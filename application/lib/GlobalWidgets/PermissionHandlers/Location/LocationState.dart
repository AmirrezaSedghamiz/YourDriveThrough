import 'package:location/location.dart';

class LocationState {
  final bool isLoading;
  final LocationData? data;
  final LocationIssue? issue;
  final String? errorMessage;

  const LocationState._({
    required this.isLoading,
    this.data,
    this.issue,
    this.errorMessage,
  });

  const LocationState.idle() : this._(isLoading: false);

  const LocationState.loading() : this._(isLoading: true);

  const LocationState.success(LocationData data)
      : this._(isLoading: false, data: data);

  const LocationState.failure(LocationIssue issue)
      : this._(isLoading: false, issue: issue);

  const LocationState.error(String message)
      : this._(isLoading: false, errorMessage: message);

  bool get hasLocation => data != null;
  bool get needsUserAction => issue != null;
}

enum LocationIssue {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
}