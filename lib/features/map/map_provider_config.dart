class MapProviderConfig {
  const MapProviderConfig({
    required this.styleUrl,
    required this.attribution,
    required this.defaultZoom,
  });

  factory MapProviderConfig.fromEnvironment() {
    const styleUrl = String.fromEnvironment(
      'MAP_STYLE_URL',
      defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
    );
    const attribution = String.fromEnvironment(
      'MAP_ATTRIBUTION',
      defaultValue: 'OpenFreeMap · OpenStreetMap contributors',
    );
    const defaultZoom = int.fromEnvironment(
      'MAP_DEFAULT_ZOOM',
      defaultValue: 16,
    );
    return const MapProviderConfig(
      styleUrl: styleUrl,
      attribution: attribution,
      defaultZoom: defaultZoom,
    );
  }

  final String styleUrl;
  final String attribution;
  final int defaultZoom;
}
