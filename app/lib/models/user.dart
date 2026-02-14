/// User model from the API
class User {
  final String id;
  final String email;
  final bool emailVerified;
  final String? phone;
  final bool phoneVerified;
  final String firstName;
  final int age;
  final String? city;
  final String? state;
  final String country;
  final String purposeStatement;
  final bool meetingPreference;
  final String? avatarIcon;
  final String subscriptionTier;
  final String status;
  final UserVerification? verification;
  final List<UserInterest> interests;

  User({
    required this.id,
    required this.email,
    this.emailVerified = false,
    this.phone,
    this.phoneVerified = false,
    required this.firstName,
    this.age = 0,
    this.city,
    this.state,
    this.country = 'AU',
    this.purposeStatement = '',
    this.meetingPreference = false,
    this.avatarIcon,
    this.subscriptionTier = 'FREE',
    required this.status,
    this.verification,
    this.interests = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      emailVerified: json['emailVerified'] ?? false,
      phone: json['phone'],
      phoneVerified: json['phoneVerified'] ?? false,
      firstName: json['firstName'],
      age: json['age'] ?? 0,
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'AU',
      purposeStatement: json['purposeStatement'] ?? '',
      meetingPreference: json['meetingPreference'] ?? false,
      avatarIcon: json['avatarIcon'],
      subscriptionTier: json['subscriptionTier'] ?? 'FREE',
      status: json['status'],
      verification: json['verification'] != null
          ? UserVerification.fromJson(json['verification'])
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => UserInterest.fromJson(i))
              .toList() ??
          [],
    );
  }

  bool get isProfileComplete =>
      purposeStatement.isNotEmpty && city != null && interests.isNotEmpty;

  bool get isVerified => status == 'ACTIVE';
  bool get isPending => status == 'PENDING_VERIFICATION';
}

class UserVerification {
  final bool email;
  final bool phone;
  final bool governmentId;
  final bool backgroundCheck;

  UserVerification({
    this.email = false,
    this.phone = false,
    this.governmentId = false,
    this.backgroundCheck = false,
  });

  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      email: json['email'] ?? false,
      phone: json['phone'] ?? false,
      governmentId: json['governmentId'] ?? false,
      backgroundCheck: json['backgroundCheck'] ?? false,
    );
  }
}

class UserInterest {
  final String id;
  final String name;
  final String category;
  final String? categoryIcon;

  UserInterest({
    required this.id,
    required this.name,
    required this.category,
    this.categoryIcon,
  });

  factory UserInterest.fromJson(Map<String, dynamic> json) {
    return UserInterest(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? '',
      categoryIcon: json['categoryIcon'],
    );
  }
}
