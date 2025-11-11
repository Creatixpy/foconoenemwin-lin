import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/application/profile_controller.dart';
import '../../account/data/account_providers.dart';

class ContaEditarPage extends ConsumerStatefulWidget {
  const ContaEditarPage({super.key});

  @override
  ConsumerState<ContaEditarPage> createState() => _ContaEditarPageState();
}

class _ContaEditarPageState extends ConsumerState<ContaEditarPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _bioController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _anoController = TextEditingController();
  final _taglineController = TextEditingController();
  bool _showStats = true;
  bool _acceptedTerms = false;
  bool _confirmedAge = false;
  String? _theme;
  bool _initialized = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _bioController.dispose();
    _objetivoController.dispose();
    _anoController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    if (_initialized) return;
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _nomeController.text = profile.fullName ?? '';
      _bioController.text = profile.bio ?? '';
      _objetivoController.text = profile.goal ?? '';
      _anoController.text = profile.targetYear?.toString() ?? '';
      _taglineController.text = profile.communityTagline ?? '';
      _theme = profile.communityProfileTheme;
      _showStats = profile.communityShowStatistics;
      _acceptedTerms = profile.communityTermsAcceptedAt != null;
      _confirmedAge = profile.isOver16 ?? false;
      _initialized = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(profileFormControllerProvider);

    Future<void> salvar() async {
      if (!_formKey.currentState!.validate()) return;
      final ano = int.tryParse(_anoController.text);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      await ref.read(profileFormControllerProvider.notifier).salvar(
            nomeCompleto: _nomeController.text.trim(),
            bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            objetivo: _objetivoController.text.trim().isEmpty
                ? null
                : _objetivoController.text.trim(),
            anoEnem: ano,
            communityTagline:
                _taglineController.text.trim().isEmpty ? null : _taglineController.text,
            communityTheme: _theme,
            showStatistics: _showStats,
            acceptedCommunityTerms: _acceptedTerms,
            confirmedAge: _confirmedAge,
            termsVersion: '2024-10',
          );
      if (!mounted) return;
      final state = ref.read(profileFormControllerProvider);
      if (!state.hasError) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        ref.invalidate(userProfileProvider);
        navigator.pop();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Informe seu nome.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objetivoController,
                decoration: const InputDecoration(labelText: 'Objetivo principal'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _anoController,
                decoration: const InputDecoration(labelText: 'Ano do ENEM'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taglineController,
                decoration: const InputDecoration(
                  labelText: 'Frase para comunidade',
                  helperText: 'Mostrada no seu perfil público da comunidade.',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _theme,
                decoration: const InputDecoration(labelText: 'Tema do perfil'),
                items: const [
                  DropdownMenuItem(value: 'purple', child: Text('Roxo')),
                  DropdownMenuItem(value: 'orange', child: Text('Laranja')),
                  DropdownMenuItem(value: 'green', child: Text('Verde')),
                  DropdownMenuItem(value: 'blue', child: Text('Azul')),
                ],
                onChanged: (value) => setState(() => _theme = value),
              ),
              SwitchListTile(
                value: _showStats,
                onChanged: (value) => setState(() => _showStats = value),
                title: const Text('Mostrar minhas estatísticas na comunidade'),
              ),
              SwitchListTile(
                value: _confirmedAge,
                onChanged: (value) => setState(() => _confirmedAge = value),
                title: const Text('Confirmo que tenho 16 anos ou mais'),
              ),
              SwitchListTile(
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value),
                title: const Text('Li e aceito os termos da comunidade'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.isLoading ? null : salvar,
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Salvar alterações'),
              ),
              if (controller.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Erro: ${controller.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
