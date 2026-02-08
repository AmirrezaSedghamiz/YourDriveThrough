import 'package:application/MainProgram/Customer/MainPage/MainPageState.dart';
import 'package:application/SourceDesign/Enums/AccountTypes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPageViewModel extends Notifier<MainPageState> {
  @override
  MainPageState build() {
    return MainPageState();
  }
  //TODO
  
}

final mainPageViewModelProvider =
    NotifierProvider<MainPageViewModel, MainPageState>(
      () => MainPageViewModel(),
    );
