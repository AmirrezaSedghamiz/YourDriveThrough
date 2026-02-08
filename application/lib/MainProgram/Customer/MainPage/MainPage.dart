import 'package:application/GlobalWidgets/ReusableComponents/AppBar.dart';
import 'package:application/MainProgram/Customer/MainPage/MainPageViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainPageViewModelProvider);
    final viewModel = ref.read(mainPageViewModelProvider.notifier);

    return Scaffold(
      appBar: AppAppBar(title: "Good Day", showBack: false, centerTitle: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
        ],
      )
    );
  }
}
