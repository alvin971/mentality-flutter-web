import 'package:equatable/equatable.dart';

/// Claims démographiques décodés depuis un token Mental E.T.
class TokenClaims extends Equatable {
  final String sex; // 'M' | 'F' | 'X'
  final String ageBucket; // '18-25' | '26-35' | ...
  final String countryCode; // 'FR', 'US', ...
  final DateTime createdAt;

  const TokenClaims({
    required this.sex,
    required this.ageBucket,
    required this.countryCode,
    required this.createdAt,
  });

  factory TokenClaims.fromJson(Map<String, dynamic> json) => TokenClaims(
        sex: json['sex'] as String,
        ageBucket: json['ageBucket'] as String,
        countryCode: json['countryCode'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [sex, ageBucket, countryCode, createdAt];
}
