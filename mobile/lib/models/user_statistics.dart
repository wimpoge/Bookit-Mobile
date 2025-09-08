import 'dart:convert';

class UserStatistics {
  final int totalBookings;
  final int countriesVisited;
  final int totalReviews;
  final List<String> countriesList;

  UserStatistics({
    required this.totalBookings,
    required this.countriesVisited,
    required this.totalReviews,
    required this.countriesList,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalBookings: json['total_bookings'] ?? 0,
      countriesVisited: json['countries_visited'] ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
      countriesList: List<String>.from(json['countries_list'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_bookings': totalBookings,
      'countries_visited': countriesVisited,
      'total_reviews': totalReviews,
      'countries_list': countriesList,
    };
  }

  String toJson() => jsonEncode(toMap());

  UserStatistics copyWith({
    int? totalBookings,
    int? countriesVisited,
    int? totalReviews,
    List<String>? countriesList,
  }) {
    return UserStatistics(
      totalBookings: totalBookings ?? this.totalBookings,
      countriesVisited: countriesVisited ?? this.countriesVisited,
      totalReviews: totalReviews ?? this.totalReviews,
      countriesList: countriesList ?? this.countriesList,
    );
  }
}