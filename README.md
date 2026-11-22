# Praktek Mobile GIS

Aplikasi survei lapangan berbasis Flutter (Android dan iOS).

## 1. Ambil project

```
git clone https://github.com/andrebejo024-big/praktek-mobile-gis.git
cd praktek-mobile-gis
flutter pub get
```

Kalau sudah pernah clone, cukup `git pull` lalu `flutter pub get`.

## 2. Menjalankan di Android (Windows / macOS / Linux)

Persiapan:
- Flutter SDK terpasang (`flutter --version`; kalau lama, `flutter upgrade`).
- Android SDK terpasang. Cek dengan `flutter doctor`, bagian Android toolchain tidak boleh ada tanda silang.
- HP Android dengan **USB debugging** aktif, atau emulator Android.

Jalankan:
```
flutter devices
flutter run
```

`flutter devices` memastikan HP atau emulator terbaca. Build pertama bisa memakan waktu beberapa menit.

## 3. Menjalankan di iOS (iPhone / Simulator)

iOS **hanya bisa dijalankan di Mac** dengan Xcode. Di Windows atau Linux tidak bisa.

Persiapan (sekali saja):
1. Pasang **Xcode** dari App Store, buka sekali, dan setujui lisensinya:
   ```
   sudo xcodebuild -license accept
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```
2. Pasang **CocoaPods**:
   ```
   sudo gem install cocoapods
   ```
   (atau `brew install cocoapods`)
3. Cek dengan `flutter doctor`, bagian Xcode tidak boleh ada tanda silang.

Jalankan di **Simulator**:
```
open -a Simulator
flutter devices
flutter run
```

Jalankan di **iPhone asli**:
1. Sambungkan iPhone ke Mac dengan kabel, buka kunci layar, dan pilih **Trust** di iPhone.
2. Aktifkan **Developer Mode** di iPhone: Settings, Privacy & Security, Developer Mode.
3. Buka project di Xcode: `open ios/Runner.xcworkspace`.
4. Di Xcode pilih target **Runner**, tab **Signing & Capabilities**, centang **Automatically manage signing**, lalu pilih **Team** dengan Apple ID Anda (akun gratis boleh).
5. Kalau muncul error bundle identifier sudah dipakai, ganti **Bundle Identifier** menjadi nama unik, misalnya `com.praktekmobilegis.NAMAANDA`.
6. Kembali ke terminal:
   ```
   flutter devices
   flutter run
   ```
7. Pertama kali, di iPhone buka Settings, General, VPN & Device Management, lalu pilih **Trust** pada Apple ID Anda.

Catatan iOS:
- Izinkan akses **Lokasi** dan **Kamera** saat aplikasi memintanya.
- Dengan Apple ID gratis, aplikasi di iPhone kedaluwarsa setelah 7 hari dan perlu dijalankan ulang dari Mac.
- Jika `flutter run` gagal karena Pods, jalankan:
  ```
  cd ios
  pod install --repo-update
  cd ..
  flutter run
  ```
