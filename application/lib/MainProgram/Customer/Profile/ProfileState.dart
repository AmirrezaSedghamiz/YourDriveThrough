import 'dart:io';

class ProfileState {
  final String username;
  final String password;
  final File? imageFile;

  final bool isEditing;
  final bool isSaving;
  final String? error;

  const ProfileState({
    this.username = "",
    this.password = "",
    this.imageFile,
    this.isEditing = false,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    String? username,
    String? password,
    File? imageFile,
    bool setImageNull = false,
    bool? isEditing,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      username: username ?? this.username,
      password: password ?? this.password,
      imageFile: setImageNull ? null : (imageFile ?? this.imageFile),
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}