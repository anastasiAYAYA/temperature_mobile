import 'package:flutter/material.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? phone;
  final DateTime? lastLogin;
  final List<int> allowedLocationIds;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
    this.lastLogin,
    this.allowedLocationIds = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:       json['id'],
      username: json['username'],
      email:    json['email'] ?? '',
      role:     json['role'] ?? 'employee',
      phone:    json['phone'],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      allowedLocationIds: json['allowed_location_ids'] != null
          ? List<int>.from(json['allowed_location_ids'])
          : [],
    );
  }

  // ── Базовые роли ──────────────────────────────────────────────────────
  bool get isSuperAdmin => role == 'superadmin';
  bool get isAdmin      => role == 'admin' || role == 'superadmin';
  bool get isEmployee   => role == 'employee';

  // ── Права по ТЗ ───────────────────────────────────────────────────────

  // ВСЕ РОЛИ:
  bool get canViewSensors           => true; // просмотр датчиков
  bool get canViewCharts            => true; // графики
  bool get canViewAlarms            => true; // просмотр тревог
  bool get canCommentAlarms         => true; // комментарии к тревогам
  bool get canConfigureNotifications=> true; // свои уведомления
  bool get canViewAuditLog          => true; // журнал аудита (только чтение)
  bool get canViewSettings          => true; // зайти в настройки

  // ТОЛЬКО АДМИН И СУПЕРАДМИН:
  bool get canEditSensorThresholds  => isAdmin; // менять пороги датчиков
  bool get canAddSensors            => isAdmin; // добавлять датчики
  bool get canManageLocations       => isAdmin; // добавлять объекты
  bool get canManageUsers           => isAdmin; // управлять пользователями

  // ТОЛЬКО СУПЕРАДМИН:
  bool get canDeleteUsers           => isSuperAdmin; // удалять пользователей
  bool get canDeleteSensors         => isSuperAdmin; // удалять датчики
  bool get canManageSystem          => isSuperAdmin; // системные настройки

  // ── UI хелперы ────────────────────────────────────────────────────────
  String get roleLabel {
    switch (role) {
      case 'superadmin': return 'Суперадмин';
      case 'admin':      return 'Администратор';
      default:           return 'Сотрудник';
    }
  }

  Color get roleColorValue {
    switch (role) {
      case 'superadmin': return const Color(0xFF7B1FA2);
      case 'admin':      return const Color(0xFF1565C0);
      default:           return const Color(0xFF616161);
    }
  }
}