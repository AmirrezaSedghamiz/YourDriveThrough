// Updated Login.dart using reusable components
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/GlobalWidgets/ReusableComponents/Buttons.dart';
import 'package:application/GlobalWidgets/ReusableComponents/CheckBox.dart';
import 'package:application/GlobalWidgets/ReusableComponents/TabSwitch.dart';
import 'package:application/GlobalWidgets/ReusableComponents/TextFields.dart';
import 'package:application/GlobalWidgets/Services/Map.dart';
import 'package:application/MainProgram/Customer/DashboardCustomer/DashboardCustomer.dart';
import 'package:application/MainProgram/Login/LoginState.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManager.dart';
import 'package:application/SourceDesign/Enums/AccountTypes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/MainProgram/Login/LoginViewModel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameControllerSignUp = TextEditingController();
  final TextEditingController _passwordControllerSignUp =
      TextEditingController();
  final TextEditingController _nameControllerSignIn = TextEditingController();
  final TextEditingController _passwordControllerSignIn =
      TextEditingController();
  final TextEditingController _confirmPasswordControllerSignUp =
      TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final viewModel = ref.read(loginViewModelProvider.notifier);
    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      final wasLoggedIn = prev?.logInSuccessful ?? false;
      final isLoggedIn = next.logInSuccessful;
      final role = next.selectedType;
      if (!wasLoggedIn && isLoggedIn) {
        var route = (role == AccountType.customer
            ? AppRoutes.fade(DashboardCustomer(initialPage: 0))
            : next.isProfileComplete
            ? AppRoutes.fade(DashboardManager(initialPage: 0,))
            : AppRoutes.fade(
                MapBuilder(
                  username: next.username ?? ""
                ),
              ));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigationService.popAllAndPush(route);
        });
      }
    });
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// --- Page header ---
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.drive_eta,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DriveThru',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order ahead, skip the wait',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: AppColors.coal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// --- Tab Switch ---
              AppTabSwitch(
                value: state.isInSignIn,
                onChanged: (value) {
                  if ((value && !state.isInSignIn) ||
                      (!value && state.isInSignIn)) {
                    viewModel.toggleSignInSignUp();
                  }
                },
                leftLabel: "Sign In",
                rightLabel: "Sign Up",
              ),

              const SizedBox(height: 24),

              /// --- Form Content ---
              /// IMPORTANT: No custom Stack/Positioned.fill inside a scroll view.
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: signIn(state, viewModel),
                secondChild: signUp(state, viewModel),
                crossFadeState: state.isInSignIn
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
              ),

              const SizedBox(height: 24),
              if (state.isInSignIn)
                SizedBox(height: MediaQuery.of(context).size.height * 0.125),

              /// --- BUTTON ---
              AppButton(
                text: state.isInSignIn ? "Sign In" : "Create Account",
                onPressed: () {
                  if (state.isInSignIn) {
                    viewModel.logIn(
                      username: _nameControllerSignIn.text,
                      password: _passwordControllerSignIn.text,
                    );
                  } else {
                    viewModel.signUp(
                      username: _nameControllerSignUp.text,
                      password: _passwordControllerSignUp.text,
                      confirmPassword: _confirmPasswordControllerSignUp.text,
                      role: state.selectedType,
                    );
                  }
                },
                variant: AppButtonVariant.primary,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget signIn(LoginState state, LoginViewModel viewModel) {
    return Column(
      key: ValueKey('signIn'),
      children: [
        AppTextField(
          controller: _nameControllerSignIn,
          labelText: "Username",
          hintText: 'Enter your Username',
          prefixIcon: Icon(Icons.person, color: AppColors.coal),
          errorText: state.errorLogInName,
        ),
        SizedBox(height: 16),
        AppPasswordField(
          controller: _passwordControllerSignIn,
          labelText: "Password",
          hintText: 'Enter your password',
          onChanged: (value) {},
          errorText: state.errorLogInPassword,
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            // AppCheckbox(
            //   label: "Remember me",
            //   value: state.rememberMe,
            //   onChanged: (_) => viewModel.toggleRememberMe(),
            // ),
            TextButton(
              onPressed: () {},
              child: Text(
                "Forgot password?",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget signUp(LoginState state, LoginViewModel viewModel) {
    return Column(
      key: ValueKey('signUp'),
      children: [
        AppTextField(
          controller: _nameControllerSignUp,
          labelText: "Username",
          hintText: 'Enter a Username',
          prefixIcon: Icon(Icons.person, color: AppColors.coal),
          errorText: state.errorSignUpName,
        ),
        SizedBox(height: 16),
        AppPasswordField(
          controller: _passwordControllerSignUp,
          labelText: "Password",
          hintText: 'Create a password',
          onChanged: (value) {},
        ),
        SizedBox(height: 16),
        AppPasswordField(
          controller: _confirmPasswordControllerSignUp,
          labelText: "Confirm Password",
          hintText: 'Confirm your password',
          onChanged: (value) {},
          errorText: state.errorSignUpConfirm,
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppCheckbox(
              label: "As Customer",
              value: state.selectedType == AccountType.customer,
              onChanged: (_) =>
                  viewModel.selectAccountType(AccountType.customer),
            ),
            AppCheckbox(
              label: "As Restaurant",
              value: state.selectedType == AccountType.restaurant,
              onChanged: (_) =>
                  viewModel.selectAccountType(AccountType.restaurant),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameControllerSignUp.dispose();
    _nameControllerSignIn.dispose();
    _passwordControllerSignIn.dispose();
    _passwordControllerSignUp.dispose();
    _confirmPasswordControllerSignUp.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
