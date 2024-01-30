import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class MapTileProvider {
  final String baseUrl = 'https://tile.openstreetmap.org';

  // Function to get the URL of a tile at a particular latitude, longitude, and zoom
  String getTileUrl(int x, int y, int zoom) {
    return '$baseUrl/$zoom/$x/$y.png';
  }

  // Function to fetch an image from a URL
  Future<ui.Image> fetchImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } else {
      throw Exception('Failed to load image');
    }
  }

  // Function to get the tiles based on zoom, latitude, and longitude
  Future<List<ui.Image>> getTiles(double zoom, double lat, double lon) async {
    // Convert lat, lon, and zoom to tile coordinates
    int xTile = long2tileX(lon, zoom.toInt());
    int yTile = lat2tileY(lat, zoom.toInt());

    // Define the range of tiles to fetch (this can be adjusted)
    int range = 1; // Adjust based on how many tiles you need

    List<ui.Image> tiles = [];
    for (int x = xTile - range; x <= xTile + range; x++) {
      for (int y = yTile - range; y <= yTile + range; y++) {
        String tileUrl = getTileUrl(x, y, zoom.toInt());
        tiles.add(await fetchImage(tileUrl));
      }
    }
    return tiles;
  }

  // Convert longitude to tile X coordinate
  int long2tileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  // Convert latitude to tile Y coordinate
  int lat2tileY(double lat, int zoom) {
    return ((1.0 -
                (math.log(math.tan(lat * math.pi / 180.0) +
                        1.0 / math.cos(lat * math.pi / 180.0)) /
                    math.pi)) /
            2.0 *
            (1 << zoom))
        .floor();
  }
}
