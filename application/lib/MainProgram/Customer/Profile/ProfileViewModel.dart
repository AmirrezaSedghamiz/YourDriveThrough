import 'package:application/GlobalWidgets/PermissionHandlers/ImagePickerService.dart';
import 'package:application/MainProgram/Customer/Profile/ProfileState.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState(
        username: "Alice Sm",
        password: "••••••••",
      );

  void toggleEdit() {
    state = state.copyWith(isEditing: !state.isEditing, clearError: true);
  }

  void setUsername(String v) {
    state = state.copyWith(username: v, clearError: true);
  }

  void setPassword(String v) {
    state = state.copyWith(password: v, clearError: true);
  }

  /// Your UI asks: "make it happen in riverpod" + you already implemented picker.
  /// This uses your ImagePickerService and stores the selected File in state.
  Future<void> pickProfileImage(BuildContext context) async {
    try {
      state = state.copyWith(clearError: true);

      final picker = ImagePickerService(context: context);
      await picker.pickImage();

      // If user cancelled, image stays unchanged.
      final file = picker.image;
      if (file == null) return;

      state = state.copyWith(imageFile: file);
    } catch (e) {
      state = state.copyWith(error: "$e");
    }
  }

  /// Placeholder hook (you said you'll handle logout yourself).
  /// Keep this for wiring from UI.
  Future<void> logout() async {
    // no-op (user will implement)
  }

  /// Optional hook if you later want Save button behavior.
  Future<void> save() async {
    // no-op (user will implement)
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(() => ProfileViewModel());