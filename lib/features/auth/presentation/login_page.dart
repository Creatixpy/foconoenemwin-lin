import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../shared/widgets/primary_button.dart';
import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signupMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_signupMode) {
      await controller.signUp(email, password);
    } else {
      await controller.signIn(email, password);
    }

    ref.invalidate(sessionStreamProvider);
    if (mounted && ref.read(sessionProvider) != null) {
      context.go('/');
    }
  }

  Future<void> _signInWithGoogle() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signInWithGoogle();
    ref.invalidate(sessionStreamProvider);
    if (mounted && ref.read(sessionProvider) != null) {
      context.go('/');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete a autenticação no navegador do Google.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _signupMode ? 'Criar conta' : 'Entrar no Foco no ENEM',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'A senha deve ter ao menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _signupMode ? 'Criar conta' : 'Entrar',
                      isLoading: authState.isLoading,
                      onPressed: authState.isLoading ? null : _submit,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_translate, size: 20),
                      label: Text(_signupMode
                          ? 'Cadastrar com Google'
                          : 'Entrar com Google'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _signupMode = !_signupMode),
                      child: Text(_signupMode
                          ? 'Já tenho conta'
                          : 'Quero criar uma conta'),
                    ),
                    if (authState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Erro: ${authState.error}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
