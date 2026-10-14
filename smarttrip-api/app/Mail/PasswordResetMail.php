<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PasswordResetMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $resetUrl) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Atur Ulang Kata Sandi - SmartTrip',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.reset-password',
            with: ['resetUrl' => $this->resetUrl],
        );
    }
}
