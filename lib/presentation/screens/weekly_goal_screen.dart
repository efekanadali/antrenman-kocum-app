// lib/presentation/screens/weekly_goal_screen.dart

import 'package:flutter/material.dart';

class WeeklyGoalScreen extends StatelessWidget {
  const WeeklyGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalik Hedef'),
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
                  'Hedef: 5 seans',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Tamamlanan: 4 seans',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.0),
                  child: LinearProgressIndicator(
                    value: 0.8,
                    minHeight: 10.0,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '1 seans daha ve hedef tamam!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Haftalik Plan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _PlanRow(day: 'Pzt', status: 'Tamamlandi'),
          const SizedBox(height: 8.0),
          _PlanRow(day: 'Car', status: 'Tamamlandi'),
          const SizedBox(height: 8.0),
          _PlanRow(day: 'Cum', status: 'Tamamlandi'),
          const SizedBox(height: 8.0),
          _PlanRow(day: 'Cmt', status: 'Tamamlandi'),
          const SizedBox(height: 8.0),
          _PlanRow(day: 'Paz', status: 'Bekliyor'),
          const SizedBox(height: 16.0),
          Text(
            'Odaklar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _TagRow(
            tags: const [
              _TagData(label: 'Push', icon: Icons.north),
              _TagData(label: 'Pull', icon: Icons.south),
              _TagData(label: 'Core', icon: Icons.bolt),
              _TagData(label: 'Mobility', icon: Icons.self_improvement),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Onerilen Seanslar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _SessionListCard(
            items: const [
              _SessionItemData(
                title: 'Skill + Push',
                subtitle: 'Handstand + dip kombosu',
                trailing: '35 dk',
              ),
              _SessionItemData(
                title: 'Pull + Core',
                subtitle: 'Pull-up, row, hollow hold',
                trailing: '40 dk',
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Son 4 Hafta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12.0),
          _MiniBarChart(
            title: 'Son 4 Hafta',
            bars: const [
              _BarData(label: 'H1', value: 0.6),
              _BarData(label: 'H2', value: 0.8),
              _BarData(label: 'H3', value: 0.7),
              _BarData(label: 'H4', value: 0.9),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.day, required this.status});

  final String day;
  final String status;

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
            day,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: status == 'Bekliyor'
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TagData {
  const _TagData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<_TagData> tags;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tag.icon, size: 16.0, color: colorScheme.primary),
                  const SizedBox(width: 6.0),
                  Text(
                    tag.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
                          margin: const EdgeInsets.symmetric(horizontal: 6.0),
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
