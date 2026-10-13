// lib/presentation/widgets/biomechanics_info_sheet.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// Hangi bilginin öncelikli olarak gösterileceğini belirten sekme filtresi.
enum BiomechanicsTopic {
  all('Tümü'),
  mli('MLI Formülü'),
  recovery('RIR Toparlanma');

  const BiomechanicsTopic(this.label);
  final String label;
}

/// Biyomekanik Formül ve RIR Toparlanma modelini açıklayan
/// "Premium Nordic & Cyber-Athlete" mat koyu temalı BottomSheet.
Future<void> showBiomechanicsInfoSheet(
  BuildContext context, {
  BiomechanicsTopic initialTopic = BiomechanicsTopic.all,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.70),
    builder: (ctx) => BiomechanicsInfoSheet(initialTopic: initialTopic),
  );
}

class BiomechanicsInfoSheet extends StatefulWidget {
  const BiomechanicsInfoSheet({
    super.key,
    this.initialTopic = BiomechanicsTopic.all,
  });

  final BiomechanicsTopic initialTopic;

  @override
  State<BiomechanicsInfoSheet> createState() => _BiomechanicsInfoSheetState();
}

class _BiomechanicsInfoSheetState extends State<BiomechanicsInfoSheet> {
  late BiomechanicsTopic _selectedTopic;

