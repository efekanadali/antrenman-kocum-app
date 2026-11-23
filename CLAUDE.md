# AntrenmanKoçum - Proje Kuralları ve Mimari Rehberi

## Teknoloji Yığını
- **Framework:** Flutter (Windows yolu: `C:\src\flutter\bin\flutter.bat`)
- **State Management:** Riverpod 2.x (`@riverpod` / `NotifierProvider`, kalıcı verilerde `keepAlive: true`)
- **Backend & Local:** Firebase Cloud Firestore + `SharedPreferences` (Offline-First mimari)
- **Grafikler:** `fl_chart`

## Tasarım Sistemi (Kesin Kurallar)
- **Tema:** Premium minimal obsidyen (WHOOP / Strong / Apple Fitness çizgisi). Tokenlar: `lib/presentation/theme/` (`AppColors`, `AppText`, `AppSpace`, `AppRadius`); ortak bileşenler: `lib/presentation/widgets/ui/ui.dart`.
- **Yasaklı Renkler:** Eski mor (`#1A1230`), lacivert, fosforlu neon sarı (`#C2F13A`) ve eski volkanik turuncu (`#FF5533`) KESİNLİKLE KULLANILMAYACAKTIR. Ekranlarda `Color(0x...)` sabiti yazılmaz; tüm renkler `AppColors`'tan gelir.
- **Yüzeyler:** Arka plan `AppColors.background` (#0B0D10), birincil yüzey `AppColors.surface` (#13161C), ikincil yüzey `AppColors.surfaceRaised` (#1A1E26). Kart = `AppSurface` (radius 16, padding 20–24, `0.5px` `AppColors.hairline` kenar). Kalın/dolu çerçeve ve iç içe kutu yok; bölümler `Hairline` ve geniş boşlukla ayrılır.
- **Vurgu disiplini:** Ana vurgu ferah atletik yeşil `AppColors.accent` (#A3E635); YALNIZCA ana CTA butonlarında (`PrimaryButton`) ve aktif/seçili öğelerde (seçili sekme, segment, hap/filtre, bugün, dokunulan grafik barı, Readiness halkası). Dolu `accent` yüzeylerin üzerindeki metin/ikon her zaman koyu obsidyen `AppColors.onAccent` (#0B0D10) olur, beyaz kullanılmaz. `AppColors.volcanic` yalnızca eski kod için `accent` takma adıdır; yeni kodda `accent` yazılır. Durum renkleri: hazır/artış `AppColors.emerald`, toparlanıyor `AppColors.amber`. Grafiklerde seçili olmayan öğeler `AppColors.chartNeutral`.
- **Tipografi:** Sayfa başlığı `AppText.pageTitle` (28, w600, -0.5); bölüm etiketi `SectionHeader` / `AppText.sectionLabel` (11, BÜYÜK HARF, 1.2, soluk gri). Tüm sayısal metrikler (MLI, tekrar, ağırlık, süre, yüzde) `AppText.metric*` ile ve `FontFeature.tabularFigures()` kullanılarak yazılır; fl_chart tooltip'lerinde stil açıkça tabular verilir.
- **İkonlar & Emoji:** Arayüzde emoji KULLANILMAZ. İkonlar yalnızca anlam taşıdığında, `_outlined` varyantında, 16–20px, `textMid`/`textMuted` renkte ve renkli kutu içine alınmadan kullanılır.
- **Anatomik harita & halka:** Kas dağılımı `AnatomicalMuscleMap` (17 kompartıman, ön/arka) ile gösterilir: egzersiz/yük dağılımında ve seçili filtrede `accent` (yüksek yük tam ton, ikincil yük soluk ton), toparlanma/yorgunlukta `amber`. Hazırlık gibi tek oranlar `SegmentedRing`, doğrusal ilerleme `SegmentedBar` ile çizilir.
- **Opaklık:** `withOpacity` kullanılmaz; const hex (`0x14FFFFFF`) veya `withValues(alpha:)`.

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