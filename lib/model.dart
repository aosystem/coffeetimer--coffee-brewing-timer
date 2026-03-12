import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coffeetimer/l10n/app_localizations.dart';
import 'package:coffeetimer/const_value.dart';

class Model {
  Model._();

  static const String _prefMinute = 'minute';
  static const String _prefWakelockEnabled = 'wakelockEnabled';
  static const String _prefSoundEnabled = 'soundEnabled';
  static const String _prefSoundVolume = 'soundVolume';
  static const String _prefSoundSelect = 'soundSelect';
  static const String _prefVibrateEnabled = 'vibrateEnabled';
  static const String _prefPercentDisplayOpacity = 'percentDisplayOpacity';
  static const String _prefTimeDisplayOpacity = 'timeDisplayOpacity';
  static const String _prefSchemeColor = 'schemeColor';
  static const String _prefThemeNumber = 'themeNumber';
  static const String _prefLanguageCode = 'languageCode';

  static bool _ready = false;
  static int _minute = 3;
  static bool _wakelockEnabled = true;
  static bool _soundEnabled = true;
  static double _soundVolume = 1.0;
  static int _soundSelect = 0;
  static bool _vibrateEnabled = true;
  static double _percentDisplayOpacity = 1.0;
  static double _timeDisplayOpacity = 1.0;
  static int _schemeColor = 20;
  static int _themeNumber = 0;
  static String _languageCode = '';

  static int get minute => _minute;
  static bool get wakelockEnabled => _wakelockEnabled;
  static bool get soundEnabled => _soundEnabled;
  static double get soundVolume => _soundVolume;
  static int get soundSelect => _soundSelect;
  static bool get vibrateEnabled => _vibrateEnabled;
  static double get percentDisplayOpacity => _percentDisplayOpacity;
  static double get timeDisplayOpacity => _timeDisplayOpacity;
  static int get schemeColor => _schemeColor;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //
    _minute = (prefs.getInt(_prefMinute) ?? 3).clamp(1, 999);
    _wakelockEnabled = prefs.getBool(_prefWakelockEnabled) ?? true;
    _soundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
    _soundVolume = (prefs.getDouble(_prefSoundVolume) ?? 1.0).clamp(0.0, 1.0);
    _soundSelect = (prefs.getInt(_prefSoundSelect) ?? 0).clamp(0, finishSounds.length - 1);
    _vibrateEnabled = prefs.getBool(_prefVibrateEnabled) ?? true;
    _percentDisplayOpacity = (prefs.getDouble(_prefPercentDisplayOpacity) ?? 1.0).clamp(0.0, 1.0);
    _timeDisplayOpacity = (prefs.getDouble(_prefTimeDisplayOpacity) ?? 1.0).clamp(0.0, 1.0);
    _schemeColor = (prefs.getInt(_prefSchemeColor) ?? 20).clamp(0, 360);
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> setMinute(int value) async {
    _minute = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefMinute, value);
  }

  static Future<void> setWakelockEnabled(bool value) async {
    _wakelockEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefWakelockEnabled, value);
  }

  static Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, value);
  }

  static Future<void> setSoundVolume(double value) async {
    _soundVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSoundVolume, value);
  }

  static Future<void> setSoundSelect(int value) async {
    _soundSelect = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSoundSelect, value);
  }

  static Future<void> setVibrateEnabled(bool value) async {
    _vibrateEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVibrateEnabled, value);
  }

  static Future<void> setPercentDisplayOpacity(double value) async {
    _percentDisplayOpacity = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefPercentDisplayOpacity, value);
  }

  static Future<void> setTimeDisplayOpacity(double value) async {
    _timeDisplayOpacity = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTimeDisplayOpacity, value);
  }

  static Future<void> setSchemeColor(int value) async {
    _schemeColor = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSchemeColor, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

}
