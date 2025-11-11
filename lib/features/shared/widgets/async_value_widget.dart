import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (err, stack) => error ??
          Center(
            child: Text(
              'Ocorreu um erro: $err',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.redAccent),
            ),
          ),
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
    );
  }
}
