import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/alarm_model.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);

    return alarmsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (alarms) => _AlarmsList(alarms: alarms),
    );
  }
}

class _AlarmsList extends ConsumerStatefulWidget {
  final List<Alarm> alarms;
  const _AlarmsList({required this.alarms});

  @override
  ConsumerState<_AlarmsList> createState() => _AlarmsListState();
}

class _AlarmsListState extends ConsumerState<_AlarmsList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.alarms.where((a) => a.isActive).toList();
    final acknowledged =
        widget.alarms.where((a) => a.isAcknowledged).toList();
    final resolved = widget.alarms.where((a) => a.isResolved).toList();

    return Column(
      children: [
        // Вкладки: Активные / В работе / Закрытые
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Активные (${active.length})'),
            Tab(text: 'В работе (${acknowledged.length})'),
            Tab(text: 'Закрытые (${resolved.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AlarmsTabContent(alarms: active),
              _AlarmsTabContent(alarms: acknowledged),
              _AlarmsTabContent(alarms: resolved),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlarmsTabContent extends ConsumerWidget {
  final List<Alarm> alarms;
  const _AlarmsTabContent({required this.alarms});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alarms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.normal),
            SizedBox(height: 12),
            Text('Тревог нет',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alarms.length,
      itemBuilder: (_, i) => _AlarmCard(alarm: alarms[i]),
    );
  }
}

// ── Карточка тревоги ───────────────────────────────────────────────────
class _AlarmCard extends ConsumerWidget {
  final Alarm alarm;
  const _AlarmCard({required this.alarm});

  Color get _levelColor =>
      alarm.level == 'alarm' ? AppColors.alarm : AppColors.warning;

  IconData get _typeIcon {
    switch (alarm.type) {
      case 'temp_high':
        return Icons.thermostat;
      case 'temp_low':
        return Icons.ac_unit;
      case 'offline':
        return Icons.wifi_off;
      case 'no_power':
        return Icons.power_off;
      default:
        return Icons.warning_amber;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    return '${diff.inDays} дн. назад';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _levelColor.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок карточки
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, color: _levelColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _levelColor,
                        ),
                      ),
                      Text(
                        '${alarm.objectName} › ${alarm.sensorName}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Бейдж уровня
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _levelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alarm.level == 'alarm' ? 'ТРЕВОГА' : 'ВНИМАНИЕ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Значение и порог
            if (alarm.value != null && alarm.threshold != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                        label: 'Значение',
                        value:
                            '${alarm.value!.toStringAsFixed(1)}°C'),
                    const SizedBox(width: 24),
                    _InfoItem(
                        label: 'Порог',
                        value:
                            '${alarm.threshold!.toStringAsFixed(1)}°C'),
                    const Spacer(),
                    Text(
                      _timeAgo(alarm.triggeredAt),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Text(
                _timeAgo(alarm.triggeredAt),
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),

            // Комментарий если есть
            if (alarm.comment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined,
                        size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        alarm.comment!,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Кнопки действий
            if (alarm.isActive || alarm.isAcknowledged) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (alarm.isActive)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.engineering, size: 16),
                        label: const Text('Взять в работу'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(
                              color: AppColors.warning),
                        ),
                        onPressed: () =>
                            _acknowledge(context, ref, alarm.id),
                      ),
                    ),
                  if (alarm.isActive) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Закрыть'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.normal,
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () =>
                          _resolve(context, ref, alarm.id),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Взять в работу
  void _acknowledge(
      BuildContext context, WidgetRef ref, int id) async {
    await ref.read(mockServiceProvider).acknowledgeAlarm(id);
    ref.refresh(alarmsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тревога взята в работу')),
      );
    }
  }

  // Закрыть с комментарием
  void _resolve(BuildContext context, WidgetRef ref, int id) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Закрыть тревогу'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'Комментарий (что сделали)',
            hintText: 'Например: заменили уплотнитель двери',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(mockServiceProvider).resolveAlarm(
                    id,
                    commentController.text,
                  );
              ref.refresh(alarmsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Тревога закрыта')),
                );
              }
            },
            child: const Text('Закрыть тревогу'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}