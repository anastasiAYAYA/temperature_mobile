import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/location_model.dart';
import '../models/sensor_model.dart';
 
// DashboardShell — это "рамка" с AppBar и нижней навигацией
// Внутри неё меняются вкладки (child)
class DashboardShell extends ConsumerWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});
 
  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/alarms'))   return 1;
    if (location.startsWith('/charts'))   return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(authProvider).user;
    final alarmStats = ref.watch(alarmStatsProvider);
    final activeCount = alarmStats.maybeWhen(
      data: (s) => s['active'] ?? 0,
      orElse: () => 0,
    );
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('temperature.kz'),
        actions: [
          // Иконка тревог с бейджем
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/alarms'),
              ),
              if (activeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.alarm,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Меню пользователя
          PopupMenuButton(
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (_) => <PopupMenuEntry>[
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      user?.roleLabel ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  Icon(Icons.person_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Личный кабинет'),
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Выйти'),
                ]),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              } else if (value == 'profile') {
                context.go('/profile');
              }
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _locationIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/alarms');    break;
            case 2: context.go('/charts');    break;
            case 3: context.go('/settings');  break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Мониторинг',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              child: const Icon(Icons.warning_amber_outlined),
            ),
            selectedIcon: const Icon(Icons.warning_amber),
            label: 'Тревоги',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Графики',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
 
// ── Вкладка мониторинга ────────────────────────────────────────────────
class MonitoringTab extends ConsumerWidget {
  const MonitoringTab({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
 
    return locationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.refresh(locationsProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (locations) => _MonitoringList(locations: locations),
    );
  }
}
 
class _MonitoringList extends StatelessWidget {
  final List<Location> locations;
  const _MonitoringList({required this.locations});
 
  @override
  Widget build(BuildContext context) {
    final allSensors   = locations.expand((l) => l.sensors).toList();
    final normalCount  = allSensors.where((s) => s.isNormal).length;
    final warningCount = allSensors.where((s) => s.isWarning).length;
    final alarmCount   = allSensors.where((s) => s.isAlarm).length;
    final offlineCount = allSensors.where((s) => !s.isOnline).length;
 
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Сводка статусов вверху
          Row(
            children: [
              _StatChip(label: 'Норма',    count: normalCount,  color: AppColors.normal),
              const SizedBox(width: 8),
              _StatChip(label: 'Внимание', count: warningCount, color: AppColors.warning),
              const SizedBox(width: 8),
              _StatChip(label: 'Тревога',  count: alarmCount,   color: AppColors.alarm),
              const SizedBox(width: 8),
              _StatChip(label: 'Нет связи',count: offlineCount, color: AppColors.offline),
            ],
          ),
          const SizedBox(height: 16),
 
          // Список локаций
          ...locations.map((loc) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LocationCard(location: loc),
          )),
        ],
      ),
    );
  }
}
 
// ── Карточка локации со статусом блока управления ─────────────────────
class _LocationCard extends StatefulWidget {
  final Location location;
  const _LocationCard({required this.location});
 
  @override
  State<_LocationCard> createState() => _LocationCardState();
}
 
class _LocationCardState extends State<_LocationCard> {
  bool _expanded = true;
 
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Строка с названием объекта
                  Row(
                    children: [
                      const Icon(Icons.business, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.location.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (widget.location.address != null)
                              Text(
                                widget.location.address!,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (widget.location.alarmCount > 0)
                        _MiniChip(
                            count: widget.location.alarmCount,
                            color: AppColors.alarm),
                      if (widget.location.warningCount > 0)
                        _MiniChip(
                            count: widget.location.warningCount,
                            color: AppColors.warning),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
 
                  // ── Статус блока управления ──────────────────────────
                  // По ТЗ: отображение питания, GSM, баланса SIM-карты
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Питание 220В
                        _BlockStatusItem(
                          icon: widget.location.hasPower
                              ? Icons.power
                              : Icons.power_off,
                          color: widget.location.hasPower
                              ? AppColors.normal
                              : AppColors.alarm,
                          label: widget.location.hasPower
                              ? 'Сеть 220В'
                              : 'Нет питания',
                        ),
                        const SizedBox(width: 16),
 
                        // Уровень GSM сигнала
                        _GsmIndicator(
                            level: widget.location.gsmLevel ?? 0),
                        const SizedBox(width: 16),
 
                        // Баланс SIM-карты
                        _BlockStatusItem(
                          icon: Icons.sim_card_outlined,
                          color: (widget.location.simBalance ?? 0) > 100
                              ? AppColors.normal
                              : AppColors.warning,
                          label: widget.location.simBalance != null
                              ? '${widget.location.simBalance!.toStringAsFixed(0)} ₸'
                              : 'SIM —',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
 
          // Список датчиков
          if (_expanded)
            ...widget.location.sensors.map((s) => _SensorRow(sensor: s)),
        ],
      ),
    );
  }
}
 
// ── Элемент статуса блока управления ──────────────────────────────────
class _BlockStatusItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
 
  const _BlockStatusItem({
    required this.icon,
    required this.color,
    required this.label,
  });
 
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
 
// ── Индикатор уровня GSM (4 полоски как на телефоне) ──────────────────
class _GsmIndicator extends StatelessWidget {
  final int level; // 0-4
  const _GsmIndicator({required this.level});
 
  @override
  Widget build(BuildContext context) {
    final color = level == 0
        ? AppColors.alarm
        : level <= 1
            ? AppColors.warning
            : AppColors.normal;
 
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(4, (i) {
          final isActive = i < level;
          final height   = 6.0 + i * 3.0;
          return Container(
            width: 4,
            height: height,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: isActive ? color : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          level == 0 ? 'GSM нет' : 'GSM $level/4',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
 
// ── Строка датчика ─────────────────────────────────────────────────────
class _SensorRow extends StatelessWidget {
  final Sensor sensor;
  const _SensorRow({required this.sensor});
 
  Color get _statusColor {
    switch (sensor.status) {
      case 'alarm':   return AppColors.alarm;
      case 'warning': return AppColors.warning;
      case 'offline': return AppColors.offline;
      default:        return AppColors.normal;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Цветная точка статуса
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
 
          Expanded(
            child: Text(
              sensor.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
 
          if (!sensor.isOnline)
            const Text(
              'Нет связи',
              style: TextStyle(color: AppColors.offline, fontSize: 13),
            )
          else ...[
            // Температура
            Row(
              children: [
                const Icon(Icons.thermostat, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${sensor.temperature?.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
 
            // Влажность
            Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${sensor.humidity?.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
 
            // Заряд батареи (если есть)
            if (sensor.batteryLevel != null) ...[
              const SizedBox(width: 12),
              Icon(
                sensor.batteryLevel! > 20
                    ? Icons.battery_4_bar
                    : Icons.battery_alert,
                size: 16,
                color: sensor.batteryLevel! > 20
                    ? Colors.grey
                    : AppColors.alarm,
              ),
              Text(
                '${sensor.batteryLevel}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
 
// ── Вспомогательные виджеты ────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _MiniChip extends StatelessWidget {
  final int count;
  final Color color;
  const _MiniChip({required this.count, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}