// LoginViewModel.dart
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/SourceDesign/Enums/AccountTypes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class LoginState {
  final bool isPasswordVisibleSignUp;
  final bool isPasswordVisibleSignIn;
  final bool isConfirmPasswordVisible;
  final bool isInSignIn;
  final bool rememberMe;
  final AccountType? selectedType;
  final String? snackBarMessage;

  LoginState({
    this.isPasswordVisibleSignUp = false,
    this.isPasswordVisibleSignIn = false,
    this.isConfirmPasswordVisible = false,
    this.isInSignIn = true,
    this.rememberMe = false,
    this.selectedType = AccountType.customer,
    this.snackBarMessage,
  });

  LoginState copyWith({
    bool? isPasswordVisibleSignUp,
    bool? isPasswordVisibleSignIn,
    bool? isConfirmPasswordVisible,
    bool? isInSignIn,
    bool? rememberMe,
    AccountType? selectedType,
    String? snackBarMessage,
  }) {
    return LoginState(
      isPasswordVisibleSignUp: isPasswordVisibleSignUp ?? this.isPasswordVisibleSignUp,
      isPasswordVisibleSignIn: isPasswordVisibleSignIn ?? this.isPasswordVisibleSignIn,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      isInSignIn: isInSignIn ?? this.isInSignIn,
      rememberMe: rememberMe ?? this.rememberMe,
      selectedType: selectedType ?? this.selectedType,
      snackBarMessage: snackBarMessage ?? this.snackBarMessage,
    );
  }
}

