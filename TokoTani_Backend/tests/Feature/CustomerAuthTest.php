<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_register_and_receives_a_sanctum_token(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Pelanggan Uji',
            'email' => 'pelanggan@example.test',
            'password' => 'password-layak',
            'password_confirmation' => 'password-layak',
            'role' => 'admin',
        ])->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.user.role', 'customer')
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'name', 'email']]]);

        $this->assertDatabaseHas('users', [
            'email' => 'pelanggan@example.test',
            'role' => 'customer',
        ]);
        $this->assertDatabaseHas('personal_access_tokens', [
            'tokenable_id' => $response->json('data.user.id'),
        ]);
    }

    public function test_login_me_and_logout_use_the_issued_token(): void
    {
        User::factory()->create([
            'name' => 'Pelanggan Masuk',
            'email' => 'masuk@example.test',
            'password' => 'password-layak',
            'role' => 'customer',
        ]);

        $token = $this->postJson('/api/auth/login', [
            'email' => 'masuk@example.test',
            'password' => 'password-layak',
        ])->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->json('data.token');

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('data.user.email', 'masuk@example.test');

        $this->withToken($token)
            ->postJson('/api/auth/logout')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        app('auth')->forgetGuards();
        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();
    }

    public function test_invalid_credentials_and_unauthed_cart_requests_are_rejected(): void
    {
        $this->postJson('/api/auth/login', [
            'email' => 'missing@example.test',
            'password' => 'not-a-password',
        ])->assertUnauthorized()
            ->assertJsonPath('status', 'gagal');

        $this->getJson('/api/keranjang')->assertUnauthorized();
        $this->postJson('/api/checkout', [])->assertUnauthorized();
        $this->getJson('/api/pesanan')->assertUnauthorized();
    }

    public function test_customer_registration_cannot_grant_admin_api_access(): void
    {
        $token = $this->postJson('/api/auth/register', [
            'name' => 'Pelanggan Biasa',
            'email' => 'biasa@example.test',
            'password' => 'password-layak',
            'password_confirmation' => 'password-layak',
        ])->assertCreated()
            ->json('data.token');

        $this->withToken($token)
            ->postJson('/api/produk', [])
            ->assertForbidden()
            ->assertJsonPath('status', 'gagal');
    }
}
