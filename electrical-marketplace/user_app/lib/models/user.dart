class User {
  final String id;
  final String? name;
  final String phone;
  final String? email;
  final bool isActive;
  final String createdAt;

  const User({
    required this.id,
    this.name,
    required this.phone,
    this.email,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString(),
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
        isActive: json['is_active'] == true,
        createdAt: json['created_at']?.toString() ?? '',
      );

  User copyWith({String? name, String? email}) => User(
        id: id,
        name: name ?? this.name,
        phone: phone,
        email: email ?? this.email,
        isActive: isActive,
        createdAt: createdAt,
      );
}
