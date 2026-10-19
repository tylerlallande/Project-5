class MapProviderConfig {
  const MapProviderConfig({required this.styleUrl, required this.attribution});

  factory MapProviderConfig.fromEnvironment() => const MapProviderConfig(
    styleUrl: String.fromEnvironment(
      'MAP_STYLE_URL',
      defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
    ),
    attribution: String.fromEnvironment(
      'MAP_ATTRIBUTION',
      defaultValue: 'OpenFreeMap · OpenStreetMap contributors',
    ),
  );

  final String styleUrl;
  final String attribution;
}
