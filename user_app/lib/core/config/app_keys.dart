import 'package:flutter/material.dart';

abstract final class AppKeys {
  AppKeys._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}
