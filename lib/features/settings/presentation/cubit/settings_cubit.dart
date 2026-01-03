import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/repositories/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepository;
  StreamSubscription<AppSettings?>? _settingsSubscription;

  SettingsCubit(this._settingsRepository) : super(SettingsInitial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      emit(SettingsLoading());
      _settingsSubscription?.cancel();
      _settingsSubscription = _settingsRepository.watchSettings().listen(
        (settings) {
          if (settings != null) {
            emit(SettingsLoaded(settings));
          }
        },
        onError: (error) {
          emit(SettingsError(error.toString()));
        },
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    try {
      await _settingsRepository.updateSettings(settings);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> resetToDefaults() async {
    try {
      await _settingsRepository.resetToDefaults();
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
