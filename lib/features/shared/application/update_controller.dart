import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/services/update_service.dart';

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
  final service = ref.watch(updateServiceProvider);
  return UpdateController(service);
});

class UpdateState {
  const UpdateState({
    this.isChecking = false,
    this.isInstalling = false,
    this.info,
    this.error,
    this.installerLaunched = false,
  });

  final bool isChecking;
  final bool isInstalling;
  final UpdateInfo? info;
  final String? error;
  final bool installerLaunched;

  UpdateState copyWith({
    bool? isChecking,
    bool? isInstalling,
    UpdateInfo? info,
    bool clearInfo = false,
    String? error,
    bool clearError = false,
    bool? installerLaunched,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isInstalling: isInstalling ?? this.isInstalling,
      info: clearInfo ? null : info ?? this.info,
      error: clearError ? null : error ?? this.error,
      installerLaunched: installerLaunched ?? this.installerLaunched,
    );
  }

  bool get hasUpdate => info != null;
}

class UpdateController extends StateNotifier<UpdateState> {
  UpdateController(this._service) : super(const UpdateState());

  final UpdateService _service;

  Future<void> checkForUpdates() async {
    if (state.isChecking) return;
    try {
      final package = await PackageInfo.fromPlatform();
      state = state.copyWith(isChecking: true, clearError: true);
      final info = await _service.checkForUpdates(package.version);
      state = state.copyWith(
        isChecking: false,
        info: info,
      );
    } catch (error) {
      state = state.copyWith(
        isChecking: false,
        error: error.toString(),
      );
    }
  }

  Future<void> installUpdate() async {
    final info = state.info;
    if (info == null || state.isInstalling) return;
    try {
      state = state.copyWith(isInstalling: true, clearError: true);
      await _service.install(info);
      state = state.copyWith(
        isInstalling: false,
        installerLaunched: true,
        clearInfo: true,
      );
    } catch (error) {
      state = state.copyWith(
        isInstalling: false,
        error: error.toString(),
      );
    }
  }

  void dismissUpdate() {
    state = state.copyWith(clearInfo: true, installerLaunched: false);
  }

  void clearInstallerMessage() {
    if (state.installerLaunched) {
      state = state.copyWith(installerLaunched: false);
    }
  }
}
