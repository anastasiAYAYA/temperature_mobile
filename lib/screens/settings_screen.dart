import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/sensor_model.dart';
import 'users_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Профиль пользователя
        _SectionHeader(title: 'Профиль'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.username.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _RoleBadge(role: user?.role ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Датчики и пороги
        _SectionHeader(title: 'Датчики и пороги тревог'),
        _SensorsSettingsList(),
        const SizedBox(height: 20),

        // Уведомления
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
                title: 'Email',
                subtitle: 'Получать тревоги на почту',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Система
        _SectionHeader(title: 'Система'),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.business_outlined,
                iconColor: AppColors.primary,
                title: 'Управление локациями',
                subtitle: 'Добавить или изменить объекты',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.people_outline,
                iconColor: AppColors.primary,
                title: 'Пользователи',
                subtitle: 'Управление доступом',
                trailing: const Icon(Icons.chevron_right),
                onTap: user?.isAdmin == true
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UsersScreen(),
                    ),
                    )
                : null,
                enabled: user?.isAdmin == true,
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.history,
                iconColor: Colors.grey,
                title: 'Журнал изменений',
                subtitle: 'Кто и когда менял настройки',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Выход
        Card(
          child: _SettingsTile(
            icon: Icons.logout,
            iconColor: AppColors.alarm,
            title: 'Выйти из системы',
            subtitle: '',
            trailing: const SizedBox.shrink(),
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
            titleColor: AppColors.alarm,
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'temperature.kz v1.0.0',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ── Список датчиков с настройкой порогов ──────────────────────────────
class _SensorsSettingsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    return locationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (locations) {
        final sensors =
            locations.expand((l) => l.sensors).toList();
        return Card(
          child: Column(
            children: sensors.asMap().entries.map((entry) {
              final i = entry.key;
              final sensor = entry.value;
              return Column(
                children: [
                  _SensorThresholdTile(sensor: sensor),
                  if (i < sensors.length - 1)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Строка датчика с порогами ─────────────────────────────────────────
class _SensorThresholdTile extends ConsumerWidget {
  final Sensor sensor;
  const _SensorThresholdTile({required this.sensor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: _statusColor(sensor.status),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        sensor.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: sensor.tempAlarmHigh != null
          ? Text(
              'Тревога: ${sensor.tempAlarmLow ?? '—'}°C … ${sensor.tempAlarmHigh}°C',
              style: const TextStyle(fontSize: 12),
            )
          : const Text(
              'Пороги не заданы',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
      trailing: const Icon(Icons.tune, color: AppColors.primary),
      onTap: () => _showThresholdDialog(context, ref, sensor),
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

  void _showThresholdDialog(
      BuildContext context, WidgetRef ref, Sensor sensor) {
    // Контроллеры для полей ввода порогов
    final alarmHighCtrl = TextEditingController(
      text: sensor.tempAlarmHigh?.toString() ?? '',
    );
    final alarmLowCtrl = TextEditingController(
      text: sensor.tempAlarmLow?.toString() ?? '',
    );
    final warnHighCtrl = TextEditingController(
      text: sensor.tempWarningHigh?.toString() ?? '',
    );
    final warnLowCtrl = TextEditingController(
      text: sensor.tempWarningLow?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          sensor.name,
          style: const TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Пороги температуры (°C)',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ThresholdField(
                      controller: alarmLowCtrl,
                      label: 'Тревога нижняя',
                      color: AppColors.alarm,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThresholdField(
                      controller: alarmHighCtrl,
                      label: 'Тревога верхняя',
                      color: AppColors.alarm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ThresholdField(
                      controller: warnLowCtrl,
                      label: 'Внимание нижняя',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThresholdField(
                      controller: warnHighCtrl,
                      label: 'Внимание верхняя',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
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
              // Здесь будет вызов API для сохранения
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

// ── Вспомогательные виджеты ───────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'admin'  => 'Администратор',
      'editor' => 'Редактор',
      _        => 'Наблюдатель',
    };
    final color = switch (role) {
      'admin'  => AppColors.primary,
      'editor' => AppColors.warning,
      _        => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
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
        decimal: true, signed: true,
      ),
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
          horizontal: 10, vertical: 10,
        ),
      ),
    );
  }
}