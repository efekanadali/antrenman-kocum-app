# AntrenmanKoçum - Proje Kuralları ve Mimari Rehberi

## Teknoloji Yığını
- **Framework:** Flutter (Windows yolu: `C:\src\flutter\bin\flutter.bat`)
- **State Management:** Riverpod 2.x (`@riverpod` / `NotifierProvider`, kalıcı verilerde `keepAlive: true`)
- **Backend & Local:** Firebase Cloud Firestore + `SharedPreferences` (Offline-First mimari)
- **Grafikler:** `fl_chart`

## Tasarım Sistemi (Kesin Kurallar)
- **Tema:** Premium minimal; varsayılan **Açık Tema**, Profil > "Koyu Tema (Dark Mode)" anahtarıyla **Koyu Tema** (`themeModeProvider`, `SharedPreferences` anahtarı `app_theme_mode`). Tokenlar: `lib/presentation/theme/` (`AppPalette.light` / `AppPalette.dark`, `AppColors`, `AppText`, `AppSpace`, `AppRadius`); ortak bileşenler: `lib/presentation/widgets/ui/ui.dart`.
- **Dinamik renkler:** `AppColors.*` ve `AppText.*` aktif paleti okuyan getter'lardır; bu yüzden `const` ifadelerde, `static final`/üst düzey `final` alanlarda veya varsayılan parametre değerlerinde KULLANILMAZ (önbelleğe alınır, tema değişince güncellenmez). Gerekirse getter (`static Color get x => AppColors.y;`) veya build içinde `param ?? AppColors.y` kullanılır. Tema değişince kök (`main.dart`) tüm elementleri yeniden kurar.
- **Yasaklı Renkler:** Eski mor (`#1A1230`), lacivert ve fosforlu neon sarı (`#C2F13A`) KULLANILMAZ. Ekranlarda `Color(0x...)` sabiti yazılmaz; tüm renkler `AppColors`'tan gelir. Mercan `#FF5533` yalnızca `AppColors.activation` üzerinden (açık temada kas aktivasyonu / seçili kas, "+" ve "AKTİF PROGRAM" gibi vurgu etiketleri) kullanılır.
- **Açık palet:** zemin `#F5F6F8`, kart `#FFFFFF`, kenar `#E2E8F0`, metin/CTA obsidyen `#111827` (üstünde beyaz `onAccent`), hazırlık/ilerleme `AppColors.ring` zümrüt `#10B981`, kas aktivasyonu `AppColors.activation` mercan `#FF5533`.
- **Koyu palet:** zemin `#0B0D10`, yüzey `#13161C` / `#1A1E26`, vurgu `accent` / `ring` / `activation` atletik yeşil `#A3E635` (üstünde koyu `onAccent` `#0B0D10`).
- **Yüzeyler:** Kart = `AppSurface` (radius 16, padding 20–24, ince `AppColors.hairline` kenar). Kalın/dolu çerçeve ve iç içe kutu yok; bölümler `Hairline` ve geniş boşlukla ayrılır.
- **Vurgu disiplini:** `AppColors.accent` YALNIZCA ana CTA butonlarında (`PrimaryButton`) ve aktif/seçili öğelerde (seçili sekme, segment, hap/filtre, bugün). Dolu `accent` yüzeylerin üzerindeki metin/ikon her zaman `AppColors.onAccent`. `AppColors.volcanic` yalnızca eski kod için `accent` takma adıdır. Durum renkleri: hazır/artış `AppColors.emerald`, toparlanıyor `AppColors.amber`. Grafiklerde seçili olmayan öğeler `AppColors.chartNeutral`.
- **Tipografi:** Sayfa başlığı `AppText.pageTitle` (28, w600, -0.5); bölüm etiketi `SectionHeader` / `AppText.sectionLabel` (11, BÜYÜK HARF, 1.2, soluk gri). Tüm sayısal metrikler (MLI, tekrar, ağırlık, süre, yüzde) `AppText.metric*` ile ve `FontFeature.tabularFigures()` kullanılarak yazılır; fl_chart tooltip'lerinde stil açıkça tabular verilir.
- **İkonlar & Emoji:** Arayüzde emoji KULLANILMAZ. İkonlar yalnızca anlam taşıdığında, `_outlined` varyantında, 16–20px, `textMid`/`textMuted` renkte kullanılır.
- **Anatomik harita & halka:** Kas dağılımı `AnatomicalMuscleMap` (17 kompartıman, ön/arka) ile gösterilir: egzersiz/yük dağılımında ve seçili filtrede varsayılan `AppColors.activation` (yüksek yük tam ton, ikincil yük soluk ton), toparlanma/yorgunlukta `amber`. Hazırlık gibi tek oranlar `SegmentedRing` (varsayılan `AppColors.ring`), doğrusal ilerleme `SegmentedBar` ile çizilir.
- **Opaklık:** `withOpacity` kullanılmaz; `withValues(alpha:)`.

## Egzersiz Kataloğu (Faz 7)
- `lib/domain/data/exercises/calisthenics_exercises.dart` (40) + `bodybuilding_exercises.dart` (40, `ExerciseType.bodybuilding`) → `exerciseCatalog` (80). Uygulama (repository, MLI çözümleyici, kütüphane, program oluşturucu) `exerciseCatalog`'u kullanır.
- `exerciseDatabase` MLI golden fixture'ları ve Firestore katalog senkronizasyonu (sürüm 2) için dondurulmuş 38 hareketlik kalistenik çekirdektir; içeriği DEĞİŞTİRİLMEZ. `FakeExerciseRepository.getAllExercises()` de bu 38'i döner; 80'lik katalog `getCatalogExercises()` / `catalogExercises` ile alınır.
- Yeni hareket eklerken: kompartıman ağırlık toplamı 1.00, her 17 kompartıman en az 2 harekette birincil kas, Türkçe açıklama `phase7_exercise_descriptions.dart` biçiminde, süreli hareketler `isTimedExercise` listesinde (`test/exercise_catalog_phase7_test.dart` doğrular).

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