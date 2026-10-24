import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/core/di/storage_providers.dart';

const _storeKey = 'settings/theme_mode.txt';

/// Light, dark, or follow the phone. Saved on the device (not per account),
/// so the choice is there before anyone signs in.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final text = await ref.read(localStoreProvider).readText(_storeKey);
      final saved = ThemeMode.values.where((m) => m.name == text?.trim());
      if (saved.isNotEmpty) state = saved.first;
    } catch (_) {
      // No saved choice, or storage is unavailable: stay on "system".
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await ref.read(localStoreProvider).writeText(_storeKey, mode.name);
    } catch (_) {
      // The choice still applies until the app closes.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
