import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(authProvider).user;

    // Только администратор видит этот экран
    if (currentUser?.isAdmin != true) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Только для администраторов',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Scaffold(
      // Кнопка добавить пользователя
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Добавить',
            style: TextStyle(color: Colors.white)),
      ),
      body: usersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Заголовок с количеством
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Пользователей: ${users.length}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13),
              ),
            ),
            ...users.map((u) => _UserCard(
                  user: u,
                  currentUser: currentUser!,
                )),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final usernameCtrl = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'viewer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новый пользователь'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                // Выбор роли
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Роль:',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                _RoleSelector(
                  selected: selectedRole,
                  onChanged: (r) =>
                      setState(() => selectedRole = r),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameCtrl.text.isEmpty ||
                    passwordCtrl.text.isEmpty) return;
                await ref
                    .read(mockServiceProvider)
                    .createUser(
                      usernameCtrl.text,
                      emailCtrl.text,
                      passwordCtrl.text,
                      selectedRole,
                    );
                ref.refresh(usersProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пользователь создан'),
                      backgroundColor: AppColors.normal,
                    ),
                  );
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Карточка пользователя ─────────────────────────────────────────────
class _UserCard extends ConsumerWidget {
  final User user;
  final User currentUser;
  const _UserCard({required this.user, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = user.id == currentUser.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Аватар с первой буквой
            CircleAvatar(
              radius: 24,
              backgroundColor: _roleColor(user.role).withOpacity(0.15),
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _roleColor(user.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('вы',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Выбор роли (только если не текущий пользователь)
            if (!isMe)
              _RoleDropdown(user: user)
            else
              _RolePill(role: user.role),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':  return AppColors.primary;
      case 'editor': return AppColors.warning;
      default:       return Colors.grey;
    }
  }
}

// ── Дропдаун смены роли ───────────────────────────────────────────────
class _RoleDropdown extends ConsumerStatefulWidget {
  final User user;
  const _RoleDropdown({required this.user});

  @override
  ConsumerState<_RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends ConsumerState<_RoleDropdown> {
  late String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _role,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: 'admin',
          child: Text('Администратор',
              style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem(
          value: 'editor',
          child: Text('Редактор',
              style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem(
          value: 'viewer',
          child: Text('Наблюдатель',
              style: TextStyle(fontSize: 13)),
        ),
      ],
      onChanged: (newRole) async {
        if (newRole == null) return;
        setState(() => _role = newRole);
        await ref
            .read(mockServiceProvider)
            .updateUserRole(widget.user.id, newRole);
        ref.refresh(usersProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Роль ${widget.user.username} изменена'),
              backgroundColor: AppColors.normal,
            ),
          );
        }
      },
    );
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────
class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;
  const _RoleSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleOption(
          label: 'Наблюдатель',
          value: 'viewer',
          selected: selected,
          color: Colors.grey,
          onTap: () => onChanged('viewer'),
        ),
        const SizedBox(width: 8),
        _RoleOption(
          label: 'Редактор',
          value: 'editor',
          selected: selected,
          color: AppColors.warning,
          onTap: () => onChanged('editor'),
        ),
        const SizedBox(width: 8),
        _RoleOption(
          label: 'Админ',
          value: 'admin',
          selected: selected,
          color: AppColors.primary,
          onTap: () => onChanged('admin'),
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final VoidCallback onTap;
  const _RoleOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}