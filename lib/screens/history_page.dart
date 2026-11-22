import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/survey_point.dart';
import '../services/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<SurveyPoint>> _futurePoints;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    setState(() {
      _futurePoints = DatabaseHelper.instance.getAllSurveyPoints();
    });
  }

  Future<void> _hapus(int id) async {
    await DatabaseHelper.instance.deleteSurveyPoint(id);
    _muatUlang();
  }

  Future<void> _kirim(SurveyPoint point) async {
    try {
      final berhasil = await ApiService.kirimSurveyPoint(point);
      if (berhasil && point.id != null) {
        await DatabaseHelper.instance.markAsTerkirim(point.id!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(berhasil ? 'Terkirim ke server.' : 'Gagal mengirim.')),
      );
      _muatUlang();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Survei')),
      body: FutureBuilder<List<SurveyPoint>>(
        future: _futurePoints,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final points = snapshot.data!;
          if (points.isEmpty) {
            return const Center(child: Text('Belum ada data survei.'));
          }
          return ListView.builder(
            itemCount: points.length,
            itemBuilder: (context, index) {
              final point = points[index];
              return ListTile(
                leading: Icon(
                  point.terkirim == 1 ? Icons.cloud_done : Icons.cloud_off,
                  color: point.terkirim == 1 ? Colors.green : Colors.grey,
                ),
                title: Text('${point.kategori} — ${point.namaSurveyor}'),
                subtitle: Text(
                  '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}\n'
                  '${point.waktu}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      tooltip: 'Kirim ke server',
                      onPressed: () => _kirim(point),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Hapus',
                      onPressed: () => _hapus(point.id!),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
