import 'package:user_app/bootstrap.dart';
import 'package:user_app/core/config/flavor.dart';

Future<void> main() =>
    bootstrap(flavor: Flavor.development, debugToolsEnabled: true);
