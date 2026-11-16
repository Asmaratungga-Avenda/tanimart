import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSuggestion {
  const LocationSuggestion({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  LatLng get point => LatLng(latitude, longitude);
}

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.failure);

  final LocationFailure failure;
}

class LocationService {
  static const _requestTimeout = Duration(seconds: 12);
  static const _nominatimInterval = Duration(seconds: 1);
  static const _nominatimUserAgent = 'TaniMart/1.0 (delivery location picker)';
  static const _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  static http.Client httpClient = http.Client();
  static Future<void> _nominatimQueue = Future<void>.value();
  static DateTime? _lastNominatimRequest;
  late final geocoding.Geocoding _geocoding = geocoding.Geocoding(
    locale: const Locale('id', 'ID'),
  );

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationServiceException(LocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        LocationFailure.permissionDeniedForever,
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: _requestTimeout,
      ),
    ).timeout(_requestTimeout);
  }

  Future<List<LocationSuggestion>> searchAddress(String query) async {
    final value = query.trim();
    if (value.length < 3) return const [];

    if (_useOpenStreetMapSearch) return _searchWithOpenStreetMap(value);

    final locations = await _geocoding
        .locationFromAddress(value)
        .timeout(_requestTimeout);
    if (locations.isEmpty) return const [];

    final placemarks = await _geocoding
        .placemarkFromAddress(value)
        .timeout(_requestTimeout);
    return [
      for (var index = 0; index < locations.length && index < 5; index++)
        LocationSuggestion(
          address: index < placemarks.length
              ? _formatPlacemark(placemarks[index], fallback: value)
              : value,
          latitude: locations[index].latitude,
          longitude: locations[index].longitude,
        ),
    ];
  }

  Future<String> reverseGeocode(double latitude, double longitude) async {
    if (_useOpenStreetMapSearch) {
      return _reverseWithOpenStreetMap(latitude, longitude);
    }

    final placemarks = await _geocoding
        .placemarkFromCoordinates(latitude, longitude)
        .timeout(_requestTimeout);
    if (placemarks.isEmpty) return '';
    return _formatPlacemark(placemarks.first);
  }

  bool get _useOpenStreetMapSearch =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS);

  Future<List<LocationSuggestion>> _searchWithOpenStreetMap(
    String query,
  ) async {
    final uri = Uri.parse('$_nominatimBaseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '5',
      },
    );
    final response = await _nominatimGet(uri);
    final body = jsonDecode(response.body);
    if (body is! List) {
      throw const FormatException('Hasil pencarian alamat tidak valid.');
    }

    return [
      for (final item in body)
        if (item is Map<String, dynamic>)
          if (_validPoint(item['lat'], item['lon']))
            LocationSuggestion(
              address: item['display_name']?.toString() ?? query,
              latitude: double.parse(item['lat'].toString()),
              longitude: double.parse(item['lon'].toString()),
            ),
    ];
  }

  Future<String> _reverseWithOpenStreetMap(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse('$_nominatimBaseUrl/reverse').replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
        'zoom': '18',
        'addressdetails': '1',
      },
    );
    final response = await _nominatimGet(uri);
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Hasil alamat lokasi tidak valid.');
    }
    return body['display_name']?.toString() ?? '';
  }

  Future<http.Response> _nominatimGet(Uri uri) {
    return _serializeNominatimRequest(() async {
      final response = await httpClient
          .get(uri, headers: const {'User-Agent': _nominatimUserAgent})
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Layanan pencarian alamat merespons ${response.statusCode}.',
          uri,
        );
      }
      return response;
    });
  }

  Future<T> _serializeNominatimRequest<T>(Future<T> Function() request) {
    final result = Completer<T>();
    final previous = _nominatimQueue;
    final next = Completer<void>();
    _nominatimQueue = next.future;

    () async {
      await previous;
      try {
        final lastRequest = _lastNominatimRequest;
        if (lastRequest != null) {
          final elapsed = DateTime.now().difference(lastRequest);
          if (elapsed < _nominatimInterval) {
            await Future<void>.delayed(_nominatimInterval - elapsed);
          }
        }
        _lastNominatimRequest = DateTime.now();
        result.complete(await request());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        next.complete();
      }
    }();

    return result.future;
  }

  bool _validPoint(Object? latitude, Object? longitude) {
    final lat = double.tryParse('$latitude');
    final lon = double.tryParse('$longitude');
    return lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  String _formatPlacemark(
    geocoding.Placemark placemark, {
    String fallback = '',
  }) {
    final components = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];
    final parts = <String>[];
    for (final component in components) {
      final value = component?.trim();
      if (value != null && value.isNotEmpty && !parts.contains(value)) {
        parts.add(value);
      }
    }
    return parts.isEmpty ? fallback : parts.join(', ');
  }
}
