/// Interest category with its tags
class InterestCategory {
  final String id;
  final String name;
  final String? icon;
  final List<Interest> interests;

  InterestCategory({
    required this.id,
    required this.name,
    this.icon,
    this.interests = const [],
  });

  factory InterestCategory.fromJson(Map<String, dynamic> json) {
    return InterestCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => Interest.fromJson(i))
              .toList() ??
          [],
    );
  }
}

/// Individual interest tag
class Interest {
  final String id;
  final String name;

  Interest({required this.id, required this.name});

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'],
      name: json['name'],
    );
  }
}
