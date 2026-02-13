import 'dart:io';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/MainProgram/Customer/Profile/ProfileViewModel.dart';
import 'package:application/MainProgram/Login/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _userC;
  late final TextEditingController _passC;

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileViewModelProvider);
    _userC = TextEditingController(text: s.username);
    _passC = TextEditingController(text: s.password);
  }

  @override
  void dispose() {
    _userC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final state = ref.watch(profileViewModelProvider);
    final vm = ref.read(profileViewModelProvider.notifier);

    // keep controllers in sync (without fighting user typing)
    ref.listen(profileViewModelProvider, (prev, next) {
      if (prev?.username != next.username && _userC.text != next.username) {
        _userC.text = next.username;
      }
      if (prev?.password != next.password && _passC.text != next.password) {
        _passC.text = next.password;
      }
    });

    Future<void> _confirmLogOut(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onYes,
  }) async {
    final t = Theme.of(context).textTheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: t.titleLarge),
        content: Text(message, style: t.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Log Out",
              style: t.labelLarge?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) onYes();
  }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text("Profile", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            _TopCard(
              username: state.username,
              imageFile: state.imageFile,
              isEditing: state.isEditing,
              onEditTap: vm.toggleEdit,
              onPickImage: () => vm.pickProfileImage(context),
            ),
            const SizedBox(height: 14),

            // inline edit fields (no navigation)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: state.isEditing
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _EditSection(
                usernameController: _userC,
                passwordController: _passC,
                onUsernameChanged: vm.setUsername,
                onPasswordChanged: vm.setPassword,
              ),
              secondChild: const SizedBox.shrink(),
            ),

            const SizedBox(height: 14),

            // Payment & Preferences
            _ActionRow(
              icon: Icons.credit_card_rounded,
              title: "Payment & Preferences",
              onTap: () {
                // keep UI; user can implement navigation if desired
              },
            ),
            const SizedBox(height: 6),

            // Order History
            _ActionRow(
              icon: Icons.history_rounded,
              title: "Order History",
              onTap: () {},
            ),

            const SizedBox(height: 14),

            // AD placeholder (you said you'll handle ad yourself)
            const _AdPlaceholder(),

            const SizedBox(height: 14),

            _ActionRow(
              icon: Icons.help_outline_rounded,
              title: "Help & Support",
              onTap: () {},
            ),
            const SizedBox(height: 6),
            _ActionRow(
              icon: Icons.settings_rounded,
              title: "Settings",
              onTap: () {},
            ),

            const SizedBox(height: 14),

            if (state.error != null) ...[
              Text(
                state.error!,
                style: t.bodyMedium?.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: 10),
            ],

            // Logout button
            GestureDetector(
              onTap: () {
                _confirmLogOut(
                context,
                title: "Log out",
                message:
                    "You will be logged out of the application and need to log in again for using this application. Continue",
                onYes: () {
                  TokenStore.clearTokens();
                  var route = AppRoutes.fade(LoginPage());
                  NavigationService.popAllAndPush(route);
                },
              );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE43B3B), // matches screenshot vibe
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Log Out",
                        style: t.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- WIDGETS --------------------

class _TopCard extends StatelessWidget {
  const _TopCard({
    required this.username,
    required this.imageFile,
    required this.isEditing,
    required this.onEditTap,
    required this.onPickImage,
  });

  final String username;
  final File? imageFile;
  final bool isEditing;
  final VoidCallback onEditTap;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEFEFEF),
                  backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
                  child: imageFile == null
                      ? Icon(
                          Icons.person_rounded,
                          color: Colors.black.withOpacity(0.35),
                          size: 28,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 10, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isEmpty ? "—" : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  "Online • New Y",
                  style: t.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: Colors.black.withOpacity(0.65)),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? "Done" : "Edit Profile",
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.usernameController,
    required this.passwordController,
    required this.onUsernameChanged,
    required this.onPasswordChanged,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onPasswordChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: t.bodyMedium?.copyWith(color: Colors.black.withOpacity(0.35)),
          filled: true,
          fillColor: const Color(0xFFF4F4F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.65)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Username", style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: usernameController,
          onChanged: onUsernameChanged,
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          decoration: deco("Enter username"),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        Text("Password", style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          onChanged: onPasswordChanged,
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          decoration: deco("Enter password"),
          obscureText: true,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black.withOpacity(0.75)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.black.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "Sponsored",
              style: t.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFEFEFEF),
            ),
            child: Center(
              child: Text(
                "Ad goes here",
                style: t.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Exclusive Deals This Week!",
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            "Find amazing discounts on your favorite brands.\n"
            "Don’t miss out on limited-time offers and save big.",
            style: t.bodySmall?.copyWith(
              height: 1.25,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6A00),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "Shop Now",
                style: t.labelLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}