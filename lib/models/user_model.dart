class User {
  final int id;
  final String username;
  final String email;
  final String role; // "admin", "editor", "viewer"

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'viewer',
    );
  }

  bool get isAdmin  => role == 'admin';
  bool get isEditor => role == 'editor' || role == 'admin';
}