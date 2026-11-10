<?php

namespace App\Traits;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

trait HandleImageStorage
{
    /**
     * Upload an image securely to the specified directory.
     *
     * @param UploadedFile $file
     * @param string $directory
     * @param string|null $oldPath
     * @param string $disk
     * @return string
     */
    public function uploadImage(UploadedFile $file, string $directory, ?string $oldPath = null, string $disk = 'public'): string
    {
        // Delete old image if exists
        if ($oldPath) {
            $this->deleteImage($oldPath, $disk);
        }

        // Generate unique name: timestamp + random string + original extension
        $extension = $file->getClientOriginalExtension() ?: 'jpg';
        $filename = time() . '_' . Str::random(10) . '.' . $extension;

        // Store file
        return $file->storeAs($directory, $filename, $disk);
    }

    /**
     * Delete an image from storage securely.
     *
     * @param string|null $path
     * @param string $disk
     * @return bool
     */
    public function deleteImage(?string $path, string $disk = 'public'): bool
    {
        if (!$path) {
            return false;
        }

        // Check if file exists and it's not a URL
        if (!Str::startsWith($path, ['http://', 'https://']) && Storage::disk($disk)->exists($path)) {
            return Storage::disk($disk)->delete($path);
        }

        return false;
    }

    /**
     * Get the full URL for an image path.
     *
     * @param string|null $path
     * @param string $disk
     * @return string|null
     */
    public function getFullImageUrl(?string $path, string $disk = 'public'): ?string
    {
        if (!$path) {
            return null;
        }

        if (Str::startsWith($path, ['http://', 'https://'])) {
            return $path;
        }

        return Storage::disk($disk)->url($path);
    }
}
