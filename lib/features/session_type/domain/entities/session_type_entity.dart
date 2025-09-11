import 'package:equatable/equatable.dart';

class SessionTypeEntity extends Equatable {
  final String? id;
  final String title;
  final bool notifyCancelation;
  final int createdTime;
  final int duration;
  final String durationUnit;
  final String details;
  final String idCreatedBy;
  final int maxPlayers;
  final int minPlayers;
  final bool showParticipants;
  final String category;
  final int price;
  
  // Cancellation Policy Fields
  final bool hasCancellationFee;
  final int cancellationTimeBefore; // just the number (e.g., 18)
  final String cancellationTimeUnit; // 'hours' or 'minutes'
  final int cancellationFeeAmount; // fee amount
  final String cancellationFeeType; // '%' or '$'

  const SessionTypeEntity({
    this.id,
    required this.title,
    this.notifyCancelation = false,
    required this.createdTime,
    required this.duration,
    this.durationUnit = 'minutes',
    this.details = '',
    required this.idCreatedBy,
    required this.maxPlayers,
    this.minPlayers = 1,
    this.showParticipants = true,
    this.category = '',
    required this.price,
    
    // Cancellation Policy defaults
    this.hasCancellationFee = true,
    this.cancellationTimeBefore = 18,
    this.cancellationTimeUnit = 'hours',
    this.cancellationFeeAmount = 100,
    this.cancellationFeeType = '%',
  });

  /// Calculate the actual cancellation fee amount in dollars
  /// If cancellationFeeType is '%', multiplies by session price
  /// If cancellationFeeType is '$', returns the amount directly
  int getActualCancellationFee() {
    if (!hasCancellationFee) return 0;
    
    if (cancellationFeeType == '%') {
      return (cancellationFeeAmount * price / 100).round();
    } else {
      return cancellationFeeAmount;
    }
  }

  /// Get cancellation time in minutes for calculations
  int getCancellationTimeInMinutes() {
    if (cancellationTimeUnit == 'hours') {
      return cancellationTimeBefore * 60;
    } else {
      return cancellationTimeBefore;
    }
  }

  @override
  List<Object?> get props => [
    id,
    title,
    notifyCancelation,
    createdTime,
    duration,
    durationUnit,
    details,
    idCreatedBy,
    maxPlayers,
    minPlayers,
    showParticipants,
    category,
    price,
    hasCancellationFee,
    cancellationTimeBefore,
    cancellationTimeUnit,
    cancellationFeeAmount,
    cancellationFeeType,
  ];
}
