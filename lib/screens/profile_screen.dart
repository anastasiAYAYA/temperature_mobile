import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    // Цвет роли
    final roleColor = switch (user.role) {
      'superadmin' => const Color(0xFF7B1FA2),
      'admin'      => AppColors.primary,
      _            => Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Личный кабинет')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Аватар и имя
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: roleColor.withOpacity(0.15),
                    child: Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      user.roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Информация
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Телефон',
                  value: user.phone ?? 'Не указан',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.access_time,
                  label: 'Последний вход',
                  value: user.lastLogin != null
                      ? _formatDate(user.lastLogin!)
                      : 'Неизвестно',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Доступных объектов',
                  value: user.isSuperAdmin
                      ? 'Все объекты'
                      : '${user.allowedLocationIds.length} объектов',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Права доступа
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Права доступа',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PermissionRow(
                    label: 'Просмотр данных датчиков',
                    allowed: user.canViewSensors,
                  ),
                  _PermissionRow(
                    label: 'Просмотр журнала аудита',
                    allowed: user.canViewAuditLog,
                  ),
                  _PermissionRow(
                    label: 'Настройка уведомлений',
                    allowed: user.canConfigureNotifications,
                  ),
                  _PermissionRow(
                    label: 'Изменение порогов датчиков',
                    allowed: user.canEditSensorThresholds,
                  ),
                  _PermissionRow(
                    label: 'Управление объектами',
                    allowed: user.canManageLocations,
                  ),
                  _PermissionRow(
                    label: 'Управление пользователями',
                    allowed: user.canManageUsers,
                  ),
                  _PermissionRow(
                    label: 'Системные настройки',
                    allowed: user.canManageSystem,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Смена пароля
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline,
                  color: AppColors.primary),
              title: const Text('Сменить пароль'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final repCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Смена пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Текущий пароль'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Новый пароль'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Повторите пароль'),
            ),
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
                  content: Text('Пароль изменён'),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 14, color: Colors.black87)),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool allowed;
  const _PermissionRow({required this.label, required this.allowed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: allowed ? AppColors.normal : Colors.grey.shade300,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: allowed ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}