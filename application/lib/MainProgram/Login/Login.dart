import 'package:application/GlobalWidgets/Colors.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameControllerSignUp = TextEditingController();
  final TextEditingController _passwordControllerSignUp =
      TextEditingController();
  final TextEditingController _nameControllerSignIn = TextEditingController();
  final TextEditingController _passwordControllerSignIn =
      TextEditingController();
  final TextEditingController _confirmPasswordControllerSignUp =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordVisibleSignIn = false;
  bool _isConfirmPasswordVisible = false;
  bool _isInSignIn = true;
  bool isCustomer = true;
  bool rememberMe = false;
  AccountType? _selectedType;

  void onChanged(AccountType? type) {
    setState(() {
      isCustomer = type == AccountType.customer;
    });
  }

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedType = AccountType.customer;
    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Setup animations
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// --- Page header ---
                        Center(
                          child: Column(
                            children: [
                              // Logo placeholder - replace with actual logo asset
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.drive_eta,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'DriveThru',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Order ahead, skip the wait',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: coalColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        /// --- Tab Switch ---
                        buildTabSwitch(),

                        SizedBox(height: 24),

                        /// --- Form Content with Expanded to push button to bottom ---
                        /// --- Form Content with Expanded to push button to bottom ---
                        Expanded(
                          child: AnimatedCrossFade(
                            duration: Duration(milliseconds: 300),
                            firstChild: signIn(),
                            secondChild: signUp(),
                            crossFadeState: _isInSignIn
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstCurve: Curves.easeInOut,
                            secondCurve: Curves.easeInOut,
                            layoutBuilder:
                                (
                                  Widget topChild,
                                  Key topChildKey,
                                  Widget bottomChild,
                                  Key bottomChildKey,
                                ) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(
                                        key: bottomChildKey,
                                        child: bottomChild,
                                      ),
                                      Positioned.fill(
                                        key: topChildKey,
                                        child: topChild,
                                      ),
                                    ],
                                  );
                                },
                          ),
                        ),

                        SizedBox(height: 24),

                        /// --- BUTTON ALWAYS AT BOTTOM ---
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              _isInSignIn ? _handleSignIn() : _createAccount();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isInSignIn ? "Sign In" : "Create Account",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTabSwitch() {
    return Container(
      width: MediaQuery.of(context).size.width - 64 / 412,
      height: 54,
      decoration: BoxDecoration(
        color: lightGrayColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Stack(
          children: [
            // Animated indicator background - now with fade effect
            AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: 1.0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  left: _isInSignIn
                      ? 0
                      : (MediaQuery.of(context).size.width - 64 / 412) / 2 - 28,
                ),
                width: (MediaQuery.of(context).size.width - 64 / 412) / 2 - 32,
                height: 46,
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Tab buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isInSignIn) {
                        setState(() {
                          _isInSignIn = true;
                        });
                      }
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                color: _isInSignIn
                                    ? primaryColor
                                    : Colors.black45,
                                fontWeight: _isInSignIn
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                shadows: _isInSignIn
                                    ? [
                                        Shadow(
                                          color: primaryColor.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : [],
                              ),
                          child: Text("Sign In"),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isInSignIn) {
                        setState(() {
                          _isInSignIn = false;
                        });
                      }
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                color: !_isInSignIn
                                    ? primaryColor
                                    : Colors.black45,
                                fontWeight: !_isInSignIn
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                shadows: !_isInSignIn
                                    ? [
                                        Shadow(
                                          color: primaryColor.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : [],
                              ),
                          child: Text("Sign Up"),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget signIn() {
    return Column(
      key: ValueKey('signIn'),
      children: [
        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Username",
                  style: Theme.of(context).textTheme!.bodyMedium,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameControllerSignIn,
                decoration: InputDecoration(
                  hintText: 'Enter your Username',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: coalColor,
                  ),
                  prefixIcon: Icon(Icons.person, color: coalColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: Theme.of(context).textTheme!.bodyMedium,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordControllerSignIn,
                obscureText: !_isPasswordVisibleSignIn,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: coalColor,
                  ),
                  prefixIcon: Icon(Icons.lock, color: coalColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisibleSignIn
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: coalColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisibleSignIn = !_isPasswordVisibleSignIn;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),
        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildCheckbox("Remember me", rememberMe, () {
                setState(() {
                  rememberMe = !rememberMe;
                });
              }),
              TextButton(
                onPressed: () {},
                child: Text(
                  "Forgot password?",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget signUp() {
    return Column(
      key: ValueKey('signUp'),
      children: [
        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Username",
                  style: Theme.of(context).textTheme!.bodyMedium,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameControllerSignUp,
                decoration: InputDecoration(
                  hintText: 'Enter a Username',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: coalColor,
                  ),
                  prefixIcon: Icon(Icons.person, color: coalColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: Theme.of(context).textTheme!.bodyMedium,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordControllerSignUp,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Create a password',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: coalColor,
                  ),
                  prefixIcon: Icon(Icons.lock, color: coalColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: coalColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Confirm Password",
                  style: Theme.of(context).textTheme!.bodyMedium,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordControllerSignUp,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Confirm your password',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: coalColor,
                  ),
                  prefixIcon: Icon(Icons.lock, color: coalColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: coalColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: coalColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),
        AnimatedOpacity(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: 1.0,
          child: checkBoxes(context),
        ),
      ],
    );
  }

  void _select(AccountType type) {
    setState(() {
      _selectedType = type;
      onChanged(type);
    });
  }

  Widget checkBoxes(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildCheckbox(
          "As Customer",
          _selectedType == AccountType.customer,
          () => _select(AccountType.customer),
        ),
        buildCheckbox(
          "As Restaurant",
          _selectedType == AccountType.restaurant,
          () => _select(AccountType.restaurant),
        ),
      ],
    );
  }

  Widget buildCheckbox(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => onTap(),
            activeColor: primaryColor,
          ),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _handleSignIn() {
    // Add your sign in logic here
    String name = _nameControllerSignIn.text;
    String password = _passwordControllerSignIn.text;

    if (name.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    _showSnackBar('Signed in successfully!');
  }

  void _createAccount() {
    // Add your account creation logic here
    String name = _nameControllerSignUp.text;
    String password = _passwordControllerSignUp.text;
    String confirmPassword = _confirmPasswordControllerSignUp.text;

    if (name.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    // Proceed with account creation
    _showSnackBar('Account created successfully!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
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

enum AccountType { customer, restaurant }
