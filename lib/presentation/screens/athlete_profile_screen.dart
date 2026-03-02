// lib/presentation/screens/athlete_profile_screen.dart

import 'package:flutter/material.dart';

class AthleteProfileScreen extends StatelessWidget {
  const AthleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlet Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: const [
          _ProfileHeaderCard(
            name: 'Deniz Kaya',
            level: 'Orta Seviye',
            tagline: 'Skill odakli calisthenics',
            weight: '72.4 kg',
            height: '178 cm',
            age: '26',
          ),
          SizedBox(height: 16.0),
          _TagRow(
            tags: [
              _TagData(label: 'Handstand', icon: Icons.self_improvement),
              _TagData(label: 'Pull-up', icon: Icons.fitness_center),
              _TagData(label: 'Core', icon: Icons.bolt),
            ],
          ),
          SizedBox(height: 16.0),
          _SectionTitle(title: 'Atlet Profili'),
          SizedBox(height: 12.0),
          _ProfileSummaryCard(
            level: 'Orta Seviye',
            goal: 'Guc + Skill',
            frequency: 'Haftada 4 gun',
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Guclu Hareketler',
            child: _SimpleListCard(
              items: [
                _ListItemData(
                  title: 'Pull-up',
                  subtitle: '4 set x 10 tekrar',
                  trailing: 'Son: 2 gun once',
                ),
                _ListItemData(
                  title: 'Dip',
                  subtitle: '4 set x 12 tekrar',
                  trailing: 'Son: 4 gun once',
                ),
                _ListItemData(
                  title: 'Pike Push-up',
                  subtitle: '3 set x 10 tekrar',
                  trailing: 'Son: 6 gun once',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Skill Ilerleme',
            child: _ProgressListCard(
              items: [
                _ProgressItemData(
                  title: 'Handstand',
                  level: 'Duvar destekli',
                  progress: 0.55,
                ),
                _ProgressItemData(
                  title: 'Front Lever',
                  level: 'Tuck',
                  progress: 0.35,
                ),
                _ProgressItemData(
                  title: 'Planche',
                  level: 'Planche lean',
                  progress: 0.25,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'PR & Milestone',
            child: _MetricGridCard(
              items: [
                _MetricItemData(label: 'Max pull-up', value: '14 tekrar'),
                _MetricItemData(label: 'L-sit', value: '28 sn'),
                _MetricItemData(label: 'Handstand', value: '12 sn'),
                _MetricItemData(label: 'Muscle-up', value: '2 tekrar'),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Rutin Planlayici',
            child: _ScheduleCard(
              items: [
                _ScheduleItemData(day: 'Pzt', focus: 'Push + Skill'),
                _ScheduleItemData(day: 'Car', focus: 'Pull + Core'),
                _ScheduleItemData(day: 'Cum', focus: 'Legs + Mobilite'),
                _ScheduleItemData(day: 'Cmt', focus: 'Full Body'),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Esneklik & Mobilite',
            child: _SimpleListCard(
              items: [
                _ListItemData(
                  title: 'Omuz',
                  subtitle: 'Gunde 10 dk mobilite',
                  trailing: '70%',
                ),
                _ListItemData(
                  title: 'Kalca',
                  subtitle: 'Dinamik esneme',
                  trailing: '55%',
                ),
                _ListItemData(
                  title: 'Hamstring',
                  subtitle: 'Statik esneme',
                  trailing: '60%',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Olcumler',
            child: _MetricGridCard(
              items: [
                _MetricItemData(label: 'Kilo', value: '72.4 kg'),
                _MetricItemData(label: 'Bel', value: '78 cm'),
                _MetricItemData(label: 'Kalca', value: '94 cm'),
                _MetricItemData(label: 'Trend', value: '+0.4 kg'),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Antrenman Gunlugu',
            child: _SimpleListCard(
              items: [
                _ListItemData(
                  title: 'Push Day',
                  subtitle: '5 hareket, 18 set',
                  trailing: '48 dk',
                ),
                _ListItemData(
                  title: 'Pull Day',
                  subtitle: '6 hareket, 20 set',
                  trailing: '52 dk',
                ),
                _ListItemData(
                  title: 'Legs + Core',
                  subtitle: '4 hareket, 16 set',
                  trailing: '40 dk',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Haftalik Hacim',
            child: _MiniBarChart(
              title: 'Haftalik Hacim',
              bars: [
                _BarData(label: 'H1', value: 0.55),
                _BarData(label: 'H2', value: 0.75),
                _BarData(label: 'H3', value: 0.65),
                _BarData(label: 'H4', value: 0.9),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Rozetler',
            child: _BadgeRowCard(
              items: [
                _BadgeItemData(label: '7 gun streak', icon: Icons.whatshot),
                _BadgeItemData(label: '30 gun devam', icon: Icons.emoji_events),
                _BadgeItemData(label: 'Yeni skill', icon: Icons.star),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Progress Fotograflari',
            child: _PhotoRowCard(
              items: [
                _PhotoItemData(label: 'Ocak'),
                _PhotoItemData(label: 'Subat'),
                _PhotoItemData(label: 'Mart'),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          _SectionCard(
            title: 'Profil Notlari',
            child: _NotesCard(
              notes:
                  'Omuz mobilitesi gelisiyor. Hedef: 30 sn handstand. Haftaya baslangic tekrarini 1 arttir.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.level,
    required this.tagline,
    required this.weight,
    required this.height,
    required this.age,
  });

  final String name;
  final String level;
  final String tagline;
  final String weight;
  final String height;
  final String age;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundColor: colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.person, color: colorScheme.primary, size: 30.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$level • $tagline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    _StatPill(label: 'Kilo', value: weight),
                    const SizedBox(width: 8.0),
                    _StatPill(label: 'Boy', value: height),
                    const SizedBox(width: 8.0),
                    _StatPill(label: 'Yas', value: age),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        collapsedBackgroundColor: colorScheme.surfaceContainerLow,
        children: [child],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.level,
    required this.goal,
    required this.frequency,
  });

  final String level;
  final String goal;
  final String frequency;

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(Icons.badge, color: colorScheme.primary),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Hedef: $goal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Siklik: $frequency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItemData {
  const _ListItemData({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}

class _SimpleListCard extends StatelessWidget {
  const _SimpleListCard({required this.items});

  final List<_ListItemData> items;

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
            _SimpleListTile(data: items[i]),
            if (i < items.length - 1) const SizedBox(height: 12.0),
          ],
        ],
      ),
    );
  }
}

class _SimpleListTile extends StatelessWidget {
  const _SimpleListTile({required this.data});

  final _ListItemData data;

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

class _ProgressItemData {
  const _ProgressItemData({
    required this.title,
    required this.level,
    required this.progress,
  });

  final String title;
  final String level;
  final double progress;
}

class _ProgressListCard extends StatelessWidget {
  const _ProgressListCard({required this.items});

  final List<_ProgressItemData> items;

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
            _ProgressRow(data: items[i]),
            if (i < items.length - 1) const SizedBox(height: 12.0),
          ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.data});

  final _ProgressItemData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              data.level,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(999.0),
          child: LinearProgressIndicator(
            value: data.progress,
            minHeight: 8.0,
            backgroundColor: colorScheme.surfaceContainerHighest,
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

class _ScheduleItemData {
  const _ScheduleItemData({required this.day, required this.focus});

  final String day;
  final String focus;
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.items});

  final List<_ScheduleItemData> items;

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
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Text(
                        item.day,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        item.focus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BadgeItemData {
  const _BadgeItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _BadgeRowCard extends StatelessWidget {
  const _BadgeRowCard({required this.items});

  final List<_BadgeItemData> items;

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
              (item) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(999.0),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 18.0, color: colorScheme.primary),
                    const SizedBox(width: 8.0),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PhotoItemData {
  const _PhotoItemData({required this.label});

  final String label;
}

class _PhotoRowCard extends StatelessWidget {
  const _PhotoRowCard({required this.items});

  final List<_PhotoItemData> items;

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
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Container(
                    height: 90.0,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

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
      child: Text(
        notes,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
