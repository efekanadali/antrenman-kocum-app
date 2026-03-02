// lib/presentation/screens/total_time_screen.dart

import 'package:flutter/material.dart';

class TotalTimeScreen extends StatelessWidget {
  const TotalTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplam Sure'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: [
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu Ay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '3s 20d',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Toplam 9 seans',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Haftalik Dagilim',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _TimeRow(week: 'Hafta 1', value: '42 dk'),
          const SizedBox(height: 8.0),
          _TimeRow(week: 'Hafta 2', value: '56 dk'),
          const SizedBox(height: 8.0),
          _TimeRow(week: 'Hafta 3', value: '68 dk'),
          const SizedBox(height: 8.0),
          _TimeRow(week: 'Hafta 4', value: '54 dk'),
          const SizedBox(height: 16.0),
          Text(
            'Son Seanslar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _SessionListCard(
            items: const [
              _SessionItemData(
                title: 'Full Body',
                subtitle: '6 hareket • 52 dk',
                trailing: 'Bugun',
              ),
              _SessionItemData(
                title: 'Pull + Core',
                subtitle: '5 hareket • 44 dk',
                trailing: 'Dun',
              ),
              _SessionItemData(
                title: 'Push Day',
                subtitle: '5 hareket • 40 dk',
                trailing: '3 gun once',
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Gunluk Dagilim',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _MiniBarChart(
            title: 'Gunluk Dagilim',
            bars: const [
              _BarData(label: 'Pzt', value: 0.5),
              _BarData(label: 'Sal', value: 0.7),
              _BarData(label: 'Car', value: 0.4),
              _BarData(label: 'Per', value: 0.6),
              _BarData(label: 'Cum', value: 0.8),
              _BarData(label: 'Cmt', value: 0.3),
              _BarData(label: 'Paz', value: 0.2),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Aylik Toplamlar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _MetricGridCard(
            items: const [
              _MetricItemData(label: 'Seans', value: '9'),
              _MetricItemData(label: 'Set', value: '122'),
              _MetricItemData(label: 'Dakika', value: '200'),
              _MetricItemData(label: 'Kalori', value: '1850'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.week, required this.value});

  final String week;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text(
            week,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
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

class _SessionItemData {
  const _SessionItemData({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}

class _SessionListCard extends StatelessWidget {
  const _SessionListCard({required this.items});

  final List<_SessionItemData> items;

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
            _SessionTile(data: items[i]),
            if (i < items.length - 1) const SizedBox(height: 12.0),
          ],
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.data});

  final _SessionItemData data;

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

class _MetricItemData {
  const _MetricItemData({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetricGridCard extends StatelessWidget {
  const _MetricGridCard({required this.items});

  final List<_MetricItemData> items;

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
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: items
            .map(
              (item) => _MetricTile(data: item),
            )
            .toList(),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricItemData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = (MediaQuery.of(context).size.width - 16.0 * 2 - 12.0) / 2;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6.0),
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
