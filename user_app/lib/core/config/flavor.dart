enum Flavor {
  development,
  staging,
  production;

  String get label => switch (this) {
    Flavor.development => 'Development',
    Flavor.staging => 'Staging',
    Flavor.production => 'Production',
  };

  String get value => name;

  static Flavor fromEnvironment(String value) => switch (value.toLowerCase()) {
    'production' || 'prod' => Flavor.production,
    'staging' || 'stage' => Flavor.staging,
    _ => Flavor.development,
  };
}
