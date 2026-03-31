import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/sensor_model.dart';
import 'users_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── РАЗДЕЛ: Уведомления — доступен ВСЕМ ────────────────────────
        _SectionHeader(title: 'Уведомления'),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.telegram,
                iconColor: const Color(0xFF2AABEE),
                title: 'Telegram',
                subtitle: 'Получать тревоги в Telegram',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.primary,
                title: 'Email уведомления',
                subtitle: 'Получать тревоги на почту',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                iconColor: AppColors.warning,
                title: 'Push-уведомления',
                subtitle: 'Уведомления на телефон',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── РАЗДЕЛ: Журнал аудита — доступен ВСЕМ (только чтение) ──────
        _SectionHeader(title: 'Журнал'),
        Card(
          child: _SettingsTile(
            icon: Icons.history,
            iconColor: Colors.grey,
            title: 'Журнал изменений',
            subtitle: 'Кто и когда вносил изменения',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAuditLog(context, user.canManageSystem),
          ),
        ),
        const SizedBox(height: 20),

        // ── РАЗДЕЛ: Управление — только для АДМИНА и СУПЕРАДМИНА ────────
        if (user.canManageLocations) ...[
          _SectionHeader(title: 'Управление (Администратор)'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.sensors,
                  iconColor: AppColors.primary,
                  title: 'Пороги тревог датчиков',
                  subtitle: 'Изменить границы срабатывания',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSensorThresholds(context, ref),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.business_outlined,
                  iconColor: AppColors.primary,
                  title: 'Управление объектами',
                  subtitle: 'Добавить или изменить объекты',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLocationsManager(context),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.people_outline,
                  iconColor: AppColors.primary,
                  title: 'Пользователи',
                  subtitle: 'Управление доступом сотрудников',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UsersScreen()),
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.warning,
                  title: 'Задержки уведомлений',
                  subtitle: 'Настройка задержки перед тревогой',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDelaysSettings(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── РАЗДЕЛ: Система — только для СУПЕРАДМИНА ────────────────────
        if (user.canManageSystem) ...[
          _SectionHeader(title: 'Система (Суперадмин)'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.security,
                  iconColor: const Color(0xFF7B1FA2),
                  title: 'Безопасность',
                  subtitle: 'HTTPS, шифрование, сессии',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.backup_outlined,
                  iconColor: const Color(0xFF7B1FA2),
                  title: 'Резервное копирование',
                  subtitle: 'Экспорт данных за 2+ года',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.system_update_outlined,
                  iconColor: const Color(0xFF7B1FA2),
                  title: 'Обновление системы',
                  subtitle: 'Версия 1.0.0',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Профиль и выход — доступны ВСЕМ ────────────────────────────
        _SectionHeader(title: 'Аккаунт'),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                iconColor: AppColors.primary,
                title: 'Личный кабинет',
                subtitle: user.email,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/profile'),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.logout,
                iconColor: AppColors.alarm,
                title: 'Выйти из системы',
                subtitle: '',
                trailing: const SizedBox.shrink(),
                onTap: () => ref.read(authProvider.notifier).logout(),
                titleColor: AppColors.alarm,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'temperature.kz v1.0.0 • ${user.roleLabel}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ── Журнал аудита ──────────────────────────────────────────────────────
  void _showAuditLog(BuildContext context, bool canExport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Журнал изменений',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (canExport)
                    TextButton.icon(
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Экспорт'),
                      onPressed: () {},
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: const [
                  _AuditItem(
                    user: 'admin',
                    action: 'Изменил порог тревоги датчика "Зона C"',
                    detail: 'tempAlarmHigh: -12 → -10°C',
                    time: '2 часа назад',
                    icon: Icons.tune,
                    color: AppColors.warning,
                  ),
                  _AuditItem(
                    user: 'superadmin',
                    action: 'Добавил пользователя "ivanov"',
                    detail: 'Роль: Сотрудник',
                    time: '5 часов назад',
                    icon: Icons.person_add,
                    color: AppColors.primary,
                  ),
                  _AuditItem(
                    user: 'admin',
                    action: 'Закрыл тревогу #3',
                    detail: 'Комментарий: выехал техник',
                    time: '2 дня назад',
                    icon: Icons.check_circle,
                    color: AppColors.normal,
                  ),
                  _AuditItem(
                    user: 'superadmin',
                    action: 'Добавил объект "Ресторан Astana"',
                    detail: 'Адрес: ул. Сейфуллина 8',
                    time: '5 дней назад',
                    icon: Icons.business,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Пороги датчиков ────────────────────────────────────────────────────
  void _showSensorThresholds(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SensorThresholdsScreen(),
      ),
    );
  }

  // ── Управление объектами ───────────────────────────────────────────────
  void _showLocationsManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Управление объектами'),
        content: const Text(
            'Здесь будет список объектов с возможностью добавить новый.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // ── Задержки уведомлений ───────────────────────────────────────────────
  void _showDelaysSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Задержки уведомлений'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Задержка нужна чтобы не получать лишних тревог при загрузке/разгрузке камер',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _DelayRow(label: 'Задержка тревоги', minutes: 5),
            _DelayRow(label: 'Задержка внимания', minutes: 10),
            _DelayRow(label: 'Задержка потери связи', minutes: 15),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Задержки сохранены'),
                  backgroundColor: AppColors.normal,
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

// ── Экран порогов датчиков ─────────────────────────────────────────────
class _SensorThresholdsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Пороги тревог')),
      body: locationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (locations) {
          final sensors = locations.expand((l) => l.sensors).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sensors.length,
            itemBuilder: (_, i) => _SensorThresholdCard(sensor: sensors[i]),
          );
        },
      ),
    );
  }
}

class _SensorThresholdCard extends StatelessWidget {
  final Sensor sensor;
  const _SensorThresholdCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: _statusColor(sensor.status),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(sensor.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: sensor.tempAlarmHigh != null
            ? Text(
                'Тревога: ${sensor.tempAlarmLow ?? "—"}°C … ${sensor.tempAlarmHigh}°C\n'
                'Внимание: ${sensor.tempWarningLow ?? "—"}°C … ${sensor.tempWarningHigh ?? "—"}°C',
                style: const TextStyle(fontSize: 12),
              )
            : const Text('Пороги не заданы',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.tune, color: AppColors.primary),
        onTap: () => _showEditDialog(context, sensor),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'alarm':   return AppColors.alarm;
      case 'warning': return AppColors.warning;
      case 'offline': return AppColors.offline;
      default:        return AppColors.normal;
    }
  }

  void _showEditDialog(BuildContext context, Sensor sensor) {
    final alarmHighCtrl = TextEditingController(
        text: sensor.tempAlarmHigh?.toString() ?? '');
    final alarmLowCtrl = TextEditingController(
        text: sensor.tempAlarmLow?.toString() ?? '');
    final warnHighCtrl = TextEditingController(
        text: sensor.tempWarningHigh?.toString() ?? '');
    final warnLowCtrl = TextEditingController(
        text: sensor.tempWarningLow?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(sensor.name,
            style: const TextStyle(fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Температура °C',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _ThresholdField(
                    controller: alarmLowCtrl,
                    label: 'Тревога нижняя',
                    color: AppColors.alarm)),
                const SizedBox(width: 12),
                Expanded(child: _ThresholdField(
                    controller: alarmHighCtrl,
                    label: 'Тревога верхняя',
                    color: AppColors.alarm)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _ThresholdField(
                    controller: warnLowCtrl,
                    label: 'Внимание нижняя',
                    color: AppColors.warning)),
                const SizedBox(width: 12),
                Expanded(child: _ThresholdField(
                    controller: warnHighCtrl,
                    label: 'Внимание верхняя',
                    color: AppColors.warning)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Пороги сохранены'),
                  backgroundColor: AppColors.normal,
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

// ── Вспомогательные виджеты ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.enabled = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: titleColor)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _AuditItem extends StatelessWidget {
  final String user;
  final String action;
  final String detail;
  final String time;
  final IconData icon;
  final Color color;

  const _AuditItem({
    required this.user,
    required this.action,
    required this.detail,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
                Text(action,
                    style: const TextStyle(fontSize: 13)),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayRow extends StatefulWidget {
  final String label;
  final int minutes;
  const _DelayRow({required this.label, required this.minutes});

  @override
  State<_DelayRow> createState() => _DelayRowState();
}

class _DelayRowState extends State<_DelayRow> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label,
                style: const TextStyle(fontSize: 13)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 20,
                onPressed: _minutes > 1
                    ? () => setState(() => _minutes--)
                    : null,
              ),
              Text('$_minutes мин',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 20,
                onPressed: () => setState(() => _minutes++),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThresholdField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const _ThresholdField({
    required this.controller,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
          decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: color),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
      ),
    );
  }
}