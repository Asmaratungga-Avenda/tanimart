<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminPasswordCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_creates_admin_account_with_hashed_password(): void
    {
        $this->artisan('admin:password')
            ->expectsQuestion('Email admin', 'admin@tokotani.com')
            ->expectsConfirmation('Akun admin@tokotani.com belum ada. Buat akun baru?', 'yes')
            ->expectsQuestion('Nama admin', 'Admin TokoTani')
            ->expectsQuestion('Password baru (minimal 8 karakter)', 'strong-password')
            ->expectsQuestion('Ulangi password baru', 'strong-password')
            ->expectsOutputToContain('Akun admin admin@tokotani.com berhasil dibuat.')
            ->assertExitCode(0);

        $user = User::query()->where('email', 'admin@tokotani.com')->firstOrFail();

        $this->assertSame('Admin TokoTani', $user->name);
        $this->assertTrue(Hash::check('strong-password', $user->password));
    }

    public function test_updates_existing_account_password(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@tokotani.com',
            'password' => 'old-password',
        ]);

        $this->artisan('admin:password')
            ->expectsQuestion('Email admin', 'admin@tokotani.com')
            ->expectsQuestion('Password baru (minimal 8 karakter)', 'new-strong-password')
            ->expectsQuestion('Ulangi password baru', 'new-strong-password')
            ->expectsOutputToContain('Password akun admin@tokotani.com berhasil diperbarui.')
            ->assertExitCode(0);

        $this->assertTrue(Hash::check('new-strong-password', $user->fresh()->password));
    }

    public function test_does_not_change_password_when_confirmation_does_not_match(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@tokotani.com',
            'password' => 'old-password',
        ]);

        $this->artisan('admin:password')
            ->expectsQuestion('Email admin', 'admin@tokotani.com')
            ->expectsQuestion('Password baru (minimal 8 karakter)', 'new-strong-password')
            ->expectsQuestion('Ulangi password baru', 'different-password')
            ->expectsOutputToContain('Konfirmasi password tidak cocok. Tidak ada perubahan yang disimpan.')
            ->assertExitCode(1);

        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    public function test_rejects_invalid_email_without_creating_an_account(): void
    {
        $this->artisan('admin:password')
            ->expectsQuestion('Email admin', 'not-an-email')
            ->expectsOutputToContain('Alamat email tidak valid.')
            ->assertExitCode(1);

        $this->assertDatabaseMissing('users', ['email' => 'not-an-email']);
    }

    public function test_does_not_create_account_when_creation_is_declined(): void
    {
        $this->artisan('admin:password')
            ->expectsQuestion('Email admin', 'admin@tokotani.com')
            ->expectsConfirmation('Akun admin@tokotani.com belum ada. Buat akun baru?', 'no')
            ->expectsOutputToContain('Tidak ada perubahan.')
            ->assertExitCode(0);

        $this->assertDatabaseMissing('users', ['email' => 'admin@tokotani.com']);
    }

    public function test_rejects_short_password_without_changing_existing_password(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@tokotani.com',
            'password' => 'old-password',
        ]);

        $this->artisan('admin:password')
            ->expectsQuestion('Email admin', 'admin@tokotani.com')
            ->expectsQuestion('Password baru (minimal 8 karakter)', 'short')
            ->expectsOutputToContain('Password harus berisi 8 sampai 255 karakter.')
            ->assertExitCode(1);

        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    public function test_database_seeding_does_not_reset_admin_password(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@tokotani.com',
            'password' => 'old-password',
        ]);

        $this->seed(DatabaseSeeder::class);

        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }
}
