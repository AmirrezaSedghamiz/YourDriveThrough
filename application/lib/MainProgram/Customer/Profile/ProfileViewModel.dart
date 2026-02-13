import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/PermissionHandlers/ImagePickerService.dart';
import 'package:application/Handlers/Repository/CustomerRepo.dart';
import 'package:application/MainProgram/Customer/Profile/ProfileState.dart';
import 'package:application/SourceDesign/Models/UserInfo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // 1) initial placeholder state (loading=true)
    final initial = const ProfileState(
      username: "",
      password: "",
      isLoading: true,
    );

    Future.microtask(_loadProfileFromApi);

    return initial;
  }

  Future<void> _loadProfileFromApi() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final data = await CustomerRepo().getProfile();

      if (data is ConnectionStates) {
        state = state.copyWith(error: "Failed to fetch data!");
        return;
      }

      state = state.copyWith(
        username: (data as UserInfo).username,
        image: data.image,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "$e");
    }
  }

  Future<void> toggleEdit() async {
    if (state.isEditing == true) {
      final data = await CustomerRepo().editProfile(
        username: state.username,
        image: state.imageFile,
      );
      if (data != ConnectionStates.Success) {
        state = state.copyWith(error: "This username is taken!");
        return;
      }
    }
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
