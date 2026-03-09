// lib/presentation/screens/streak_details_screen.dart

import 'package:flutter/material.dart';

class StreakDetailsScreen extends StatelessWidget {
  const StreakDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seri'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: [
          _HighlightCard(
            title: 'Mevcut Seri',
            value: '7 gün',
            subtitle: 'Araliksiz antrenman',
            icon: Icons.local_fire_department,
          ),
          const SizedBox(height: 12.0),
          _HighlightCard(
            title: 'En İyi Seri',
            value: '14 gün',
            subtitle: 'Kendi rekorun',
            icon: Icons.emoji_events,
          ),
          const SizedBox(height: 12.0),
          _HighlightCard(
            title: 'Son 30 Gün',
            value: '18 gün',
            subtitle: 'Aktif antrenman gunu',
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Seri Tavsiyeleri',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün 10-15 dk karın ekleyerek seriyi koru.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Haftada en az 1 aktif dinlenme planla.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Son 7 Gün Aktivite',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _MiniBarChart(
            title: 'Son 7 Gün Aktivite',
            bars: const [
              _BarData(label: 'Pzt', value: 0.6),
              _BarData(label: 'Sal', value: 0.8),
              _BarData(label: 'Car', value: 0.4),
              _BarData(label: 'Per', value: 0.7),
              _BarData(label: 'Cum', value: 0.9),
              _BarData(label: 'Cmt', value: 0.3),
              _BarData(label: 'Paz', value: 0.5),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Seri Günlüğü',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _LogListCard(
            items: const [
              _LogItemData(
                title: 'İtiş Günü',
                subtitle: '45 dk • 5 hareket',
                trailing: 'Bugün',
              ),
              _LogItemData(
                title: 'Çekiş Günü',
                subtitle: '50 dk • 6 hareket',
                trailing: 'Dün',
              ),
              _LogItemData(
                title: 'Karın + Mobilite',
                subtitle: '30 dk • 4 hareket',
                trailing: '2 gün önce',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  const _BarData({required this.label, required this.value});

  final String label;
  final double value;
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.title, required this.bars});

  final String title;
  final List<_BarData> bars;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18.0),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12.0),
                  for (final bar in bars) ...[
                    _DetailRow(label: bar.label, value: bar.value),
                    const SizedBox(height: 8.0),
                  ],
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars
              .map(
                (bar) => Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FractionallySizedBox(
                        heightFactor: bar.value.clamp(0.1, 1.0),
                        child: Container(
                          height: 90.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        bar.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (value * 100).round();

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _LogItemData {
  const _LogItemData({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}

class _LogListCard extends StatelessWidget {
  const _LogListCard({required this.items});

  final List<_LogItemData> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _LogTile(data: items[i]),
            if (i < items.length - 1) const SizedBox(height: 12.0),
          ],
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.data});

  final _LogItemData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                data.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        Text(
          data.trailing,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
