<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Models\PlacePhoto;
use GdImage;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Place photos live on this server's public disk (PRD Section 2: local
 * files, no hotlinking). Every photo is re-encoded as a JPEG at most 1600 px
 * on its longest side, enough for the app's hero, and the first photo by
 * sort_order is mirrored into places.photo_url for the catalog cards.
 */
class PlacePhotoStore
{
    private const DISK = 'public';

    private const MAX_EDGE = 1600;

    private const JPEG_QUALITY = 82;

    private const MAX_DOWNLOAD_BYTES = 15 * 1024 * 1024;

    /**
     * Wikimedia and other image hosts throttle requests whose User-Agent has
     * no way to contact the operator.
     */
    private const USER_AGENT = 'SmartTripBatam/1.0 (+https://github.com/OcatZ0/SmartTrip-PBLTRPL301)';

    public function storeUpload(Place $place, UploadedFile $file): PlacePhoto
    {
        return $this->save($place, (string) file_get_contents($file->getRealPath()));
    }

    /**
     * A photo the admin found on Google Images, picked from the search
     * results or pasted as a link.
     */
    public function storeFromLink(Place $place, string $imageUrl): PlacePhoto
    {
        $this->assertPublicUrl($imageUrl);

        try {
            $response = Http::timeout(60)
                ->withHeaders(['User-Agent' => self::USER_AGENT])
                ->withOptions(['allow_redirects' => [
                    'max' => 3,
                    'protocols' => ['http', 'https'],
                    'on_redirect' => fn ($request, $response, $uri) => $this->assertPublicUrl((string) $uri),
                ]])
                ->get($imageUrl);
        } catch (ConnectionException $exception) {
            throw new RuntimeException('Gambar tidak bisa diunduh dari alamat itu. Pastikan alamatnya mengarah langsung ke file gambar.', 0, $exception);
        }

        if ($response->failed()) {
            throw new RuntimeException('Gambar tidak bisa diunduh ('.$response->status().'). Pastikan alamatnya mengarah langsung ke file gambar.');
        }

        $bytes = $response->body();
        if (strlen($bytes) > self::MAX_DOWNLOAD_BYTES) {
            throw new RuntimeException('Gambar lebih dari 15 MB, pilih ukuran yang lebih kecil.');
        }

        return $this->save($place, $bytes);
    }

    /**
     * Moves [photo] to the front. sort_order is unique per place and
     * unsigned, so the others are parked above the current range first.
     */
    public function makePrimary(PlacePhoto $photo): void
    {
        DB::transaction(function () use ($photo) {
            $place = $photo->place;
            $ordered = $place->photos()->orderBy('sort_order')->get()
                ->sortBy(fn (PlacePhoto $other) => $other->is($photo) ? -1 : $other->sort_order)
                ->values();

            $offset = (int) $place->photos()->max('sort_order') + 1;
            $place->photos()->increment('sort_order', $offset);

            // A query update: the loaded models still hold the pre-increment
            // value and Eloquent would skip an "unchanged" sort_order.
            foreach ($ordered as $index => $other) {
                PlacePhoto::whereKey($other->getKey())->update(['sort_order' => $index]);
            }

            $this->syncThumbnail($place);
        });
    }

    public function delete(PlacePhoto $photo): void
    {
        $place = $photo->place;
        $path = $this->pathOf($photo->photo_url);

        $photo->delete();
        if ($path !== null) {
            Storage::disk(self::DISK)->delete($path);
        }

        $this->syncThumbnail($place);
    }

    private function save(Place $place, string $bytes): PlacePhoto
    {
        $jpeg = $this->toJpeg($bytes);
        $path = "place-photos/{$place->places_id}/".Str::uuid().'.jpg';
        Storage::disk(self::DISK)->put($path, $jpeg);

        $photo = $place->photos()->create([
            'photo_url' => Storage::disk(self::DISK)->url($path),
            'sort_order' => ((int) $place->photos()->max('sort_order')) + ($place->photos()->exists() ? 1 : 0),
        ]);

        $this->syncThumbnail($place);

        return $photo;
    }

    private function toJpeg(string $bytes): string
    {
        $source = @imagecreatefromstring($bytes);
        if (! $source instanceof GdImage) {
            throw new RuntimeException('File bukan gambar JPG, PNG, atau WebP yang bisa dibaca.');
        }

        [$width, $height] = [imagesx($source), imagesy($source)];
        $scale = min(1, self::MAX_EDGE / max($width, $height));
        $targetWidth = max(1, (int) round($width * $scale));
        $targetHeight = max(1, (int) round($height * $scale));

        // White background, so transparent PNG areas do not turn black.
        $canvas = imagecreatetruecolor($targetWidth, $targetHeight);
        imagefill($canvas, 0, 0, imagecolorallocate($canvas, 255, 255, 255));
        imagecopyresampled($canvas, $source, 0, 0, 0, 0, $targetWidth, $targetHeight, $width, $height);

        ob_start();
        imagejpeg($canvas, null, self::JPEG_QUALITY);

        return (string) ob_get_clean();
    }

    /**
     * The server fetches an admin-typed URL, so it must never reach this
     * machine or the internal network (checked again on every redirect).
     */
    private function assertPublicUrl(string $url): void
    {
        $parts = parse_url($url);
        $scheme = strtolower($parts['scheme'] ?? '');
        $host = trim($parts['host'] ?? '', '[]');

        if (! in_array($scheme, ['http', 'https'], true) || $host === '') {
            throw new RuntimeException('Alamat gambar harus diawali http:// atau https://.');
        }

        $ips = filter_var($host, FILTER_VALIDATE_IP) ? [$host] : (gethostbynamel($host) ?: []);
        if ($ips === []) {
            throw new RuntimeException('Alamat gambar tidak ditemukan. Periksa lagi tautannya.');
        }

        foreach ($ips as $address) {
            if (! filter_var($address, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                throw new RuntimeException('Alamat gambar harus dari internet, bukan jaringan lokal.');
            }
        }
    }

    private function syncThumbnail(Place $place): void
    {
        $first = $place->photos()->orderBy('sort_order')->value('photo_url');

        if ($place->photo_url !== $first) {
            $place->update(['photo_url' => $first]);
        }
    }

    /**
     * Storage path of a photo saved by [save]; null for URLs from elsewhere
     * (e.g. seeded rows), which are left untouched on disk.
     */
    private function pathOf(string $url): ?string
    {
        $prefix = rtrim(Storage::disk(self::DISK)->url(''), '/').'/';

        return str_starts_with($url, $prefix) ? substr($url, strlen($prefix)) : null;
    }
}
