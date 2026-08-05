enum Flavor {
  development,
  staging,
  production;

  static Flavor fromEnvironment(String value) => switch (value.toLowerCase()) {
    'production' || 'prod' => Flavor.production,
    'staging' || 'stage' => Flavor.staging,
    _ => Flavor.development,
  };
}
