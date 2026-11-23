# AntrenmanKoçum - Proje Kuralları ve Mimari Rehberi

## Teknoloji Yığını
- **Framework:** Flutter (Windows yolu: `C:\src\flutter\bin\flutter.bat`)
- **State Management:** Riverpod 2.x (`@riverpod` / `NotifierProvider`, kalıcı verilerde `keepAlive: true`)
- **Backend & Local:** Firebase Cloud Firestore + `SharedPreferences` (Offline-First mimari)
- **Grafikler:** `fl_chart`

## Tasarım Sistemi (Kesin Kurallar)
- **Tema:** Premium Nordic Dark (Obsidian & Volkanik Turuncu).
- **Yasaklı Renkler:** Eski mor (`#1A1230`), lacivert ve fosforlu neon sarı/lime (`#C2F13A`) KESİNLİKLE KULLANILMAYACAKTIR.
- **Standart Renkler:** Tüm renkler `AppColors` sınıfından çekilmelidir (Arka plan: mat kömür, kartlar: `AppColors.surface` + `1px` `AppColors.border` + `BorderRadius.circular(14.0)`, ana aksiyon butonları: `AppColors.volcanic`, başarı/hazır durumu: `AppColors.emerald`).

## Biyomekanik Motor Kuralları
- **Hibrit MLI Formülü:**
  - Kalistenik: `MLI = Hacim × Lf × (1 + Ek_Ağırlık / Vücut_Ağırlığı) × M_rating`
  - Vücut Geliştirme: `MLI = Set × Tekrar × (Kaldırılan_Ağırlık / Vücut_Ağırlığı) × Lf_bb × M_rating`
- **İzometrik Eşdeğerlik:** `1 saniye statik tutuş = 0.5 tekrar` (süre bazlı egzersizlerde tekrar yerine saniye gösterilir).
- **Kas Kompartımanları:** Toplam kas ağırlığı her egzersiz için tam `1.00` olmalıdır.

## Kod Kalitesi & Doğrulama
- `build()` metotları içinde asla `FutureBuilder` veya veritabanı sorgusu çağrılmaz; veriler önbellekli Riverpod provider'larından okunur.
- Route argümanlarında doğrudan `as` cast yapılmaz; `is!` ile güvenli tip kontrolü uygulanır.
- Büyük değişikliklerden sonra mutlaka `C:\src\flutter\bin\flutter.bat analyze` çalıştırılarak **0 issue** doğrulanır.