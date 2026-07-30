import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import '../routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // If user is not logged in, redirect to login
    if (!BackendApiService.to.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
