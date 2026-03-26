class UserModel {
  final int id;
  final String email;
  final String username;
  final String role;
  final String? phone;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: (json['email'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      role: (json['role'] ?? 'user') as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'phone': phone,
    };
  }

  bool get isAdmin => role == 'admin';
}

