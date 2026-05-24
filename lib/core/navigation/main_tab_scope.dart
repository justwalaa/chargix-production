import 'package:flutter/material.dart';

/// Lets child screens request a bottom-nav tab change without rewriting [MainNavigation].
class MainTabScope extends InheritedWidget {
  const MainTabScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final void Function(int index) goToTab;

  static MainTabScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainTabScope>();
  }

  static void goTo(BuildContext context, int index) {
    maybeOf(context)?.goToTab(index);
  }

  @override
  bool updateShouldNotify(MainTabScope oldWidget) => false;
}

/// Bottom navigation indices (matches [MainNavigation] order).
abstract final class MainTabIndex {
  static const int home = 0;
  static const int map = 1;
  static const int activity = 2;
  static const int profile = 3;

  /// Legacy alias — use [activity].
  static const int bookings = activity;
}
