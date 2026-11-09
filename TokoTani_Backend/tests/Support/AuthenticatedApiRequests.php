<?php

namespace Tests\Support;

use App\Models\User;

trait AuthenticatedApiRequests
{
    protected User $apiUser;

    protected function setUp(): void
    {
        parent::setUp();

        $this->apiUser = User::factory()->create(['role' => 'admin']);
        $this->withToken($this->apiUser->createToken('feature-test')->plainTextToken);
    }

    protected function authenticateAs(User $user): void
    {
        $this->apiUser = $user;
        app('auth')->forgetGuards();
        $this->withToken($user->createToken('feature-test')->plainTextToken);
    }
}
