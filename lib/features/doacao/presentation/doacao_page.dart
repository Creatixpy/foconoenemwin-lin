import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/doacao_repository.dart';

class DoacaoPage extends ConsumerStatefulWidget {
  const DoacaoPage({super.key});

  @override
  ConsumerState<DoacaoPage> createState() => _DoacaoPageState();
}

class _DoacaoPageState extends ConsumerState<DoacaoPage> {
  double _valor = 25;
  final _mensagemController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _abrirCheckout() async {
    setState(() => _isLoading = true);
    final repository = ref.read(doacaoRepositoryProvider);
    try {
      final url = await repository.criarCheckout(
        valorEmCentavos: (_valor * 100).round(),
        mensagem: _mensagemController.text.isNotEmpty
            ? _mensagemController.text
            : null,
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } on UnimplementedError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? error.toString())),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar checkout: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apoie o Foco no ENEM',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Mantemos toda a infraestrutura (Supabase, IA Groq, NewsAPI e monitoramento) com apoio da comunidade.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selecione o valor',
                      style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: _valor,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: 'R\$ ${_valor.toStringAsFixed(0)}',
                    onChanged: (value) => setState(() => _valor = value),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'R\$ ${_valor.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mensagemController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mensagem (opcional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _abrirCheckout,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite_border),
                    label: const Text('Doar via Stripe'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Transparência',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            '- Todos os pagamentos vão para uma sessão Stripe Checkout protegida.\n'
            '- Registramos eventos em `analytics_events` para auditoria.\n'
            '- Você pode solicitar recibo pelo e-mail cadastrado no Supabase.\n'
            '- As doações financiam novas rotas, cache de temas e monitoramento.',
          ),
        ],
      ),
    );
  }
}
