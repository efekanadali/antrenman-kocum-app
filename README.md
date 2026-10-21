<div align="center">

# ⚡ AntrenmanKoçum (Calisthenics App)

### Biyomekanik Tabanlı ve Kişiselleştirilmiş Kalistenik Antrenman Takip, Yük Analitiği ve İyileşme (Recovery) Sistemi

[![Flutter Version](https://img.shields.io/badge/Flutter-3.27%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.10%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/Riverpod-2.5%2B-0553B1?style=for-the-badge&logo=riverpod&logoColor=white)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Firebase-Firestore_%26_Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Visuals](https://img.shields.io/badge/Analytics-fl__chart_1.2%2B-FF5533?style=for-the-badge)](https://pub.dev/packages/fl_chart)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Arch_%2B_MVVM-10B981?style=for-the-badge)](https://blog.cleancoder.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](CONTRIBUTING.md)

<p align="center">
  <b>AntrenmanKoçum</b>, geleneksel ağırlık antrenmanı metriklerinin yetersiz kaldığı vücut ağırlığı (calisthenics) mekaniğini; <b>moment kolları, eklem torkları, kinetik kaldıraç çarpanları</b> ve <b>Fitness-Fatigue toparlanma dinamikleri</b> ile modelleyen açık kaynaklı, yeni nesil bir mobil atlet performans platformudur.
</p>

---

</div>

## 📑 İçindekiler
- [1. Problem Tanımı ve Mühendislik Motivasyonu](#1-problem-tanımı-ve-mühendislik-motivasyonu)
- [2. Temel Özellikler](#2-temel-özellikler)
- [3. Matematiksel & Biyomekanik Model](#3-matematiksel--biyomekanik-model)
  - [3.1 Muscular Workload Index (MLI) Formülasyonu](#31-muscular-workload-index-mli-formülasyonu)
  - [3.2 Kaldıraç Katsayıları (Leverage Factors)](#32-kaldıraç-katsayıları-leverage-factors)
  - [3.3 RIR & Zatsiorsky Toparlanma Modeli](#33-rir--zatsiorsky-toparlanma-modeli)
- [4. Sistem Mimarisi & Teknoloji Yığını](#4-sistem-mimarisi--teknoloji-yığını)
  - [4.1 Katmanlı Clean Architecture Şeması](#41-katmanlı-clean-architecture-şeması)
  - [4.2 Teknoloji Matrisi](#42-teknoloji-matrisi)
- [5. NoSQL Veritabanı & Firestore Şeması](#5-nosql-veritabanı--firestore-şeması)
- [6. Kurulum ve Çalıştırma Rehberi](#6-kurulum-ve-çalıştırma-rehberi)
- [7. Kullanıcı Arayüzü & Ekran Görüntüleri](#7-kullanıcı-arayüzü--ekran-görüntüleri)
- [8. Katkıda Bulunma ve Lisans](#8-katkıda-bulunma-ve-lisans)

---

## 1. Problem Tanımı ve Mühendislik Motivasyonu

Klasik direnç antrenmanı takip uygulamalarında iş yükü (tonaj) doğrusal skaler çarpımla hesaplanır:

$$\text{Tonaj} = \text{Set} \times \text{Tekrar} \times \text{Ağırlık}$$

Ancak bu formül **vücut ağırlığı antrenmanlarında (kalistenik) biyomekanik olarak geçersizdir**. Kalistenikte direnç, sabit bir dış kütleden ziyade; insan iskelet sisteminin yerçekimi vektörüne karşı oluşturduğu **kaldıraç açısı**, **moment kolu mesafesi** ($r$) ve ilgili ekleme binen **net tork** ($\vec{\tau} = \vec{r} \times \vec{F}$) tarafından belirlenir.

```
       [Geleneksel Model]                      [Kalistenik Biyomekanik Model]
    Direnç Sabittir (Plaka)             Direnç Değişkendir (Moment Kolu & Açı)
+-------------------------------+       +---------------------------------------------+
| 10 x Şınav     = 10 x Tekrar ? |  vs   | Incline Şınav  -> F ≈ 0.45 x m_body         |
| 10 x Dips      = 10 x Tekrar ? |       | Standart Şınav -> F ≈ 0.64 x m_body         |
| 10 x HSPU      = 10 x Tekrar ? |       | Planche Şınav  -> F ≈ 1.80-2.20 x Tork Çarp.|
+-------------------------------+       +---------------------------------------------+
(Yük farkını ayırt edemez)              (Gerçek kas lifi gerilimini modelleyebilir)
```

### Bilimsel Yaklaşımımız
1. **Moment Kolu Telafisi:** Farklı egzersiz progresyonlarının (örneğin *Knee Push-up* → *Standard Push-up* → *Archer Push-up* → *Full Planche*) yarattığı mekanik gerilim farklılıkları, deneysel biyomekanik kaldıraç çarpanı ($L_f$) ile eşitlenir.
2. **Statik ve Dinamik Normalizasyon:** Dinamik tekrarlar ile statik tutuşlar (izometrik kontraksiyonlar - *Front Lever*, *L-Sit*, *Planche Hold*) gerilim altındaki süre (Time Under Tension - TUT) temelli tek bir ortak iş yükü birimine dönüştürülür.
3. **Merkezi Sinir Sistemi (CNS) ve Kas İyileşmesi:** Tekrarların tükenişe yakınlığı (RIR - Reps In Reserve) ölçülerek, Vladimir Zatsiorsky'nin **İki Faktörlü Kondisyon-Yorgunluk (Fitness-Fatigue) Kuramı** ışığında kas grubu bazlı toparlanma periyotları dinamik olarak hesaplanır.

---

## 2. Temel Özellikler

* ⚡ **Muscular Workload Index (MLI):** Hem dinamik tekrar serilerini hem de izometrik gerilimleri eklem moment kolu, RIR şiddet katsayısı ve varsa ek ağırlık (weighted calisthenics) çarpanlarıyla tekilleştiren tork tabanlı yük indeksi.
* 🧬 **RIR Tabanlı Kişiselleştirilmiş İyileşme (Recovery):** 6 ana anatomik kas grubu (*Göğüs, Sırt, Omuz, Kol, Karın, Bacak*) için tükeniş mesafesine göre 24 ila 72 saat arasında değişken toparlanma süresi. Üst üste binen seanslarda aşırı yüklenmeyi engelleyen **Kümülatif Yorgunluk Koruması**.
* 📊 **Donanım İvmeli Veri Analitiği (`fl_chart`):** Kas gruplarına binen haftalık ve aylık yük dağılımlarını, optimal hipertrofi bantlarını (80–220 MLI aralığı) ve hacim dengesizliklerini gösteren interaktif grafikler.
* 🔄 **Offline-First & Çift Yönlü Arka Plan Eşitlemesi:** İnternet bağlantısı kesildiğinde dahi kesintisiz çalışan `SharedPreferences` tabanlı yerel önbellek; ağ erişimi sağlandığında `Cloud Firestore` ve `Firebase Auth` ile otomatik çift yönlü veri senkronizasyonu.
* 🎨 **Premium Nordic & Cyber-Athlete Tasarım Sistemi:** Derin obsidian siyahı (`#0A0C0E`), mat grafit yüzeyler (`#13171C`), kinetik volkanik turuncu (`#FF5533`) ve biyolojik zümrüt toparlanma yeşili (`#10B981`) ile oluşturulmuş yüksek kontrastlı, haptic geri bildirimli arayüz.
* 🛠️ **Özel Program Oluşturucu (Custom Program Builder):** Kendi split, gün ve hareket şablonlarınızı oluşturma; gerçek zamanlı biyomekanik MLI ve toparlanma önizlemesi alma imkanı.

---

## 3. Matematiksel & Biyomekanik Model

### 3.1 Muscular Workload Index (MLI) Formülasyonu

Bir seanstaki toplam kas yükü aşağıdaki integral toplamı ile ifade edilir:

$$\text{MLI}_{\text{total}} = \sum_{i=1}^{N_{\text{set}}} \left[ V_i \times L_{f,i} \times M_{\text{RIR},i} \times \left(1 + \frac{m_{\text{ek}}}{m_{\text{vücut}}}\right) \right]$$

Burada:
* **$V_i$ (Efektif Hacim):**
  * Dinamik egzersizler için: $V_i = \text{Tekrar Sayısı}$
  * Statik izometrik tutuşlar için: $V_i = \frac{t_{\text{saniye}}}{3.0}$ *(1 sn TUT $\approx$ 0.33–0.50 tekrar normalize katsayısı)*
* **$L_{f,i}$ (Leverage / Kaldıraç Faktörü):** İlgili varyasyonun moment kolu ve taşınan vücut ağırlığı yüzdesine bağlı biyomekanik çarpan.
* **$M_{\text{RIR},i}$ (Yoğunluk / Şiddet Çarpanı):**
  $$M_{\text{RIR}} = 1 + \frac{10 - \text{RIR}}{10}$$
  *(Statik tutuşlarda saniye rezervine göre $M_{\text{SIR}} \in [0.60, 1.05]$ tablosu kullanılır)*
* **$\omega_k$ (Kas Katılım Katsayısı):**
  $$\text{Yük}_k = \text{MLI} \times \omega_k \quad \text{burada} \quad \omega_{\text{primer}} = 1.0, \quad \omega_{\text{sinerjist}} = 0.5, \quad \omega_{\text{stabilizatör}} = 0.2$$

```dart
// MLI Hesaplama Çekirdeği (Domain Servisi Özeti)
double calculateMLI({
  required double volume,
  required double leverageFactor,
  required int rir,
  double weightMultiplier = 1.0,
}) {
  final double dynamicRirFactor = 1.0 + (10 - rir) / 10.0;
  return volume * leverageFactor * dynamicRirFactor * weightMultiplier;
}
```

---

### 3.2 Kaldıraç Katsayıları (Leverage Factors)

Kalistenikte eklem torkunu belirleyen kaldıraç varyasyonları standart referans matrisine bağlanmıştır:

| Egzersiz Sınıfı | Biyomekanik Örnek | Kaldıraç Katsayısı ($L_f$) | Etki Eden Kuvvet / Mekanizma |
| :--- | :--- | :---: | :--- |
| **Incline Push** | Yüksek Eğimli Şınav | `0.70x` | Vücut kütlesinin ~%40–45'i taşınır; moment kolu kısadır. |
| **Floor Horizontal** | Standart Şınav | `1.00x` | Taban pivot noktası ayak uçları; kütlenin ~%64'ü taşınır. |
| **Full Suspension** | Barfiks (Pull-up), Dips | `1.30x` | Kütlenin %100'ü serbest asılı; tam yerçekimi direnci. |
| **Unilateral Lever** | Archer Pull-up / Push-up | `1.50x` | Yük tek ekstremite üzerine kaydırılarak moment asimetrisi oluşturulur. |
| **Inverted Vertical** | Handstand Push-up (HSPU) | `1.70x` | Baş aşağı pozisyonda omuz kuşağı üzerine tam eksenel yüklenme. |
| **Extreme Extended** | Planche, Front Lever | `2.00x - 2.20x` | Ağırlık merkezi dayanak noktasından maksimum uzaklaşır; devasa eklem torku. |

---

### 3.3 RIR & Zatsiorsky Toparlanma Modeli

Vladimir Zatsiorsky'nin **Fitness-Fatigue (Kondisyon-Yorgunluk)** paradigmasına göre, yüksek şiddetteki egzersizler akut performansı (yorgunluk) düşürürken uzun vadeli süperkompansasyon potansiyelini tetikler.

RIR (Tükenişe Kalan Tekrar) parametresi doğrusal toparlanma fonksiyonuyla modellenir:

$$T_{\text{toparlanma}} = \text{clamp}\left(72.0 - 12.0 \times \text{RIR}, \; 24.0, \; 72.0\right) \quad [\text{saat}]$$

```
Toparlanma Süresi (Saat)
  72 sa +------------------------\ (0-1 RIR: Aşırı Yorgunluk / Maksimum Hasar)
        |                         \
  48 sa +--------------------------\ (2-3 RIR: Optimal Hipertrofi Aralığı)
        |                           \
  24 sa +----------------------------\====== (4+ RIR: Hafif / Deload / Teknik)
        +-----------------------------------+
        0           1           2           3           4+      [RIR Değeri]
```

* **0 – 1 RIR (48 – 72 Saat):** Yüksek miyofibriler mikrohasar ve merkezi sinir sistemi (MSS) depresyonu. Tam toparlanma ve protein sentezi için uzun dinlenme penceresi şarttır.
* **2 – 3 RIR (36 – 48 Saat):** Mekanik gerilim ile yorgunluk arasında optimal denge; 1.5–2 gün içinde süperkompansasyon zirvesine ulaşılır.
* **4+ RIR (24 Saat):** Düşük mikrohasar, nörolojik adaptasyon ve beceri çalışması; ertesi gün aynı kas grubu tekrar uyarılabilir.

#### Kümülatif Yorgunluk Koruma Prensibi
Bir kas grubu henüz toparlanmasını tamamlamadan ($t_{\text{current}} < t_{\text{ready}}$) yeni bir uyarana maruz kalırsa, önceki yorgunluk yok sayılmaz:

$$T_{\text{yeni\_ready}} = \max\left(t_{\text{eski\_ready}}, \; t_{\text{yeni\_seans}} + \Delta t_{\text{yeni\_toparlanma}}\right)$$

Bu sayede sporcunun sürantrenmana (overtraining) girmesi algoritmik olarak engellenir.

---

## 4. Sistem Mimarisi & Teknoloji Yığını

Uygulama, bağımlılıkların içe doğru aktığı **Clean Architecture** prensipleri ve **MVVM (Model-View-ViewModel)** tasarım kalıbı etrafında inşa edilmiştir.

### 4.1 Katmanlı Clean Architecture Şeması

```
                          KULLANICI ETKİLEŞİMİ (UI / TOUCH)
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION LAYER                                 │
│  ┌─────────────────────────┐  ┌────────────────────────┐  ┌──────────────────┐  │
│  │   Screens (Home,        │  │ Widgets (GlassCard,    │  │ Theme (Obsidian, │  │
│  │   Workout, Analytics)   │  │ BiomechanicsSheet)     │  │ Volcanic/Emerald)│  │
│  └───────────┬─────────────┘  └───────────┬────────────┘  └──────────────────┘  │
│              │                            │                                     │
│              ▼                            ▼                                     │
│  ┌─────────────────────────────────────────────────────┐                        │
│  │     Riverpod State Notifiers & Providers (MVVM)     │                        │
│  └───────────────────────────┬─────────────────────────┘                        │
└──────────────────────────────┼──────────────────────────────────────────────────┘
                               │ (Dependency Inversion)
                               ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 DOMAIN LAYER                                    │
│  ┌─────────────────────────┐  ┌────────────────────────┐  ┌──────────────────┐  │
│  │ Entities & Models       │  │ Domain Services        │  │ Repository       │  │
│  │ (Exercise, MLI, Record) │  │ (MLI Calc, Recovery)   │  │ Interfaces       │  │
│  └─────────────────────────┘  └────────────────────────┘  └─────────▲────────┘  │
└─────────────────────────────────────────────────────────────────────┼───────────┘
                                                                      │ (Implements)
┌─────────────────────────────────────────────────────────────────────┴───────────┐
│                                  DATA LAYER                                     │
│  ┌─────────────────────────┐  ┌────────────────────────┐  ┌──────────────────┐  │
│  │ Firestore Services      │  │ SharedPreferences      │  │ Repositories     │  │
│  │ (Auth, Cloud Sync)      │  │ (Offline Caching)      │  │ Implementation   │  │
│  └─────────────────────────┘  └────────────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
                    HARİCİ SERVİSLER (Cloud Firestore / Firebase Auth)
```

---

### 4.2 Teknoloji Matrisi

| Bileşen | Seçilen Teknoloji | Versiyon | Tercih ve Mühendislik Nedeni |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter | `^3.27.0` | Skia/Impeller destekli, 60/120 FPS donanım ivmeli tek kod tabanlı cross-platform motoru. |
| **Dil** | Dart | `^3.10.4` | Güçlü tip güvenliği, pattern matching, records ve asenkron stream yönetimi. |
| **State Management** | Flutter Riverpod | `^2.5.1` | Compile-time güvenliği, kolay test edilebilirlik ve reaktif bildirim mekanizması. |
| **Veritabanı (Cloud)** | Cloud Firestore | `^5.4.4` | Düşük gecikmeli gerçek zamanlı (WebSocket) dinleme ve doküman tabanlı esnek NoSQL veri modeli. |
| **Kimlik Doğrulama** | Firebase Auth | `^5.3.1` | Anonim oturum başlatma ve kesintisiz hesap yükseltme desteği. |
| **Grafik Motoru** | `fl_chart` | `^1.2.0` | Donanım ivmeli, dokunmatik tepkili ve yüksek performanslı çizelge kütüphanesi. |
| **Yerel Depolama** | `shared_preferences` | `^2.2.3` | Hızlı açılış süresi ve çevrimdışı önbellekleme katmanı. |
| **Tasarım Dili** | Nordic Cyber-Athlete | Özel Tema | Düşük ışıklı ortamlarda göz yormayan derin obsidian ve kinetik neon vurgular. |

---

## 5. NoSQL Veritabanı & Firestore Şeması

Veri mimarisi, ilişkisel olmayan (NoSQL) hiyerarşik koleksiyon yapısında modellenmiştir:

```
firestore_root
├── /exercises/{exerciseId}
└── /users/{uid}
    ├── /workout_sessions/{sessionId}
    ├── /custom_programs/{programId}
    └── /muscle_recovery/{muscleKey}
```

### Koleksiyon Detayları

#### 1. `/exercises/{exerciseId}` *(Global Katalog)*
Tüm kullanıcılar tarafından salt-okunur olarak dinlenen egzersiz kütüphanesi.
```json
{
  "id": "pull_up_standard",
  "name": "Standard Pull-up",
  "difficulty": 1.30,
  "leverageFactor": 1.30,
  "type": "calisthenics",
  "muscles": {
    "back": 1.0,
    "biceps": 0.5,
    "shoulders": 0.5,
    "core": 0.2
  },
  "createdAt": "2026-03-01T10:00:00Z"
}
```

#### 2. `/users/{uid}/workout_sessions/{sessionId}`
Tamamlanan her antrenman seansının detaylı dökümü.
```json
{
  "programId": "custom_push_hypertrophy",
  "programName": "Push Day Pro",
  "completedAt": "2026-03-01T14:30:00Z",
  "durationSeconds": 3120,
  "totalMli": 412.5,
  "muscleLoad": {
    "chest": 195.0,
    "shoulders": 135.0,
    "arms": 82.5
  },
  "muscleRir": {
    "chest": 1.8,
    "shoulders": 2.2,
    "arms": 1.5
  },
  "syncedAt": "FieldValue.serverTimestamp()"
}
```

#### 3. `/users/{uid}/custom_programs/{programId}`
Kullanıcının tasarladığı split ve egzersiz yapılandırması.
```json
{
  "id": "prog_abc123",
  "title": "Üst Vücut İtme & Çekme",
  "description": "Hipertrofi ve tork odaklı kalistenik spliti",
  "days": [
    {
      "dayIndex": 1,
      "dayName": "Pazartesi - Dikey İtme/Çekme",
      "exercises": [
        {
          "exerciseId": "pull_up_standard",
          "exerciseName": "Barfiks",
          "targetSets": 4,
          "targetReps": 8,
          "targetRir": 2
        }
      ]
    }
  ],
  "updatedAt": "FieldValue.serverTimestamp()"
}
```

#### 4. `/users/{uid}/muscle_recovery/{muscleKey}`
6 ana kas grubu için anlık toparlanma durumları.
```json
{
  "muscle": "chest",
  "lastTrainedAt": "2026-03-01T14:30:00Z",
  "recoveryHours": 50.4,
  "averageRir": 1.8,
  "load": 195.0,
  "updatedAt": "FieldValue.serverTimestamp()"
}
```

---

## 6. Kurulum ve Çalıştırma Rehberi

Projeyi yerel geliştirme ortamınızda derlemek ve çalıştırmak için aşağıdaki adımları izleyin.

### Ön Koşullar
* **Flutter SDK:** $\ge$ `3.27.0` ([Kurulum Kılavuzu](https://docs.flutter.dev/get-started/install))
* **Dart SDK:** $\ge$ `3.10.4`
* **Git SCM**
* **Android Studio / Xcode** (Emülatör veya fiziksel test cihazı)

### Adım Adım Kurulum

1. **Depoyu Klonlayın:**
   ```bash
   git clone https://github.com/efekanadali/calisthenics-app.git
   cd calisthenics-app
   ```

2. **Paket Bağımlılıklarını İndirin:**
   ```bash
   flutter pub get
   ```

3. **Kod Üretimini Gerçekleştirin (Build Runner):**
   Riverpod ve model anotasyonlarını üretmek için:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Firebase Yapılandırması:**
   * Android için Firebase Console üzerinden indirdiğiniz `google-services.json` dosyasını `android/app/` dizinine yerleştirin.
   * iOS için `GoogleService-Info.plist` dosyasını `ios/Runner/` dizinine ekleyin.

5. **Uygulamayı Başlatın:**
   ```bash
   # Bağlı cihazları listele
   flutter devices

   # Hata ayıklama modunda başlat
   flutter run
   ```

---

## 7. Kullanıcı Arayüzü & Ekran Görüntüleri

Tasarım felsefesi **Obsidian Siyahı**, **Volkanik Turuncu** ve **Zümrüt Yeşili** kinetik renk kontrastlarına dayanır.

| Ana Panel (Home Dashboard) | Biyomekanik & MLI Analitiği | Kas Toparlanma Radarı | Özel Program Planlayıcı |
| :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/dashboard.png" width="220" alt="Home Dashboard" onerror="this.src='https://placehold.co/400x850/13171C/FF5533?text=Dashboard+UI';"/> | <img src="docs/screenshots/mli_analytics.png" width="220" alt="MLI Analytics" onerror="this.src='https://placehold.co/400x850/13171C/10B981?text=MLI+Analytics';"/> | <img src="docs/screenshots/muscle_recovery.png" width="220" alt="Muscle Recovery" onerror="this.src='https://placehold.co/400x850/13171C/38BDF8?text=Recovery+Radar';"/> | <img src="docs/screenshots/program_builder.png" width="220" alt="Program Builder" onerror="this.src='https://placehold.co/400x850/13171C/F59E0B?text=Custom+Plan';"/> |


> Gerçek ekran görüntüleri proje tamamen bittikten sonra yüklenecektir. 

---

## 8. Katkıda Bulunma ve Lisans

Bu proje açık kaynak topluluğuna açıktır. Katkıda bulunmak için:

1. Bu depoyu çatallayın (Fork edin).
2. Özellik dalınızı oluşturun (`git checkout -b feature/YeniBiyomekanikHesap`).
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Yeni kaldıraç çarpanı entegre edildi'`).
4. Dalınıza push yapın (`git push origin feature/YeniBiyomekanikHesap`).
5. Bir **Pull Request (PR)** açın.

### Lisans
Bu proje [MIT Lisansı](LICENSE) kapsamında lisanslanmıştır. Telif Hakkı © 2026 **AntrenmanKoçum Contributors**.
