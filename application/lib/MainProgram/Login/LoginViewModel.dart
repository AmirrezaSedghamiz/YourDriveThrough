import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/Handlers/Repository/LoginRepo.dart';
import 'package:application/MainProgram/Login/LoginState.dart';
import 'package:application/SourceDesign/Enums/AccountTypes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = state.copyWith(isInSignIn: !state.isInSignIn);
  }

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  void selectAccountType(AccountType type) {
    state = state.copyWith(selectedType: type);
  }

  Future<void> signUp({
    required String username,
    required String password,
    required String confirmPassword,
    required AccountType? role,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(errorSignUpName: 'Please fill in all fields');
      return;
    }
    if (role == null) {
      state = state.copyWith(errorSignUpName: 'Please select a role');
      return;
    }
    if (password != confirmPassword) {
      state = state.copyWith(
        errorSignUpConfirm: 'Must be the same as your password',
      );
      return;
    }

    final data = await LoginRepo().signUp(
      phoneNumber: username,
      password: password,
      role: role == AccountType.customer ? "customer" : " restaurant",
    );

    if (data != ConnectionStates.Success) {
      state = state.copyWith(errorSignUpName: 'This user already exists');
    }

    state = state.copyWith(logInSuccessful: true);
  }

  Future<void> logIn({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(errorLogInName: 'Please fill in all fields');
      return;
    }

    final data = await LoginRepo().loginUser(
      phoneNumber: username,
      password: password,
    );

    if (data is ConnectionStates) {
      state = state.copyWith(errorLogInName: 'Invalid credentials');
      return;
    }

    state = state.copyWith(
      logInSuccessful: true,
      isProfileComplete: data["complete"],
      selectedType: data["role"] == "customer"
          ? AccountType.customer
          : AccountType.restaurant,
    );
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  () => LoginViewModel(),
);
