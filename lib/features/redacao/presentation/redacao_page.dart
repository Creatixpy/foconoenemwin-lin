import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/rate_limit_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/utils/operating_hours.dart';
import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/section_header.dart';
import '../application/redacao_providers.dart';
import '../data/theme_repository.dart';
import '../domain/tema_tipo.dart';
import '../models/selected_theme.dart';

class RedacaoPage extends ConsumerStatefulWidget {
  const RedacaoPage({super.key});

  @override
  ConsumerState<RedacaoPage> createState() => _RedacaoPageState();
}

class _RedacaoPageState extends ConsumerState<RedacaoPage> {
  final _textoController = TextEditingController();
  final _customTemaController = TextEditingController();
  TemaTipo _temaTipo = TemaTipo.sugerido;
  SelectedTheme? _temaSelecionado;
  bool _gerandoTema = false;

  @override
  void dispose() {
    _textoController.dispose();
    _customTemaController.dispose();
    super.dispose();
  }

  Future<void> _gerarTemaAI() async {
    setState(() => _gerandoTema = true);
    final themeRepository = ref.read(themeRepositoryProvider);
    try {
      final response = await themeRepository.requestTheme();
      setState(() {
        _temaSelecionado = response;
        _temaTipo = TemaTipo.ia;
      });
      _showMessage('Tema gerado com sucesso!');
    } catch (error) {
      _showMessage('Erro ao gerar tema: $error');
    } finally {
      if (mounted) {
        setState(() => _gerandoTema = false);
      }
    }
  }

  Future<void> _enviarRedacao() async {
    if (_textoController.text.trim().length < 800) {
      _showMessage('A redação deve ter pelo menos 800 caracteres.');
      return;
    }

    final controller = ref.read(redacaoControllerProvider.notifier);
    final texto = _textoController.text.trim();
    final temaCustom =
        _temaTipo == TemaTipo.personalizado ? _customTemaController.text.trim() : null;
    final themeToSend = _temaTipo == TemaTipo.personalizado ? null : _temaSelecionado;

    try {
      await controller.enviar(
        texto: texto,
        tipo: _temaTipo,
        temaSelecionado: themeToSend,
        temaCustom: temaCustom,
      );
    } on OutsideOperatingHoursException catch (error) {
      _showMessage(
        'Correções disponíveis entre ${OperatingHours.startHour}h e ${OperatingHours.endHour}h. '
        'Faltam ${error.remaining.inMinutes} minutos.',
      );
      return;
    } on RateLimitException catch (error) {
      _showMessage(
        'Limite atingido. Tente novamente em ${error.timeRemaining.inMinutes} minutos.',
      );
      return;
    } on StateError catch (error) {
      _showMessage(error.message);
      return;
    } catch (error) {
      _showMessage('Erro ao corrigir redação: $error');
      return;
    }

    if (!mounted) return;
    final state = ref.read(redacaoControllerProvider);
    if (state.hasError) {
      _showMessage('Erro: ${state.error}');
      return;
    }

    final result = state.value;
    if (result != null) {
      context.go('/resultados/${result.id}');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cachedThemes = ref.watch(cachedThemesProvider);
    final controllerState = ref.watch(redacaoControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Correção de redação',
            subtitle:
                'IA alinhada às 5 competências + verificação de horário e limite por usuário.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ChoiceChip(
                label: const Text('Tema sugerido'),
                selected: _temaTipo == TemaTipo.sugerido,
                onSelected: (_) => setState(() => _temaTipo = TemaTipo.sugerido),
              ),
              ChoiceChip(
                label: const Text('Tema personalizado'),
                selected: _temaTipo == TemaTipo.personalizado,
                onSelected: (_) => setState(() => _temaTipo = TemaTipo.personalizado),
              ),
              ChoiceChip(
                label: const Text('Tema via IA'),
                selected: _temaTipo == TemaTipo.ia,
                onSelected: (_) => setState(() => _temaTipo = TemaTipo.ia),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_temaTipo == TemaTipo.personalizado)
            TextField(
              controller: _customTemaController,
              decoration: const InputDecoration(
                labelText: 'Digite seu tema',
                hintText: 'Ex: Desafios da cidadania digital entre jovens',
              ),
            )
          else
            AsyncValueWidget(
              value: cachedThemes,
              data: (themes) {
                if (themes.isEmpty) {
                  return const Text('Nenhum tema em cache. Gere um novo!');
                }
                if (_temaSelecionado == null) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _temaSelecionado = themes.first);
                    }
                  });
                }
                return DropdownMenu<SelectedTheme>(
                  initialSelection: _temaSelecionado ?? themes.first,
                  label: const Text('Escolha um tema'),
                  onSelected: (value) => setState(() => _temaSelecionado = value),
                  dropdownMenuEntries: [
                    for (final theme in themes)
                      DropdownMenuEntry(
                        value: theme,
                        label: theme.tema,
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _gerandoTema ? null : _gerarTemaAI,
              icon: _gerandoTema
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Gerar novo tema com IA'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textoController,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Cole sua redação aqui',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_clock, size: 18),
              const SizedBox(width: 8),
              Text(
                'Correções disponíveis entre ${OperatingHours.startHour}h e ${OperatingHours.endHour}h (horário de Brasília).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 260,
            child: ElevatedButton.icon(
              onPressed: controllerState.isLoading ? null : _enviarRedacao,
              icon: controllerState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Enviar para correção'),
            ),
          ),
          if (controllerState.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Erro: ${controllerState.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Por que usar?',
            subtitle: 'Validamos horário, tema e aplicamos rate limit antes de chamar a Groq.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _BenefitCard(
                icon: Icons.shield_moon_outlined,
                title: 'Respeito aos limites',
                subtitle: 'Validamos horário de operação e limite por usuário antes de usar créditos de IA.',
              ),
              _BenefitCard(
                icon: Icons.rule,
                title: 'Alinhado às 5 competências',
                subtitle: 'Cada competência recebe nota, feedback e destaques.',
              ),
              _BenefitCard(
                icon: Icons.analytics_outlined,
                title: 'Dashboards automáticos',
                subtitle: 'Resultados alimentam o RPC `recalculate_user_statistics` do Supabase.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
