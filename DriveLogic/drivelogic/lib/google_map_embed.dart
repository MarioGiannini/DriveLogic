// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import 'open_location_code.dart';

const String MAP_API_KEY = "AIzaSyAtpnLg0Ndg4eHM6Z8TwjZPT9z_ECeRSqw";

class GoogleMapEmbed extends StatefulWidget {
  const GoogleMapEmbed({super.key});

  @override
  State<GoogleMapEmbed> createState() => _GoogleMapEmbedState();
}


class _GoogleMapEmbedState extends State<GoogleMapEmbed> {
  double long=0, lat=0;
  double bearing = 0;
  WebViewController controller = WebViewController();

  static bool initializingGPS = true, hasGPS = false;
  static bool initializingMagnetometer = true; //, hasMagnetometer = false;

  // Geo Locator <<

  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';
  static String permissionGPS="";

  static final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  static Position? lastPosition;
  //static Position? newPosition;
  // >> Geo Locator

/*  void _update() {
    setState(() {

    });
  }
*/

////////////////////////////////////////////////////////////////////////////////
  Future<void> _getCurrentPosition() async {
    if (!hasGPS || initializingGPS ) {
      return;
    }

    final newPosition = await _geolocatorPlatform.getCurrentPosition();
    double km = 1;
    if( lastPosition != null ) {
      km = 2 * 6371 * asin(sqrt(
          pow(sin((newPosition.latitude - lastPosition!.latitude) / 2), 2) +
              cos(lastPosition!.latitude) * cos(newPosition.latitude) * pow(sin((newPosition.longitude - lastPosition!.longitude) / 2), 2)));
    }
    // double km = 2 * 6371 * asin(sqrt( (sin((lat2 - lat1) / 2))^2 + cos(lat1) * cos(lat2) * (sin((lon2 - lon1) / 2))^2 ))
    if( km >= 0.5 ) {
      lastPosition = newPosition;
      setState(() {
      });
    }
  }
  Future<bool> _handlePermissionMagnetometer() async {
    return false;
  }

  Future<bool> _handlePermissionGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      permissionGPS = _kLocationServicesDisabledMessage;
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        permissionGPS = _kPermissionDeniedMessage;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      permissionGPS = _kPermissionDeniedForeverMessage;
      return false;
    }
    permissionGPS = _kPermissionGrantedMessage;
    return true;
  }

  void _handlePermission() async {
    bool gpsEnabled = await _handlePermissionGPS();
    initializingGPS = false;
    hasGPS = gpsEnabled;
    /* bool magnetometerEnabled = */ await _handlePermissionMagnetometer();
    initializingMagnetometer = false;

    hasGPS = gpsEnabled;
    //hasMagnetometer = magnetometerEnabled;
  }
////////////////////////////////////////////////////////////////////////////////
  void update()
  {
    _getCurrentPosition();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Initialize static GPS data
    _handlePermission();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    Timer.periodic( const Duration( seconds: 2 ), (timer) {
      _getCurrentPosition();
    } );


  }
  @override
  Widget build(BuildContext context) {
    if( initializingGPS || initializingMagnetometer || lastPosition == null ) {
      Timer(
          const Duration(seconds: 1),
              () {
            setState(() {

            });
          } );
      return( Text( "Loading... ${_GoogleMapEmbedState.permissionGPS}" ));
    }


    /*String htmlString =
        "<!DOCTYPE html><html lang=\"en\"><body>"
        "<iframe style"
        "width=\"600\" "
        "height=\"450\" "
        "style=\"border:0\" "
        "loading=\"lazy\" "
        "allowfullscreen "
        "referrerpolicy=\"no-referrer-when-downgrade\" "
        "src=\"https://www.google.com/maps/embed/v1/place?key=${MAP_API_KEY}&q=Space+Needle,Seattle+WA\"> "
        "</iframe></body></html>";
    htmlString =
        '<!DOCTYPE html><html lang="en"><body><iframe style="width:100%;height:100%;border:0" loading="lazy" allowfullscreen referrerpolicy="no-referrer-when-downgrade" src="https://www.google.com/maps/embed/v1/place?key='
        + MAP_API_KEY + '&q=Space+Needle,Seattle+WA"></iframe></body></html>';
    controller.loadRequest(Uri.parse('https://www.google.com/maps'));
     */

    String placeID = encode( lastPosition!.latitude, lastPosition!.longitude).replaceAll('+', "%2B");
    String htmlString = _kHtml.replaceAll( "[PARAMETERS]", "key=$MAP_API_KEY&q=$placeID" ).replaceAll("[MODE]", "place");
    controller.loadHtmlString( htmlString );

    // Notes:
    // By embedding Google Maps directly, Google Maps shows 'Launch App' icon, and can't identify location;
    // By implementing Embedded map with current location, we have to use place IDs, which display on top left in a cryptic form.
    // By using the Map API key we can display a map with a marker, but it will cost $7 for every 1,000 map retrievals. (Expect a 2-hour drive to retrieve about 3,600 maps)
    return
      Expanded(
        child: WebViewWidget(controller: controller),
      );
  }

  final String _kHtml = """
<!DOCTYPE html>
<html>

<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Google Maps Embed</title>
    <style>
        html, body {margin: 0; padding:0; height: 100%; overflow: hidden}
        #map { height: 100vh; width: 100%; }
    </style>
</head>

<body>  
    <div id="map"></div>

    <script>
    const queryString = "[PARAMETERS]";
    const mode = "[MODE]";

    let mapUrl = 'https://www.google.com/maps/embed/v1/';
    mapUrl += mode;
    mapUrl += '?';
    mapUrl += queryString;

    // Create the iframe element with the map URL
    const mapElement = document.createElement('iframe');
    mapElement.setAttribute('src', mapUrl);
    mapElement.setAttribute('width', '100%');
    mapElement.setAttribute('height', '100%'); // Full height
    mapElement.setAttribute('frameborder', '0');
    mapElement.setAttribute('style', 'border:0');
    document.getElementById('map').appendChild(mapElement);
    </script>
</body>

</html>
""";

}