import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  late TextEditingController _searchController;
  StreamSubscription<Position>? _positionStream;

  LatLng _destination = LatLng(6.517832, 3.389232);
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  final LatLngBounds _unilagBounds = LatLngBounds(
    southwest: LatLng(6.512, 3.384),
    northeast: LatLng(6.524, 3.396),
  );

  final String _apiKey = 'AIzaSyCpcBJ_1OO9sfSg8zjNzyp7WASjN_xLIIU';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showSnack('Location permission denied');
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = pos);

    _addMarkersAndRoute(
      LatLng(pos.latitude, pos.longitude),
      _destination,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position newPosition) {
      setState(() => _currentPosition = newPosition);
      _addMarkersAndRoute(
        LatLng(newPosition.latitude, newPosition.longitude),
        _destination,
      );
    });
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _searchController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _launchNavigation(LatLng destination) async {
    final String urlString = kIsWeb
        ? 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=walking'
        : 'google.navigation:q=${destination.latitude},${destination.longitude}&mode=w';

    final url = Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not launch Google Maps.');
    }
  }

  Future<void> _addMarkersAndRoute(LatLng start, LatLng end) async {
    _markers
      ..clear()
      ..add(Marker(
        markerId: MarkerId('user'),
        position: start,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ))
      ..add(Marker(
        markerId: MarkerId('dest'),
        position: end,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

    final polylinePoints = await _getRoutePoints(start, end);

    if (polylinePoints != null) {
      _polylines
        ..clear()
        ..add(Polyline(
          polylineId: PolylineId('route'),
          points: polylinePoints,
          color: Colors.green,
          width: 5,
        ));
      setState(() {});
    }
  }

  Future<List<LatLng>?> _getRoutePoints(LatLng start, LatLng end) async {
    late Uri url;
    late http.Response response;

    if (kIsWeb) {
      // 1. Firebase Function URL
      url = Uri.parse(
        'https://us-central1-fes-connect-x.cloudfunctions.net/getRoute?startLat=${start.latitude}&startLng=${start.longitude}&endLat=${end.latitude}&endLng=${end.longitude}',
      );

      // 2. Get current user's ID token
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      // 3. Send GET request with Authorization header
      response = await http.get(url, headers: {
        'Authorization': 'Bearer $idToken',
      });
    } else {
      // On mobile, call Google API directly (NOT RECOMMENDED, but you’re doing it here for now)
      url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$_apiKey',
      );
      response = await http.get(url);
    }

    final data = json.decode(response.body);

    if (kIsWeb) {
      if (response.statusCode != 200 || data['polyline'] == null) return null;

      final points = PolylinePoints().decodePolyline(data['polyline']);
      return points.map((e) => LatLng(e.latitude, e.longitude)).toList();
    } else {
      if (data['status'] != 'OK') return null;

      final points = PolylinePoints()
          .decodePolyline(data['routes'][0]['overview_polyline']['points']);
      return points.map((e) => LatLng(e.latitude, e.longitude)).toList();
    }
  }

  Future<void> _searchAndNavigate(String query) async {
    final placeUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
      '?input=${Uri.encodeComponent(query)}'
      '&inputtype=textquery'
      '&fields=geometry'
      '&locationbias=rectangle:6.512,3.384|6.524,3.396'
      '&key=$_apiKey',
    );

    final response = await http.get(placeUrl);
    final data = json.decode(response.body);

    if (data['status'] == 'OK' && data['candidates'].isNotEmpty) {
      final location = data['candidates'][0]['geometry']['location'];
      final newDest = LatLng(location['lat'], location['lng']);

      setState(() => _destination = newDest);

      if (_currentPosition != null) {
        await _addMarkersAndRoute(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          newDest,
        );
        _mapController?.animateCamera(CameraUpdate.newLatLng(newDest));
      }
    } else {
      _showSnack('Location not found');
    }
  }

  Future<List<String>> _getSuggestions(String input) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&location=6.519,3.395'
      '&radius=1000'
      '&strictbounds=true'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final predictions = data['predictions'] as List;
      return predictions.map((p) => p['description'] as String).toList();
    } else {
      print('Autocomplete error: ${data['status']} - ${data['error_message']}');
      return [];
    }
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.isEmpty)
            return const Iterable<String>.empty();
          return await _getSuggestions(textEditingValue.text);
        },
        onSelected: (String selection) async {
          FocusScope.of(context).unfocus();
          await Future.delayed(Duration(milliseconds: 100));
          _searchController.text = selection;
          await _searchAndNavigate(selection);
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          controller.text = _searchController.text;

          return TextField(
            controller: _searchController,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Search destination...",
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Campus Navigator")),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                  minMaxZoomPreference: MinMaxZoomPreference(15, 20),
                  cameraTargetBounds: CameraTargetBounds(_unilagBounds),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: _buildSearchBar(),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 40.0),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.black,
          onPressed: () => _launchNavigation(_destination),
          label:
              Text("Start Navigation", style: TextStyle(color: Colors.white)),
          icon: Icon(Icons.navigation, color: Colors.white),
        ),
      ),
    );
  }
}
