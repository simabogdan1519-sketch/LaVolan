import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

part 'penalty_entry.g.dart';

@HiveType(typeId: 7)
class PenaltyEntry extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  int points;
  @HiveField(3)
  String? reason;
  @HiveField(4)
  double? fineAmount;
  @HiveField(5)
  String? location;

  PenaltyEntry({
    required this.id,
    required this.date,
    required this.points,
    this.reason,
    this.fineAmount,
    this.location,
  });

  /// Points expire after AppConstants.penaltyExpiryMonths months
  /// from the date of the violation.
  DateTime get expiresOn => DateTime(
        date.year,
        date.month + AppConstants.penaltyExpiryMonths,
        date.day,
      );

  bool get isActive => DateTime.now().isBefore(expiresOn);

  int get daysUntilExpiry => expiresOn.difference(DateTime.now()).inDays;
}
