import 'package:flutter/foundation.dart';

/// Indeks tab navigasi bawah.
class AppTab {
  const AppTab._();

  static const int home = 0;
  static const int products = 1;
  static const int cart = 2;
  static const int orders = 3;
  static const int account = 4;
}

/// Menyimpan tab aktif agar halaman mana pun dapat berpindah tab.
class NavigationProvider extends ChangeNotifier {
  int _index = AppTab.home;
  int get index => _index;

  void select(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void reset() => select(AppTab.home);
}
