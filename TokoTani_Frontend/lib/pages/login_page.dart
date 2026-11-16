import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/inline_banner.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _registerMode = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() {
    context.read<AuthProvider>().clearError();
    setState(() => _registerMode = !_registerMode);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final email = _email.text.trim();
    if (_registerMode) {
      await auth.register(_name.text.trim(), email, _password.text);
    } else {
      await auth.signIn(email, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final palette = context.palette;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const pagePadding = EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                );

                return SingleChildScrollView(
                  padding: pagePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - pagePadding.vertical)
                          .clamp(0, double.infinity),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _LoginLogo(),
                          const SizedBox(height: 28),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Theme(
                              data: AppTheme.light,
                              child: _LoginForm(
                                formKey: _formKey,
                                nameController: _name,
                                emailController: _email,
                                passwordController: _password,
                                confirmController: _confirm,
                                registerMode: _registerMode,
                                obscurePassword: _obscure,
                                auth: auth,
                                onTogglePassword: () =>
                                    setState(() => _obscure = !_obscure),
                                onToggleMode: _toggleMode,
                                onSubmit: _submit,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: palette.background,
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Image.asset(
      'assets/images/background/tanimart_background.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Unable to load login background asset: $error');
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.brandSoft, palette.background],
            ),
          ),
        );
      },
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo/tanimart_logo.png',
      width: 140,
      height: 110,
      fit: BoxFit.contain,
      semanticLabel: 'Logo TaniMart',
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.registerMode,
    required this.obscurePassword,
    required this.auth,
    required this.onTogglePassword,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool registerMode;
  final bool obscurePassword;
  final AuthProvider auth;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fieldErrors = auth.fieldErrors;
    final palette = AppPalette.light;

    return Card(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                registerMode ? 'Buat Akun TaniMart' : 'Selamat Datang',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                registerMode
                    ? 'Daftar untuk mulai berbelanja'
                    : 'Masuk ke akun TaniMart Anda',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: 22),
              if (auth.errorMessage != null) ...[
                InlineBanner(message: auth.errorMessage!),
                const SizedBox(height: 16),
              ],
              if (registerMode) ...[
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    errorText: fieldErrors['name'],
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  errorText: fieldErrors['email'],
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email wajib diisi';
                  if (!_emailPattern.hasMatch(email)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: registerMode
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!registerMode) onSubmit();
                },
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: fieldErrors['password'],
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Kata sandi wajib diisi';
                  if (registerMode && password.length < 8) {
                    return 'Kata sandi minimal 8 karakter';
                  }
                  return null;
                },
              ),
              if (registerMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  decoration: const InputDecoration(
                    labelText: 'Ulangi Kata Sandi',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) => value != passwordController.text
                      ? 'Kata sandi tidak sama'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: registerMode ? 'Daftar Sekarang' : 'Login',
                loading: auth.isSubmitting,
                onPressed: onSubmit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: auth.isSubmitting ? null : onToggleMode,
                child: Text(
                  registerMode
                      ? 'Sudah punya akun? Masuk'
                      : 'Belum memiliki akun? Daftar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
