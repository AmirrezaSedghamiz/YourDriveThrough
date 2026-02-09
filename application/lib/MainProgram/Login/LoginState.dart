// ignore_for_file: public_member_api_docs, sort_constructors_first
// LoginViewModel.dart
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/SourceDesign/Enums/AccountTypes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginState {
  final bool isPasswordVisibleSignUp;
  final bool isPasswordVisibleSignIn;
  final bool isConfirmPasswordVisible;
  final bool isInSignIn;
  final bool isProfileComplete;
  final bool rememberMe;
  final bool logInSuccessful;
  final String? errorLogInName;
  final String? errorLogInPassword;
  final String? errorSignUpName;
  final String? errorSignUpConfirm;
  final AccountType? selectedType;

  LoginState({
    this.isPasswordVisibleSignUp = false,
    this.isPasswordVisibleSignIn = false,
    this.isProfileComplete = true,
    this.isConfirmPasswordVisible = false,
    this.isInSignIn = true,
    this.rememberMe = false,
    this.selectedType = AccountType.customer,
    this.logInSuccessful = false,
    this.errorLogInName,
    this.errorLogInPassword,
    this.errorSignUpConfirm,
    this.errorSignUpName,
  });


  LoginState copyWith({
    bool? isPasswordVisibleSignUp,
    bool? isPasswordVisibleSignIn,
    bool? isConfirmPasswordVisible,
    bool? isInSignIn,
    bool? isProfileComplete,
    bool? rememberMe,
    bool? logInSuccessful,
    String? errorLogInName,
    String? errorLogInPassword,
    String? errorSignUpName,
    String? errorSignUpConfirm,
    AccountType? selectedType,
  }) {
    return LoginState(
      isPasswordVisibleSignUp: isPasswordVisibleSignUp ?? this.isPasswordVisibleSignUp,
      isPasswordVisibleSignIn: isPasswordVisibleSignIn ?? this.isPasswordVisibleSignIn,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      isInSignIn: isInSignIn ?? this.isInSignIn,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      rememberMe: rememberMe ?? this.rememberMe,
      logInSuccessful: logInSuccessful ?? this.logInSuccessful,
      errorLogInName: errorLogInName ?? this.errorLogInName,
      errorLogInPassword: errorLogInPassword ?? this.errorLogInPassword,
      errorSignUpName: errorSignUpName ?? this.errorSignUpName,
      errorSignUpConfirm: errorSignUpConfirm ?? this.errorSignUpConfirm,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}
