import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local premium entitlement until IAP / AdMob is wired up.
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const String _kPrefsPremiumActive = 'premium_active_v1';

  final ValueNotifier<bool> active = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    active.value = prefs.getBool(_kPrefsPremiumActive) ?? false;
  }

  bool get hasPremium => active.value;

  Future<void> setActive(bool value) async {
    active.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsPremiumActive, value);
  }
}
