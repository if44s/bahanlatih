import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/survey_point.dart';

class ApiService {
  // Pertemuan 13: ganti dengan URL Web App hasil deploy Google Apps Script.
  static const String scriptUrl = 'GANTI_DENGAN_URL_GOOGLE_APPS_SCRIPT';

  static Future<bool> kirimSurveyPoint(SurveyPoint point) async {
    if (scriptUrl == 'GANTI_DENGAN_URL_GOOGLE_APPS_SCRIPT') {
      throw Exception('URL Google Apps Script belum diisi di lib/services/api_service.dart');
    }

    final response = await http.post(
      Uri.parse(scriptUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama_surveyor': point.namaSurveyor,
        'kategori': point.kategori,
        'kondisi_rusak': point.kondisiRusak ? 'Ya' : 'Tidak',
        'latitude': point.latitude,
        'longitude': point.longitude,
        'foto_path': point.fotoPath ?? '',
        'waktu': point.waktu,
      }),
    );

    return response.statusCode == 200;
  }
}
