import 'dart:io';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/digitization_result.dart';
import '../models/survey_point.dart';

class _HistoryImage {
  const _HistoryImage.photo(this.point) : digitization = null;
  const _HistoryImage.digitization(this.digitization) : point = null;

  final SurveyPoint? point;
  final DigitizationResult? digitization;

  String get imagePath => point?.fotoPath ?? digitization!.imagePath;
  String get title => point?.kategori ?? 'Hasil Digitasi';
  String get waktu => point?.waktu ?? digitization!.waktu;
}

class PhotoHistoryPage extends StatefulWidget {
  const PhotoHistoryPage({super.key});

  @override
  State<PhotoHistoryPage> createState() => _PhotoHistoryPageState();
}

class _PhotoHistoryPageState extends State<PhotoHistoryPage> {
  late Future<List<_HistoryImage>> _futurePhotos;

  @override
  void initState() {
    super.initState();
    _futurePhotos = _muatFoto();
  }

  // Gabungkan foto survei dan screenshot digitasi yang masih tersedia.
  Future<List<_HistoryImage>> _muatFoto() async {
    final photos = await DatabaseHelper.instance.getAllSurveyPoints();
    final digitizations =
        await DatabaseHelper.instance.getAllDigitizationResults();

    return [
      for (final point in photos)
        if (point.fotoPath != null &&
            point.fotoPath!.isNotEmpty &&
            File(point.fotoPath!).existsSync())
          _HistoryImage.photo(point),
      for (final result in digitizations)
        if (result.imagePath.isNotEmpty && File(result.imagePath).existsSync())
          _HistoryImage.digitization(result),
    ]..sort((a, b) => b.waktu.compareTo(a.waktu));
  }

  void _segarkan() {
    setState(() {
      _futurePhotos = _muatFoto();
    });
  }

  void _bukaDetail(SurveyPoint point) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PhotoDetailPage(point: point)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _segarkan(),
        child: FutureBuilder<List<_HistoryImage>>(
          future: _futurePhotos,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final fotos = snapshot.data!;
            if (fotos.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada foto atau hasil digitasi.')),
                ],
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: fotos.length,
              itemBuilder: (context, index) {
                final item = fotos[index];
                return GestureDetector(
                  onTap: () {
                    if (item.point != null) {
                      _bukaDetail(item.point!);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _DigitizationDetailPage(
                            result: item.digitization!,
                          ),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(item.imagePath),
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              '${item.title}\n${item.waktu}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DigitizationDetailPage extends StatelessWidget {
  final DigitizationResult result;

  const _DigitizationDetailPage({required this.result});

  @override
  Widget build(BuildContext context) {
    final distance = result.distanceMeters < 1000
        ? '${result.distanceMeters.toStringAsFixed(0)} m'
        : '${(result.distanceMeters / 1000).toStringAsFixed(2)} km';

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Digitasi')),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(child: Image.file(File(result.imagePath))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jarak   : $distance'),
                Text('Titik   : ${result.vertexCount}'),
                Text('Waktu   : ${result.waktu}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoDetailPage extends StatelessWidget {
  final SurveyPoint point;

  const _PhotoDetailPage({required this.point});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(point.kategori)),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(child: Image.file(File(point.fotoPath!))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Surveyor : ${point.namaSurveyor} (${point.nim})'),
                Text('Waktu    : ${point.waktu}'),
                Text(
                  'Lokasi   : ${point.latitude.toStringAsFixed(5)}, '
                  '${point.longitude.toStringAsFixed(5)}',
                ),
                Text('Kondisi  : ${point.kondisiRusak ? "Rusak" : "Baik"}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
