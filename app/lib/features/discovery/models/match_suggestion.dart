class MatchSuggestion {
  final String id;
  final String firstName;
  final String? city;
  final String? state;
  final String? purposeStatement;
  final bool meetingPreference;
  final String? avatarIcon;
  final double score;
  final List<SharedInterest> sharedInterests;
  final int sharedCount;
  final int totalInterests;
  final ScoreBreakdown breakdown;

  const MatchSuggestion({
    required this.id,
    required this.firstName,
    this.city,
    this.state,
    this.purposeStatement,
    this.meetingPreference = false,
    this.avatarIcon,
    required this.score,
    required this.sharedInterests,
    required this.sharedCount,
    required this.totalInterests,
    required this.breakdown,
  });

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) {
    return MatchSuggestion(
      id: json['id'],
      firstName: json['firstName'],
      city: json['city'],
      state: json['state'],
      purposeStatement: json['purposeStatement'],
      meetingPreference: json['meetingPreference'] ?? false,
      avatarIcon: json['avatarIcon'],
      score: (json['score'] as num).toDouble(),
      sharedInterests: (json['sharedInterests'] as List? ?? [])
          .map((e) => SharedInterest.fromJson(e))
          .toList(),
      sharedCount: json['sharedCount'] ?? 0,
      totalInterests: json['totalInterests'] ?? 0,
      breakdown: ScoreBreakdown.fromJson(json['breakdown'] ?? {}),
    );
  }

  int get scorePercent => (score * 100).round();
}

class SharedInterest {
  final String name;
  final String category;
  final String? categoryIcon;

  const SharedInterest({
    required this.name,
    required this.category,
    this.categoryIcon,
  });

  factory SharedInterest.fromJson(Map<String, dynamic> json) {
    return SharedInterest(
      name: json['name'],
      category: json['category'],
      categoryIcon: json['categoryIcon'],
    );
  }
}

class ScoreBreakdown {
  final int interest;
  final int proximity;
  final int activity;

  const ScoreBreakdown({
    required this.interest,
    required this.proximity,
    required this.activity,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      interest: json['interest'] ?? 0,
      proximity: json['proximity'] ?? 0,
      activity: json['activity'] ?? 0,
    );
  }
}

class MatchSuggestionsResponse {
  final List<MatchSuggestion> matches;
  final int total;

  const MatchSuggestionsResponse({required this.matches, required this.total});

  factory MatchSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return MatchSuggestionsResponse(
      matches: (json['matches'] as List? ?? [])
          .map((e) => MatchSuggestion.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}
