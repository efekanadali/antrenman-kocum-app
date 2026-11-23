// lib/presentation/widgets/biomechanics_info_sheet.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

/// Hangi bilginin öncelikli olarak gösterileceğini belirten sekme filtresi.
enum BiomechanicsTopic {
  all('Tümü'),
  mli('MLI Formülü'),
  recovery('RIR Toparlanma');

  const BiomechanicsTopic(this.label);
  final String label;
}

/// Biyomekanik formül ve RIR toparlanma modelini açıklayan bottom sheet.
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

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.initialTopic;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final showMli = _selectedTopic == BiomechanicsTopic.all ||
        _selectedTopic == BiomechanicsTopic.mli;
    final showRecovery = _selectedTopic == BiomechanicsTopic.all ||
        _selectedTopic == BiomechanicsTopic.recovery;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                0,
                AppSpace.sm,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biyomekanik & Toparlanma',
                          style: TextStyle(
                            color: AppColors.textHigh,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kalistenik iş yükü ve kas toparlanma dinamikleri',
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Kapat',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMid,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: AppSegmentedControl<BiomechanicsTopic>(
                values: BiomechanicsTopic.values,
                labelOf: (t) => t.label,
                selected: _selectedTopic,
                onChanged: (t) => setState(() => _selectedTopic = t),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const Hairline(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.xxl,
                  AppSpace.page,
                  AppSpace.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showMli) _buildMliSection(),
                    if (showMli && showRecovery) ...[
                      const SizedBox(height: AppSpace.section),
                      const Hairline(),
                      const SizedBox(height: AppSpace.section),
                    ],
                    if (showRecovery) _buildRecoverySection(),
                    const SizedBox(height: AppSpace.section),
                    GhostButton(
                      label: 'Anladım',
                      expand: true,
                      height: 48,
                      onPressed: () => Navigator.of(context).pop(),
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
        const Text('MLI (Muscular Workload Index)', style: AppText.cardTitle),
        const SizedBox(height: AppSpace.lg),
        const SectionHeader(
          'İş yükü hesaplama formülü',
          padding: EdgeInsets.only(bottom: AppSpace.sm),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'MLI = Set × Tekrar × Kaldıraç Zorluk Katsayısı',
            style: TextStyle(
              color: AppColors.textHigh,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        const Text(
          '• Statik tutuşlarda süre: Süre (sn) ÷ 2 olarak hesaba katılır.\n'
          '• Ek ağırlık eklendiğinde: (1 + Ek Ağırlık ÷ Vücut Ağırlığı) çarpanı uygulanır.',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        const SectionHeader(
          'Kalistenikte kaldıraç neden önemli?',
          padding: EdgeInsets.only(bottom: AppSpace.sm),
        ),
        const Text(
          'Geleneksel ağırlık antrenmanında direnç plaka ağırlığı ile sabitlenir. '
          'Kalistenikte ise kaslara binen yük vücut açısı ve eklem moment kolu (kaldıraç) ile değişir.',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        _buildLeverageRow(
          'Eğimli Şınav (Incline)',
          '0.70×',
          'Vücut ağırlığının ~%45\'i taşınır',
        ),
        const Hairline(),
        _buildLeverageRow(
          'Standart Şınav',
          '1.00×',
          'Vücut ağırlığının ~%64\'ü taşınır',
        ),
        const Hairline(),
        _buildLeverageRow(
          'Dips & Barfiks',
          '1.30×',
          'Tüm vücut kütlesi yerçekimine karşı çekilir',
        ),
        const Hairline(),
        _buildLeverageRow(
          'Planche / Front Lever',
          '1.80–2.20×',
          'Moment kolu uzar, kas gerilimi katlanır',
        ),
      ],
    );
  }

  Widget _buildLeverageRow(String name, String factor, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(note, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Text(factor, style: AppText.metricS),
        ],
      ),
    );
  }

  /// 2. RIR Tabanlı Toparlanma (Recovery) Bölümü
  Widget _buildRecoverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RIR Tabanlı Kas Toparlanması (Recovery)',
          style: AppText.cardTitle,
        ),
        const SizedBox(height: AppSpace.md),
        const Text(
          'RIR (Reps in Reserve), set sonrasında tükenişe kalan tahmini tekrar mesafenizdir. '
          'Tükenişe yaklaştıkça kas mikroyırtıkları ve sinir sistemi (CNS) yorgunluğu katlanarak artar.',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        _buildRirRow(
          dotColor: AppColors.textHigh,
          rirRange: '0 - 1 RIR (Tükeniş / Maksimal Efor)',
          hours: '48–72 sa',
          description:
              'Kritik miyofibriler mikrohasar ve merkezi sinir sistemi tükenmesi. Kas lifi protein sentezi ve tam yenilenme için uzun dinlenme şarttır.',
        ),
        const Hairline(),
        _buildRirRow(
          dotColor: AppColors.amber,
          rirRange: '2 - 3 RIR (Optimal Hipertrofi)',
          hours: '36–48 sa',
          description:
              'Maksimum kas uyarıcı mekanik gerilim ve dengeli yorgunluk. Kas grubu 1.5 - 2 günde süperkompansasyona ulaşır.',
        ),
        const Hairline(),
        _buildRirRow(
          dotColor: AppColors.emerald,
          rirRange: '4+ RIR (Hafif / Teknik & Hız)',
          hours: '24 sa',
          description:
              'Düşük mikrohasar ve hafif sinirsel yük. Yüksek frekanslı teknik ve beceri çalışmaları için ertesi gün tekrar hazırdır.',
        ),
        const SizedBox(height: AppSpace.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kümülatif yorgunluk koruması',
                style: TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bir kas grubu henüz %100 toparlanmadan tekrar çalıştırılırsa, '
                'kalan saatler sıfırlanmaz; yeni seansın RIR yükü kümülatif olarak eklenerek sürantrenman (overtraining) riski engellenir.',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRirRow({
    required Color dotColor,
    required String rirRange,
    required String hours,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(color: dotColor),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  rirRange,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Text(hours, style: AppText.metricS),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              description,
              style: AppText.caption.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