  static const Color _bg = AppColors.surface; // #13171C
  static const Color _surface = AppColors.surfaceSoft; // #181D24
  static const Color _border = AppColors.border; // #1E232A
  static const Color _volcanic = AppColors.volcanic; // #FF5533
  static const Color _emerald = AppColors.emerald; // #10B981
  static const Color _amber = AppColors.amber; // #F59E0B
  static const Color _red = AppColors.volcanic; // #FF5533
  static const Color _textHigh = AppColors.textHigh; // #F1F5F9
  static const Color _textMid = AppColors.textMid; // #94A3B8
  static const Color _textMuted = AppColors.textMuted; // #64748B

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.initialTopic;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: _border, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Sürükleme Tutamacı (Drag Handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Başlık Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.biotech_rounded,
                      color: _volcanic,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biyomekanik & Toparlanma',
                          style: TextStyle(
                            color: _textHigh,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kalistenik iş yükü ve kas toparlanma dinamikleri',
                          style: TextStyle(
                            color: _textMid,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _textMid, size: 20),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Konu Seçim Bölmeleri (Segmented Selector)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: BiomechanicsTopic.values.map((topic) {
                  final isSelected = _selectedTopic == topic;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTopic = topic;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _volcanic.withValues(alpha: 0.15)
                                : _surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? _volcanic.withValues(alpha: 0.50)
                                  : _border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              topic.label,
                              style: TextStyle(
                                color: isSelected ? _volcanic : _textMid,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),

            // Kaydırılabilir İçerik Alanı
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTopic == BiomechanicsTopic.all ||
                        _selectedTopic == BiomechanicsTopic.mli) ...[
                      _buildMliSection(),
                      if (_selectedTopic == BiomechanicsTopic.all)
                        const SizedBox(height: 20),
                    ],
                    if (_selectedTopic == BiomechanicsTopic.all ||
                        _selectedTopic == BiomechanicsTopic.recovery) ...[
                      _buildRecoverySection(),
                      const SizedBox(height: 20),
                    ],

                    // Kapat Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _volcanic,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Anladım',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Biyomekanik Formül (MLI) Bölümü
  Widget _buildMliSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _volcanic.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _volcanic.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.bolt_rounded, color: _volcanic, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'MLI (Muscular Workload Index)',
              style: TextStyle(
                color: _textHigh,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Formül Kutusu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İŞ YÜKÜ HESAPLAMA FORMÜLÜ',
                style: TextStyle(
                  color: _volcanic,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: const Text(
                  'MLI = Set × Tekrar × Kaldıraç Zorluk Katsayısı',
                  style: TextStyle(
                    color: _textHigh,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Statik tutuşlarda süre: Süre (sn) ÷ 2 olarak hesaba katılır.\n'
                '• Ek ağırlık eklendiğinde: (1 + Ek Ağırlık ÷ Vücut Ağırlığı) çarpanı uygulanır.',
                style: TextStyle(color: _textMuted, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Açıklama: Vücut Ağırlığı ve Kaldıraç Farkları
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.architecture_rounded, color: _emerald, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Kalistenikte Kaldıraç Neden Önemli?',
                    style: TextStyle(
                      color: _textHigh,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Geleneksel ağırlık antrenmanında direnç plaka ağırlığı ile sabitlenir. '
                'Kalistenikte ise kaslara binen yük vücut açısı ve eklem moment kolu (kaldıraç) ile değişir.',
                style: TextStyle(color: _textMid, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 10),
              _buildLeverageRow('Eğimli Şınav (Incline)', '0.70x', 'Vücut ağırlığının ~%45\'i taşınır'),
              const SizedBox(height: 6),
              _buildLeverageRow('Standart Şınav', '1.00x', 'Vücut ağırlığının ~%64\'ü taşınır'),
              const SizedBox(height: 6),
              _buildLeverageRow('Dips & Barfiks', '1.30x', 'Tüm vücut kütlesi yerçekimine karşı çekilir'),
              const SizedBox(height: 6),
              _buildLeverageRow('Planche / Front Lever', '1.80x - 2.20x', 'Moment kolu uzar, kas gerilimi katlanır'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeverageRow(String name, String factor, String note) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _textHigh,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(color: _textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _emerald.withValues(alpha: 0.3)),
            ),
            child: Text(
              factor,
              style: const TextStyle(
                color: _emerald,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. RIR Tabanlı Toparlanma (Recovery) Bölümü
  Widget _buildRecoverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _emerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _emerald.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.healing_rounded, color: _emerald, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'RIR Tabanlı Kas Toparlanması (Recovery)',
              style: TextStyle(
                color: _textHigh,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'RIR (Reps in Reserve), set sonrasında tükenişe kalan tahmini tekrar mesafenizdir. '
          'Tükenişe yaklaştıkça kas mikroyırtıkları ve sinir sistemi (CNS) yorgunluğu katlanarak artar.',
          style: TextStyle(color: _textMid, fontSize: 12, height: 1.45),
        ),
        const SizedBox(height: 12),

        // 3 Kademe Kartı
        _buildRirCard(
          badgeColor: _red,
          rirRange: '0 - 1 RIR (Tükeniş / Maksimal Efor)',
          hours: '48 - 72 Saat',
          description:
              'Kritik miyofibriler mikrohasar ve merkezi sinir sistemi tükenmesi. Kas lifi protein sentezi ve tam yenilenme için uzun dinlenme şarttır.',
          icon: Icons.local_fire_department_rounded,
        ),
        const SizedBox(height: 8),
        _buildRirCard(
          badgeColor: _amber,
          rirRange: '2 - 3 RIR (Optimal Hipertrofi)',
          hours: '36 - 48 Saat',
          description:
              'Maksimum kas uyarıcı mekanik gerilim ve dengeli yorgunluk. Kas grubu 1.5 - 2 günde süperkompansasyona ulaşır.',
          icon: Icons.offline_bolt_rounded,
        ),
        const SizedBox(height: 8),
        _buildRirCard(
          badgeColor: _emerald,
          rirRange: '4+ RIR (Hafif / Teknik & Hız)',
          hours: '24 Saat',
          description:
              'Düşük mikrohasar ve hafif sinirsel yük. Yüksek frekanslı teknik ve beceri çalışmaları için ertesi gün tekrar hazırdır.',
          icon: Icons.check_circle_outline_rounded,
        ),

        const SizedBox(height: 12),

        // Kümülatif Yorgunluk Notu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_rounded, color: _volcanic, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kümülatif Yorgunluk Koruması',
                      style: TextStyle(
                        color: _textHigh,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Bir kas grubu henüz %100 toparlanmadan tekrar çalıştırılırsa, '
                      'kalan saatler sıfırlanmaz; yeni seansın RIR yükü kümülatif olarak eklenerek sürantrenman (overtraining) riski engellenir.',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRirCard({
    required Color badgeColor,
    required String rirRange,
    required String hours,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: badgeColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rirRange,
                  style: const TextStyle(
                    color: _textHigh,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  hours,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: _textMid,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
