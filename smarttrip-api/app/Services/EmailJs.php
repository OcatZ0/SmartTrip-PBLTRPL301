<?php

namespace App\Services;

use Illuminate\Mail\Mailable;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Sends the app's emails (registration verification, password reset) through
 * the EmailJS REST API with the "SmartTrip - Email Aksi" template
 * (resources/views/emails/emailjs-template.html). The server calls the API with
 * the private key, so links with tokens never pass through the mobile app.
 * Without EMAILJS_* in .env (local, tests) the Laravel mailable is sent instead.
 */
class EmailJs
{
    private const ENDPOINT = 'https://api.emailjs.com/api/v1.0/email/send';

    public static function enabled(): bool
    {
        $config = config('services.emailjs');

        return filled($config['service_id'] ?? null)
            && filled($config['template_id'] ?? null)
            && filled($config['public_key'] ?? null)
            && filled($config['private_key'] ?? null);
    }

    /**
     * @param  array{subject: string, heading: string, message: string, action_label: string, action_url: string, note: string}  $params
     * @return bool false when EmailJS refused or could not be reached (already logged)
     */
    public static function deliver(string $to, Mailable $fallback, array $params): bool
    {
        if (! self::enabled()) {
            Mail::to($to)->send($fallback);

            return true;
        }

        $config = config('services.emailjs');

        try {
            $response = Http::timeout(15)->post(self::ENDPOINT, [
                'service_id' => $config['service_id'],
                'template_id' => $config['template_id'],
                'user_id' => $config['public_key'],
                'accessToken' => $config['private_key'],
                'template_params' => ['to_email' => $to, ...$params],
            ]);
        } catch (Throwable $exception) {
            Log::error('EmailJS unreachable', ['subject' => $params['subject'], 'error' => $exception->getMessage()]);

            return false;
        }

        if ($response->failed()) {
            Log::error('EmailJS refused the email', [
                'subject' => $params['subject'],
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return false;
        }

        return true;
    }
}
