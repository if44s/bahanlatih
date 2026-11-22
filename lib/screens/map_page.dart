import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database_helper.dart';
import '../models/digitization_result.dart';
import '../models/survey_point.dart';
import '../services/location_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final GlobalKey _mapBoundaryKey = GlobalKey();
  LatLng? _currentLatLng;
  List<SurveyPoint> _savedPoints = [];
  StreamSubscription<Position>? _positionSub;
  SurveyPoint? _selected;
  final List<LatLng> _linePoints = [];
  bool _isDrawingLine = false;
  bool _isSavingDigitization = false;

  // [M. Arief Abdillah - NIM: V126241003] Peta Dasar: Default aktif Peta Rupabumi Indonesia (RBI) BIG
  bool _useRbiBasemap = true;

  static const LatLng _defaultCenter = LatLng(-6.200000, 106.816666);

  @override
  void initState() {
    super.initState();
    _loadSavedPoints();
    _startListeningLocation();
  }

  Future<void> _loadSavedPoints() async {
    final points = await DatabaseHelper.instance.getAllSurveyPoints();
    if (mounted) setState(() => _savedPoints = points);
  }

  void _startListeningLocation() {
    _positionSub = LocationService.getPositionStream().listen((position) {
      if (mounted) {
        setState(() =>
            _currentLatLng = LatLng(position.latitude, position.longitude));
      }
    });

    LocationService.getCurrentPosition().then((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _currentLatLng = latLng);
        _mapController.move(latLng, 16);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Widget _panelDetail(SurveyPoint point) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (point.fotoPath != null)
            Image.file(
              File(point.fotoPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${point.kategori} — ${point.namaSurveyor}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Kondisi rusak: ${point.kondisiRusak ? "Ya" : "Tidak"}'),
                Text(
                  'Koordinat: ${point.latitude.toStringAsFixed(5)}, '
                  '${point.longitude.toStringAsFixed(5)}',
                ),
                Text('Waktu: ${point.waktu}'),
                Text(
                    'Status: ${point.terkirim == 1 ? "Sudah terkirim" : "Belum terkirim"}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _lineDistance {
    const distance = Distance();
    var total = 0.0;
    for (var i = 1; i < _linePoints.length; i++) {
      total += distance.as(
        LengthUnit.Meter,
        _linePoints[i - 1],
        _linePoints[i],
      );
    }
    return total;
  }

  String get _formattedLineDistance {
    final distance = _lineDistance;
    return distance < 1000
        ? '${distance.toStringAsFixed(0)} m'
        : '${(distance / 1000).toStringAsFixed(2)} km';
  }

  void _handleMapTap(LatLng point) {
    if (_isDrawingLine) {
      setState(() {
        _linePoints.add(point);
        _selected = null;
      });
    } else {
      setState(() => _selected = null);
    }
  }

  Future<void> _simpanDigitasi() async {
    if (_linePoints.length < 2 || _isSavingDigitization) return;
    setState(() => _isSavingDigitization = true);

    try {
      final renderObject = _mapBoundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Peta belum siap untuk disimpan.');
      }

      final image = await renderObject.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('Gagal membuat gambar hasil digitasi.');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final waktu = DateTime.now();
      final imageFile = File(
        p.join(docsDir.path, 'digitasi_${waktu.millisecondsSinceEpoch}.png'),
      );
      await imageFile.writeAsBytes(byteData.buffer.asUint8List());

      try {
        await DatabaseHelper.instance.insertDigitizationResult(
          DigitizationResult(
            imagePath: imageFile.path,
            distanceMeters: _lineDistance,
            vertexCount: _linePoints.length,
            waktu: waktu.toIso8601String(),
          ),
        );
      } catch (_) {
        await imageFile.delete();
        rethrow;
      }

      if (!mounted) return;
      setState(() {
        _linePoints.clear();
        _isDrawingLine = false;
        _isSavingDigitization = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil digitasi tersimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingDigitization = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan hasil digitasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      for (final point in _savedPoints)
        Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 36,
          height: 36,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => setState(() => _selected = point),
            child: Icon(
              Icons.location_on,
              color: point.terkirim == 1
                  ? Colors.green
                  : const Color.fromARGB(255, 0, 255, 26),
            ),
          ),
        ),
      if (_currentLatLng != null)
        Marker(
          point: _currentLatLng!,
          width: 36,
          height: 36,
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
      for (var i = 0; i < _linePoints.length; i++)
        Marker(
          point: _linePoints[i],
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.deepOrange, width: 3),
            ),
          ),
        ),
    ];

    // [M. Arief Abdillah - NIM: V126241003] URL Peta Dasar: Default RBI (BIG), opsi OSM
    final tileUrl = _useRbiBasemap
        ? 'https://geoservices.big.go.id/rbi/rest/services/BASEMAP/Rupabumi_Indonesia/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta'),
        actions: [
          // [M. Arief Abdillah - NIM: V126241003] Switcher layer Peta Dasar RBI BIG / OSM
          TextButton.icon(
            onPressed: () => setState(() => _useRbiBasemap = !_useRbiBasemap),
            icon: const Icon(Icons.layers, size: 18),
            label: Text(_useRbiBasemap ? 'Layer: RBI BIG' : 'Layer: OSM'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _mapBoundaryKey,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLatLng ?? _defaultCenter,
                initialZoom: 15,
                onTap: (_, point) => _handleMapTap(point),
              ),
              children: [
                // [M. Arief Abdillah - NIM: V126241003] TileLayer dinamis RBI BIG & OSM
                TileLayer(
                  key: ValueKey(_useRbiBasemap),
                  urlTemplate: tileUrl,
                  userAgentPackageName:
                      'com.praktekmobilegis.praktek_mobile_gis',
                ),
                if (_linePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _linePoints,
                        color: Colors.deepOrange,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          if (_isDrawingLine || _linePoints.isNotEmpty)
            Positioned(
              top: 8,
              left: 8,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    _isDrawingLine
                        ? 'Ketuk peta untuk menambah titik'
                        : 'Garis: ${_linePoints.length} titik',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          if (_selected != null)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _panelDetail(_selected!),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_linePoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDrawingLine)
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _linePoints.removeLast()),
                      tooltip: 'Batalkan titik terakhir',
                      icon: const Icon(Icons.undo),
                    ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() {
                      _linePoints.clear();
                      _isDrawingLine = false;
                    }),
                    tooltip: 'Hapus garis',
                    icon: const Icon(Icons.delete_outline),
                  ),
                  if (!_isDrawingLine)
                    Text(
                      _formattedLineDistance,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (!_isDrawingLine && _linePoints.length >= 2)
                    IconButton.filledTonal(
                      onPressed: _isSavingDigitization ? null : _simpanDigitasi,
                      tooltip: 'Simpan hasil digitasi',
                      icon: _isSavingDigitization
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'reload-points',
                onPressed: _loadSavedPoints,
                tooltip: 'Muat ulang titik tersimpan',
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.extended(
                heroTag: 'draw-line',
                onPressed: () => setState(() {
                  _isDrawingLine = !_isDrawingLine;
                  _selected = null;
                }),
                icon: Icon(_isDrawingLine ? Icons.check : Icons.show_chart),
                label: Text(_isDrawingLine ? 'Selesai' : 'Gambar garis'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
