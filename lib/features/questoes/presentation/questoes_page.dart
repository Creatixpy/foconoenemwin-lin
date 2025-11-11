import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../account/data/account_providers.dart';
import '../../shared/models/quiz_result.dart' as models;
import '../../shared/widgets/section_header.dart';
import '../application/quiz_controller.dart';

class QuestoesPage extends ConsumerStatefulWidget {
  const QuestoesPage({super.key});

  @override
  ConsumerState<QuestoesPage> createState() => _QuestoesPageState();
}

class _QuestoesPageState extends ConsumerState<QuestoesPage> {
  final _disciplinas = const [
    'Linguagens',
    'Matemática',
    'Ciências Humanas',
    'Ciências da Natureza',
    'Redação',
  ];
  final _selecionadas = <String>{'Linguagens', 'Matemática'};

  List<models.QuizQuestion>? _questions;
  final Map<String, String> _answers = {};
  _QuizSummary? _summary;
  bool _savingResult = false;

  Future<void> _gerar() async {
    if (_selecionadas.isEmpty) {
      _showSnack('Selecione ao menos uma disciplina.');
      return;
    }
    try {
      final generated = await ref
          .read(quizControllerProvider.notifier)
          .gerar(disciplinas: _selecionadas.toList());
      if (!mounted) return;
      setState(() {
        _questions = generated;
        _answers.clear();
        _summary = null;
      });
    } catch (error) {
      _showSnack('Erro ao gerar questões: $error');
    }
  }

  Future<void> _finalizar() async {
    final questions = _questions;
    if (questions == null || questions.isEmpty) {
      _showSnack('Gere um simulado antes de finalizar.');
      return;
    }

    final total = questions.length;
    final correct = questions
        .where(
          (q) => (_answers[q.id]?.toUpperCase() ?? '') == q.respostaCorreta,
        )
        .length;
    final unanswered = total - _answers.length;
    final wrong = total - correct;
    final score = (correct / total * 1000).round();

    setState(() {
      _summary = _QuizSummary(
        total: total,
        correct: correct,
        wrong: wrong,
        unanswered: unanswered,
        score: score,
        savedResult: null,
      );
      _savingResult = true;
    });

    try {
      final result = await ref.read(quizControllerProvider.notifier).salvar(
            questions: questions,
            respostas: _answers,
          );
      if (!mounted) return;
      ref.invalidate(recentQuizResultsProvider);
      setState(() {
        _summary = _summary?.copyWith(savedResult: result);
      });
      _showSnack('Resultado salvo com sucesso!');
    } on StateError catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack('Não foi possível salvar: $error');
    } finally {
      if (mounted) {
        setState(() => _savingResult = false);
      }
    }
  }

  void _selectAnswer(String questionId, String letter) {
    setState(() {
      _answers[questionId] = letter;
    });
  }

  void _clearAnswers() {
    setState(() {
      _answers.clear();
      _summary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(quizControllerProvider);
    final quizzes = ref.watch(recentQuizResultsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Simulador inteligente',
            subtitle:
                'Escolha disciplinas, gere questões com IA e sincronize seu histórico.',
          ),
          const SizedBox(height: 16),
          _buildDisciplineSelector(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controllerState.isLoading ? null : _gerar,
            icon: controllerState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Gerar simulado'),
          ),
          if (controllerState.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Erro: ${controllerState.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 24),
          if (_questions != null) _buildQuestionnaire(),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Histórico recente',
            subtitle: 'Sincronizado com Supabase (quiz_results)',
          ),
          const SizedBox(height: 12),
          quizzes.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('Nenhum simulado encontrado.');
              }
              return Column(
                children: [
                  for (final quiz in items.take(5))
                    Card(
                      child: ListTile(
                        title: Text(quiz.disciplines.join(' · ')),
                        subtitle: Text(
                          '${quiz.correctAnswers}/${quiz.totalQuestions} '
                          'acertos – ${DateFormat('dd/MM HH:mm').format(quiz.createdAt)}',
                        ),
                        trailing: Text('${quiz.score} pts'),
                      ),
                    ),
                ],
              );
            },
            error: (err, stack) => Text('Erro ao carregar: $err'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _disciplinas.map((disciplina) {
        final isSelected = _selecionadas.contains(disciplina);
        return FilterChip(
          label: Text(disciplina),
          selected: isSelected,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selecionadas.add(disciplina);
              } else {
                _selecionadas.remove(disciplina);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuestionnaire() {
    final questions = _questions ?? const [];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final answered = _answers.length;
    final total = questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Respondidas: $answered / $total'),
            TextButton(
              onPressed: _answers.isEmpty ? null : _clearAnswers,
              child: const Text('Limpar respostas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final question in questions)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(question.disciplina),
                    avatar: const Icon(Icons.menu_book, size: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.enunciado,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < question.alternativas.length; i++)
                    Builder(
                      builder: (context) {
                        final letter = i < letters.length
                            ? letters[i]
                            : String.fromCharCode(65 + i);
                        final selected =
                            _answers[question.id]?.toUpperCase() == letter;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text('$letter) ${question.alternativas[i]}'),
                          onTap: () => _selectAnswer(question.id, letter),
                        );
                      },
                    ),
                  if (_summary != null && question.explicacao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Explicação: ${question.explicacao}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_summary != null) _buildSummaryCard(_summary!),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _savingResult ? null : _finalizar,
          icon: _savingResult
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.flag),
          label: const Text('Finalizar simulado'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(_QuizSummary summary) {
    final saved = summary.savedResult != null;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do simulado',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Acertos: ${summary.correct}/${summary.total}'),
            Text('Erros: ${summary.wrong}'),
            Text('Em branco: ${summary.unanswered}'),
            Text('Pontuação estimada: ${summary.score} pts'),
            const SizedBox(height: 8),
            Text(
              saved
                  ? 'Resultado salvo na sua conta.'
                  : 'Faça login para salvar o histórico.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: saved ? Colors.white : Colors.yellowAccent,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuizSummary {
  const _QuizSummary({
    required this.total,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.score,
    this.savedResult,
  });

  final int total;
  final int correct;
  final int wrong;
  final int unanswered;
  final int score;
  final models.QuizResult? savedResult;

  _QuizSummary copyWith({models.QuizResult? savedResult}) {
    return _QuizSummary(
      total: total,
      correct: correct,
      wrong: wrong,
      unanswered: unanswered,
      score: score,
      savedResult: savedResult ?? this.savedResult,
    );
  }
}
