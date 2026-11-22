// ===================== IMPORT (memanggil library yang dipakai) =====================
import 'dart:io'; // untuk class File (menyimpan/membaca file foto)

import 'package:flutter/material.dart'; // widget dasar Flutter (Scaffold, Button, dll)
import 'package:geolocator/geolocator.dart'; // untuk tipe data Position (lat & long GPS)
import 'package:image_picker/image_picker.dart'; // untuk membuka kamera
import 'package:path/path.dart' as p; // membantu mengolah nama/alamat file
import 'package:path_provider/path_provider.dart'; // mencari folder penyimpanan di HP

import '../db/database_helper.dart'; // class untuk simpan data ke database SQLite
import '../models/survey_point.dart'; // model/struktur data satu titik survei
import '../services/location_service.dart'; // class untuk mengambil lokasi GPS

// ===================== WIDGET UTAMA =====================
// StatefulWidget = halaman yang tampilannya BISA BERUBAH
// (contoh: tombol GPS berubah teks setelah lokasi didapat)
class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

// Class State = tempat menyimpan data & logika halaman
// Tanda "_" di depan nama artinya private (hanya dipakai di file ini)
class _SurveyFormPageState extends State<SurveyFormPage> {
  // Kunci untuk mengontrol Form (dipakai untuk validasi & reset)
  final _formKey = GlobalKey<FormState>();

  // Controller = "pengendali" TextField, supaya kita bisa membaca isi ketikan
  final _namaController = TextEditingController();
  
  final _nimController = TextEditingController();

  // Daftar pilihan untuk dropdown kategori
  final List<String> _kategoriList = const ['Jalan', 'Bangunan', 'Drainase', 'Lainnya'];
  String? _kategoriTerpilih; // kategori yang dipilih user (tanda ? = boleh kosong/null)
  bool _kondisiRusak = false; // status checkbox: true = rusak, false = tidak

  Position? _posisiTerambil; // hasil GPS (null = belum diambil)
  File? _fotoTerambil; // hasil foto (null = belum difoto)
  bool _sedangMenyimpan = false; // true saat proses simpan berjalan (untuk loading)

  // dispose() dipanggil saat halaman ditutup
  // Controller harus dibuang agar tidak memenuhi memori
  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  // ===================== FUNGSI AMBIL LOKASI GPS =====================
  // async/await = menunggu proses yang butuh waktu (GPS tidak langsung dapat)
  Future<void> _ambilLokasi() async {
    try {
      // Minta posisi saat ini dari LocationService
      final posisi = await LocationService.getCurrentPosition();
      // setState = beri tahu Flutter agar tampilan digambar ulang
      setState(() => _posisiTerambil = posisi);
    } catch (e) {
      // Jika gagal (misal izin ditolak / GPS mati), tampilkan pesan error
      _tampilkanPesan(e.toString());
    }
  }

  // ===================== FUNGSI AMBIL FOTO =====================
  Future<void> _ambilFoto() async {
    final picker = ImagePicker();
    // Buka kamera, kualitas foto 70% supaya ukuran file tidak terlalu besar
    final xFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (xFile == null) return; // user batal foto -> berhenti

    // Foto dari kamera ada di folder sementara, jadi kita pindahkan
    // (salin) ke folder dokumen aplikasi supaya tidak hilang
    final docsDir = await getApplicationDocumentsDirectory();
    // Nama file unik memakai waktu sekarang, contoh: survei_1700000000000.jpg
    final namaFile = 'survei_${DateTime.now().millisecondsSinceEpoch}${p.extension(xFile.path)}';
    final fotoTersimpan = await File(xFile.path).copy(p.join(docsDir.path, namaFile));

    // Simpan ke variabel & gambar ulang layar agar preview foto muncul
    setState(() => _fotoTerambil = fotoTersimpan);
  }

