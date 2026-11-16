import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_palette.dart';
import '../models/delivery_location.dart';
import '../services/location_service.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  final DeliveryLocation? initialLocation;
  final String? initialAddress;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _locationService = LocationService();

  DeliveryLocation? _location;
  List<LocationSuggestion> _suggestions = const [];
  Timer? _searchDebounce;
  int _reverseRequest = 0;
  int _searchRequest = 0;
  int _locationRequest = 0;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isResolvingAddress = false;
  bool _isSearchDirty = false;
  bool _mapTileError = false;
  int _mapTileRetry = 0;
  String? _searchError;
  String? _locationError;
  double _zoom = 15;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    if (initial != null && initial.isValid) {
      _location = initial;
      _searchController.text = initial.address;
    } else if (widget.initialAddress?.trim().isNotEmpty ?? false) {
      _searchController.text = widget.initialAddress!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onSearchChanged(_searchController.text);
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _locationRequest++;
    final requestId = ++_searchRequest;
    _reverseRequest++;
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = const [];
        _searchError = null;
        _isSearching = false;
        _isSearchDirty = query.trim().isNotEmpty;
        _isResolvingAddress = false;
        if (query.trim().isEmpty) _isLocating = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _isSearchDirty = true;
      _isLocating = false;
      _isResolvingAddress = false;
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 1100),
      () => _searchAddress(query, requestId),
    );
  }

  Future<void> _searchAddress(String query, int requestId) async {
    try {
      final results = await _locationService.searchAddress(query);
      if (!mounted ||
          requestId != _searchRequest ||
          query != _searchController.text) {
        return;
      }
      setState(() {
        _suggestions = results;
        _isSearching = false;
        _searchError = results.isEmpty
            ? 'Alamat tidak ditemukan. Coba kata kunci lain.'
            : null;
      });
    } on TimeoutException {
      if (!mounted || requestId != _searchRequest) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Pencarian alamat melewati batas waktu.';
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequest) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Alamat belum dapat dicari. Periksa koneksi internet.';
      });
    }
  }

  void _chooseSuggestion(LocationSuggestion suggestion) {
    _reverseRequest++;
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _isSearchDirty = false;
      _searchController.text = suggestion.address;
      _location = DeliveryLocation(
        address: suggestion.address,
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
      );
      _locationError = null;
    });
    _moveMap(suggestion.point);
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    final requestId = ++_locationRequest;
    setState(() {
      _isLocating = true;
      _locationError = null;
      _isSearchDirty = false;
    });

    try {
      final position = await _locationService.currentPosition();
      if (!mounted || requestId != _locationRequest) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _location = DeliveryLocation(
          address: _fallbackAddress(point),
          latitude: point.latitude,
          longitude: point.longitude,
          accuracy: position.accuracy,
        );
        _isLocating = false;
        _isResolvingAddress = true;
      });
      _moveMap(point);
      await _resolveAddress(point);
    } on LocationServiceException catch (error) {
      if (!mounted || requestId != _locationRequest) return;
      final message = switch (error.failure) {
        LocationFailure.serviceDisabled =>
          'GPS tidak aktif. Aktifkan layanan lokasi atau cari alamat.',
        LocationFailure.permissionDenied =>
          'Izin lokasi ditolak. Anda tetap dapat mencari atau memilih lokasi di peta.',
        LocationFailure.permissionDeniedForever =>
          kIsWeb
              ? 'Izin lokasi ditolak. Aktifkan izin lokasi untuk situs ini di pengaturan browser.'
              : 'Izin lokasi ditolak permanen. Aktifkan izin dari pengaturan perangkat.',
      };
      setState(() {
        _isLocating = false;
        _locationError = message;
      });
      _showLocationSnack(
        message,
        action: error.failure == LocationFailure.permissionDeniedForever &&
                !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS)
            ? SnackBarAction(
                label: 'Pengaturan',
                onPressed: Geolocator.openAppSettings,
              )
            : null,
      );
    } on TimeoutException {
      if (!mounted || requestId != _locationRequest) return;
      const message =
          'Lokasi GPS belum ditemukan. Coba lagi atau pilih manual di peta.';
      setState(() {
        _isLocating = false;
        _locationError = message;
      });
      _showLocationSnack(message);
    } catch (_) {
      if (!mounted || requestId != _locationRequest) return;
      const message =
          'Lokasi GPS belum dapat diambil. Anda tetap dapat memilih manual.';
      setState(() {
        _isLocating = false;
        _locationError = message;
      });
      _showLocationSnack(message);
    }
  }

  void _showLocationSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      _zoom = event.camera.zoom;
      _updateCenter(event.camera.center);
    }
  }

  void _updateCenter(LatLng center) {
    _locationRequest++;
    final point = LatLng(center.latitude, center.longitude);
    final previous = _location;
    if (previous != null &&
        (previous.latitude - point.latitude).abs() < 0.0000001 &&
        (previous.longitude - point.longitude).abs() < 0.0000001) {
      return;
    }
    setState(() {
      _location = DeliveryLocation(
        address: _fallbackAddress(point),
        latitude: point.latitude,
        longitude: point.longitude,
      );
      _locationError = null;
      _isResolvingAddress = true;
      _isSearchDirty = false;
    });
    _resolveAddress(point);
  }

  Future<void> _resolveAddress(LatLng point) async {
    final requestId = ++_reverseRequest;
    try {
      final address = await _locationService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted || requestId != _reverseRequest) return;
      final current = _location;
      if (current == null) return;
      setState(() {
        _location = DeliveryLocation(
          address: address.trim().isEmpty ? _fallbackAddress(point) : address,
          latitude: point.latitude,
          longitude: point.longitude,
          accuracy: current.accuracy,
        );
        _searchController.text = _location!.address;
        _isResolvingAddress = false;
        _isSearchDirty = false;
      });
    } catch (_) {
      if (!mounted || requestId != _reverseRequest) return;
      setState(() {
        _isResolvingAddress = false;
        _locationError =
            'Alamat otomatis tidak tersedia. Koordinat lokasi tetap dapat digunakan.';
      });
    }
  }

  String _fallbackAddress(LatLng point) =>
      'Lokasi terpilih (${point.latitude.toStringAsFixed(6)}, '
      '${point.longitude.toStringAsFixed(6)})';

  void _moveMap(LatLng point) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(point, _zoom);
    });
  }

  void _zoomBy(double amount) {
    final controller = _mapController;
    final nextZoom = (controller.camera.zoom + amount).clamp(3.0, 19.0);
    setState(() => _zoom = nextZoom);
    controller.move(controller.camera.center, nextZoom);
  }

  void _confirmLocation() {
    final location = _location;
    if (location == null || !location.isValid) {
      setState(
        () => _locationError = 'Pilih lokasi yang valid terlebih dahulu.',
      );
      return;
    }
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi Pengiriman')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentukan lokasi penerimaan pesanan Anda',
                    style: text.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari alamat atau nama tempat',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Gunakan lokasi saya',
                              onPressed: _isLocating
                                  ? null
                                  : _useCurrentLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                            ),
                    ),
                  ),
                  if (_searchError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        _searchError!,
                        style: text.bodySmall?.copyWith(color: palette.danger),
                      ),
                    ),
                  if (_suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: Card(
                        margin: const EdgeInsets.only(top: 6),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined),
                              title: Text(
                                suggestion.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _chooseSuggestion(suggestion),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _location == null
                  ? _MapPrompt(
                      onUseCurrentLocation: _useCurrentLocation,
                      isLocating: _isLocating,
                      message: _locationError,
                    )
                  : _buildMap(palette),
            ),
            _locationDetails(palette, text),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _location?.isValid == true &&
                          !_isResolvingAddress &&
                          !_isSearchDirty &&
                          !_isSearching
                      ? _confirmLocation
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Gunakan Lokasi Ini'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(AppPalette palette) {
    final location = _location!;
    final center = LatLng(location.latitude, location.longitude);

    return Stack(
      children: [
        FlutterMap(
          key: ValueKey<int>(_mapTileRetry),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _zoom,
            minZoom: 3,
            maxZoom: 19,
            onMapEvent: _onMapEvent,
            onTap: (_, point) {
              _mapController.move(point, _zoom);
              _updateCenter(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tokotani',
              maxNativeZoom: 19,
              errorTileCallback: (_, _, _) {
                if (!_mapTileError && mounted) {
                  setState(() => _mapTileError = true);
                }
              },
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: const [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 46),
              child: Icon(
                Icons.location_pin,
                size: 46,
                color: palette.warning,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 5)],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              _MapControl(
                icon: Icons.add,
                tooltip: 'Perbesar peta',
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(height: 8),
              _MapControl(
                icon: Icons.remove,
                tooltip: 'Perkecil peta',
                onPressed: () => _zoomBy(-1),
              ),
              const SizedBox(height: 8),
              _MapControl(
                icon: Icons.my_location,
                tooltip: 'Gunakan lokasi saya',
                onPressed: _isLocating ? null : _useCurrentLocation,
              ),
            ],
          ),
        ),
        if (_mapTileError)
          Positioned(
            left: 12,
            top: 12,
            child: ActionChip(
              avatar: const Icon(Icons.wifi_off_rounded, size: 18),
              label: const Text('Peta gagal dimuat · Coba lagi'),
              onPressed: () => setState(() {
                _mapTileError = false;
                _mapTileRetry++;
              }),
            ),
          ),
        if (_isLocating)
          Positioned(
            left: 12,
            top: 12,
            child: Chip(
              avatar: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Mencari lokasi...'),
              backgroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _locationDetails(AppPalette palette, TextTheme text) {
    final location = _location;
    if (location == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          _locationError ??
              'Cari alamat atau gunakan lokasi GPS untuk memulai.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: palette.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_rounded, color: palette.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (_isResolvingAddress)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat ${location.latitude.toStringAsFixed(6)} · '
            'Lon ${location.longitude.toStringAsFixed(6)}'
            '${location.accuracy == null ? '' : ' · ±${location.accuracy!.round()} m'}',
            style: text.bodySmall?.copyWith(color: palette.textSecondary),
          ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _locationError!,
                style: text.bodySmall?.copyWith(color: palette.warning),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPrompt extends StatelessWidget {
  const _MapPrompt({
    required this.onUseCurrentLocation,
    required this.isLocating,
    this.message,
  });

  final VoidCallback onUseCurrentLocation;
  final bool isLocating;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ColoredBox(
      color: palette.neutralSoft,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 42, color: palette.brand),
              const SizedBox(height: 12),
              Text(
                message ??
                    'Cari alamat atau gunakan GPS untuk menampilkan peta. '
                        'Anda juga dapat memilih lokasi secara manual setelah peta terbuka.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isLocating ? null : onUseCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(isLocating ? 'Mencari lokasi...' : 'Lokasi saya'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
