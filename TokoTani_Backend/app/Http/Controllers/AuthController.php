<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'gagal',
                'code' => '422',
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::create([
            ...$validator->validated(),
            'role' => 'customer',
        ]);

        return $this->tokenResponse($user, 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'gagal',
                'code' => '422',
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::where('email', $validator->validated()['email'])->first();

        if (! $user || ! Hash::check($validator->validated()['password'], $user->password)) {
            return response()->json([
                'status' => 'gagal',
                'code' => '401',
                'message' => 'Email atau kata sandi tidak valid.',
            ], 401);
        }

        return $this->tokenResponse($user);
    }

    public function me(Request $request)
    {
        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Data pelanggan berhasil diambil.',
            'data' => ['user' => $request->user()],
        ]);
    }

    public function logout(Request $request)
    {
        $token = $request->user()->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Anda berhasil keluar.',
        ]);
    }

    private function tokenResponse(User $user, int $status = 200)
    {
        $token = $user->createToken(
            'flutter-customer',
            ['customer'],
            now()->addDays(30),
        )->plainTextToken;

        return response()->json([
            'status' => 'sukses',
            'code' => (string) $status,
            'message' => 'Autentikasi berhasil.',
            'data' => [
                'token' => $token,
                'user' => $user,
            ],
        ], $status);
    }
}
