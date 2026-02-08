import 'package:application/SourceDesign/Enums/AccountTypes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPageState {
  final bool hasActiveOrder;
  final bool isInPreparingState;
  final bool isReady;
  final bool hasLocationOn;
  final bool isInLoading;

  MainPageState({
    this.hasActiveOrder = false,
    this.isInPreparingState = false, 
    this.isReady = false,
    this.hasLocationOn = false,
    this.isInLoading = false
  });


  MainPageState copyWith({
    bool? hasActiveOrder,
    bool? isInPreparingState,
    bool? isReady,
    bool? hasLocationOn,
    bool? isInLoading,
  }) {
    return MainPageState(
      hasActiveOrder: hasActiveOrder ?? this.hasActiveOrder,
      isInPreparingState: isInPreparingState ?? this.isInPreparingState,
      isReady: isReady ?? this.isReady,
      hasLocationOn: hasLocationOn ?? this.hasLocationOn,
      isInLoading: isInLoading ?? this.isInLoading
    );
  }
}