  // ===================== FUNGSI SIMPAN DATA =====================
  Future<void> _simpan() async {
    // 1) Cek validasi form (nama & kategori wajib diisi). Jika gagal -> berhenti
    if (!_formKey.currentState!.validate()) return;

    // 2) Lokasi GPS wajib sudah diambil
    if (_posisiTerambil == null) {
      _tampilkanPesan('Ambil lokasi GPS dulu sebelum menyimpan.');
      return;
    }

    // 3) Tampilkan loading di tombol simpan
    setState(() => _sedangMenyimpan = true);

    // 4) Bungkus semua isian form menjadi satu objek SurveyPoint
    final point = SurveyPoint(
      namaSurveyor: _namaController.text.trim(), // trim() = hapus spasi berlebih
      nim: _nimController.text.trim(),
      kategori: _kategoriTerpilih!, // tanda ! = pasti tidak null (sudah divalidasi)
      kondisiRusak: _kondisiRusak,
      latitude: _posisiTerambil!.latitude,
      longitude: _posisiTerambil!.longitude,
      fotoPath: _fotoTerambil?.path, // tanda ?. = kalau foto null, hasilnya null (foto opsional)
      waktu: DateTime.now().toIso8601String(), // waktu survei dalam bentuk teks
    );

    // 5) Simpan ke database
    try {
      await DatabaseHelper.instance.insertSurveyPoint(point);
      if (!mounted) return;
      _tampilkanPesan('Data survei tersimpan.');
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      _tampilkanPesan('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  // ===================== FUNGSI KOSONGKAN FORM =====================
  // Dipanggil setelah data berhasil disimpan, supaya siap input data baru
  void _resetForm() {
    _formKey.currentState!.reset();
    _namaController.clear();
    _nimController.clear();
    setState(() {
      _kategoriTerpilih = null;
      _kondisiRusak = false;
      _posisiTerambil = null;
      _fotoTerambil = null;
    });
  }

  // ===================== FUNGSI TAMPIL PESAN =====================
  // SnackBar = pesan kecil yang muncul sebentar di bagian bawah layar
  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  // ===================== TAMPILAN (UI) =====================
  // build() dipanggil setiap setState, tugasnya menggambar layar
  @override
  Widget build(BuildContext context) {
    // Scaffold = kerangka halaman (ada AppBar di atas dan body di bawahnya)
    return Scaffold(
      appBar: AppBar(title: const Text('Survei')),
      body: Form(
        key: _formKey, // sambungkan Form dengan kunci agar bisa divalidasi
        // ListView = daftar vertikal yang bisa di-scroll
        child: ListView(
          padding: const EdgeInsets.all(16), // jarak tepi layar
          children: [
            // ---------- Input nama surveyor ----------
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Surveyor'),
              // validator: jika kosong, tampilkan pesan error merah; jika benar kembalikan null
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Nama surveyor wajib diisi' : null,
            ),
            const SizedBox(height: 16), // SizedBox = pemberi jarak kosong

            // ---------- Input NIM ----------
            TextFormField(
              controller: _nimController,
              keyboardType: TextInputType.number, // keyboard angka
              decoration: const InputDecoration(labelText: 'NIM'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'NIM wajib diisi' : null,
            ),

            // ---------- Dropdown kategori ----------
            DropdownButtonFormField<String>(
              initialValue: _kategoriTerpilih,
              decoration: const InputDecoration(labelText: 'Kategori Objek'),
              // Ubah daftar String menjadi daftar pilihan dropdown
              items: _kategoriList
                  .map((kategori) => DropdownMenuItem(value: kategori, child: Text(kategori)))
                  .toList(),
              // Saat user memilih, simpan pilihannya
              onChanged: (value) => setState(() => _kategoriTerpilih = value),
              validator: (value) => value == null ? 'Pilih kategori objek' : null,
            ),

            // ---------- Checkbox kondisi rusak ----------
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _kondisiRusak,
              title: const Text('Kondisi rusak?'),
              // value ?? false = kalau null, anggap false
              onChanged: (value) => setState(() => _kondisiRusak = value ?? false),
            ),
            const SizedBox(height: 8),

            // ---------- Tombol ambil lokasi GPS ----------
            OutlinedButton.icon(
              onPressed: _ambilLokasi,
              icon: const Icon(Icons.gps_fixed),
              // Teks tombol berubah: sebelum GPS = "Ambil Lokasi GPS",
              // sesudah GPS = tampil koordinat (5 angka di belakang koma)
              label: Text(
                _posisiTerambil == null
                    ? 'Ambil Lokasi GPS'
                    : 'Lokasi: ${_posisiTerambil!.latitude.toStringAsFixed(5)}, '
                        '${_posisiTerambil!.longitude.toStringAsFixed(5)}',
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Tombol ambil foto ----------
            OutlinedButton.icon(
              onPressed: _ambilFoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_fotoTerambil == null ? 'Ambil Foto' : 'Foto terambil'),
            ),

            // ---------- Preview foto (hanya muncul jika foto sudah ada) ----------
            // "if" di dalam list = tampilkan widget hanya bila kondisi benar
            if (_fotoTerambil != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8), // sudut membulat
                child: Image.file(_fotoTerambil!, height: 160, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),

            // ---------- Tombol simpan ----------
            FilledButton(
              // onPressed null = tombol nonaktif (saat sedang menyimpan, tidak bisa ditekan 2x)
              onPressed: _sedangMenyimpan ? null : _simpan,
              // Saat menyimpan tampil lingkaran loading, selain itu tampil teks
              child: _sedangMenyimpan
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Data Survei'),
            ),
          ],
        ),
      ),
    );
  }
}
