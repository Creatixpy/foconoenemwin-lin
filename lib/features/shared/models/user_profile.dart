class UserProfile {
  const UserProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.goal,
    this.targetYear,
    this.communityTagline,
    this.communityProfileTheme,
    this.communityShowStatistics = true,
    this.communityTermsVersion,
    this.communityTermsAcceptedAt,
    this.communityAgeConfirmedAt,
    this.isOver16,
  });

  final String id;
  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? goal;
  final int? targetYear;
  final String? communityTagline;
  final String? communityProfileTheme;
  final bool communityShowStatistics;
  final String? communityTermsVersion;
  final DateTime? communityTermsAcceptedAt;
  final DateTime? communityAgeConfirmedAt;
  final bool? isOver16;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fullName: map['nome_completo'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      goal: map['objetivo'] as String?,
      targetYear: map['ano_enem'] as int?,
      communityTagline: map['community_tagline'] as String?,
      communityProfileTheme: map['community_profile_theme'] as String?,
      communityShowStatistics:
          (map['community_show_statistics'] as bool?) ?? true,
      communityTermsVersion: map['community_terms_version'] as String?,
      communityTermsAcceptedAt: map['community_terms_accepted_at'] != null
          ? DateTime.parse(map['community_terms_accepted_at'] as String)
          : null,
      communityAgeConfirmedAt: map['community_age_confirmed_at'] != null
          ? DateTime.parse(map['community_age_confirmed_at'] as String)
          : null,
      isOver16: map['is_over_16'] as bool?,
    );
  }
}
