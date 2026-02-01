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

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() {
    return LoginState();
  }

  void togglePasswordVisibilitySignUp() {
    state = state.copyWith(
      isPasswordVisibleSignUp: !state.isPasswordVisibleSignUp,
    );
  }

  void togglePasswordVisibilitySignIn() {
    state = state.copyWith(
      isPasswordVisibleSignIn: !state.isPasswordVisibleSignIn,
    );
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  void toggleSignInSignUp() {
    state = state.copyWith(
      isInSignIn: !state.isInSignIn,
    );
  }

  void toggleRememberMe() {
    state = state.copyWith(
      rememberMe: !state.rememberMe,
    );
  }

  void selectAccountType(AccountType type) {
    state = state.copyWith(
      selectedType: type,
    );
  }

  void signIn({required String username, required String password}) {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(
        snackBarMessage: 'Please fill in all fields',
      );
      return;
    }

    // Add your actual sign-in logic here
    state = state.copyWith(
      snackBarMessage: 'Signed in successfully!',
    );
  }

  void signUp({
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      state = state.copyWith(
        snackBarMessage: 'Please fill in all fields',
      );
      return;
    }

    if (password != confirmPassword) {
      state = state.copyWith(
        snackBarMessage: 'Passwords do not match',
      );
      return;
    }

    // Add your actual sign-up logic here
    state = state.copyWith(
      snackBarMessage: 'Account created successfully!',
    );
  }

  void clearSnackBar() {
    state = state.copyWith(snackBarMessage: null);
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  () => LoginViewModel(),
);