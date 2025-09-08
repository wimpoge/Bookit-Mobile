import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';

  ThemeBloc(this._prefs) : super(const ThemeState(false)) {
    on<ThemeLoadEvent>(_onLoadTheme);
    on<ThemeToggleEvent>(_onToggleTheme);
  }

  void _onLoadTheme(ThemeLoadEvent event, Emitter<ThemeState> emit) {
    final isDarkMode = _prefs.getBool(_themeKey) ?? false;
    emit(ThemeState(isDarkMode));
  }

  Future<void> _onToggleTheme(ThemeToggleEvent event, Emitter<ThemeState> emit) async {
    final newTheme = !state.isDarkMode;
    emit(ThemeState(newTheme));
    await _prefs.setBool(_themeKey, newTheme);
  }
}