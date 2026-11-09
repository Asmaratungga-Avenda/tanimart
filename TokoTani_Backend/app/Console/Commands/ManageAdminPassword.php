<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

#[Signature('admin:password')]
#[Description('Create an administrator account or change its password')]
class ManageAdminPassword extends Command
{
    public function handle(): int
    {
        $email = trim((string) $this->ask('Email admin'));

        if (Str::length($email) > 255 || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->error('Alamat email tidak valid.');

            return self::FAILURE;
        }

        $user = User::query()->where('email', $email)->first();

        if ($user === null) {
            if (! $this->confirm("Akun {$email} belum ada. Buat akun baru?")) {
                $this->info('Tidak ada perubahan.');

                return self::SUCCESS;
            }

            $name = trim((string) $this->ask('Nama admin'));

            if ($name === '' || Str::length($name) > 255) {
                $this->error('Nama admin wajib diisi dan maksimal 255 karakter.');

                return self::FAILURE;
            }

            $user = new User;
            $user->name = $name;
            $user->email = $email;
        }

        $password = $this->secret('Password baru (minimal 8 karakter)');

        if (! is_string($password) || Str::length($password) < 8 || Str::length($password) > 255) {
            $this->error('Password harus berisi 8 sampai 255 karakter.');

            return self::FAILURE;
        }

        if ($password !== $this->secret('Ulangi password baru')) {
            $this->error('Konfirmasi password tidak cocok. Tidak ada perubahan yang disimpan.');

            return self::FAILURE;
        }

        $user->password = $password;
        $user->role = 'admin';
        $user->save();

        $this->info($user->wasRecentlyCreated
            ? "Akun admin {$email} berhasil dibuat."
            : "Password akun {$email} berhasil diperbarui.");

        return self::SUCCESS;
    }
}
