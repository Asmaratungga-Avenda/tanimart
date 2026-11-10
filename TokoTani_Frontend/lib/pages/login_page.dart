import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _registering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = _registering
        ? await auth.register(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          )
        : await auth.signIn(_emailController.text, _passwordController.text);

    if (!mounted || success) return;
    final error = auth.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/logo/agrimart_logo.png',
                  height: 60,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.eco_rounded,
                    size: 60,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _registering ? 'Buat Akun Baru' : 'Selamat Datang Kembali',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _registering
                    ? 'Daftar sekarang untuk mulai belanja produk segar.'
                    : 'Masuk untuk melanjutkan pengalaman belanja Anda.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_registering) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          hintText: 'Masukkan nama lengkap Anda',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Nama wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return email.contains('@') ? null : 'Masukkan email yang valid.';
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        hintText: 'Minimal 8 karakter',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.length < 8 ? 'Kata sandi minimal 8 karakter.' : null,
                    ),
                    if (_registering) ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmationController,
                        obscureText: _obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (value) => value != _passwordController.text
                            ? 'Konfirmasi kata sandi tidak cocok.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 40),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_registering ? 'Daftar Sekarang' : 'Masuk'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _registering ? 'Sudah punya akun?' : 'Belum punya akun?',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _registering = !_registering;
                            context.read<AuthProvider>().clearError();
                          }),
                          child: Text(_registering ? 'Masuk' : 'Daftar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
