class SurveyPoint {
  final int? id;
  final String namaSurveyor;
  final String nim;
  final String kategori;
  final bool kondisiRusak;
  final double latitude;
  final double longitude;
  final String? fotoPath;
  final String waktu;
  final int terkirim;

  const SurveyPoint({
    this.id,
    required this.namaSurveyor,
    required this.nim,
    required this.kategori,
    required this.kondisiRusak,
    required this.latitude,
    required this.longitude,
    this.fotoPath,
    required this.waktu,
    this.terkirim = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_surveyor': namaSurveyor,
      'nim': nim,
      'kategori': kategori,
      'kondisi_rusak': kondisiRusak ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'foto_path': fotoPath,
      'waktu': waktu,
      'terkirim': terkirim,
    };
  }

  factory SurveyPoint.fromMap(Map<String, dynamic> map) {
    return SurveyPoint(
      id: map['id'] as int?,
      namaSurveyor: map['nama_surveyor'] as String,
      nim: (map['nim'] as String?) ?? '',
      kategori: map['kategori'] as String,
      kondisiRusak: (map['kondisi_rusak'] as int) == 1,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      fotoPath: map['foto_path'] as String?,
      waktu: map['waktu'] as String,
      terkirim: map['terkirim'] as int,
    );
  }
}