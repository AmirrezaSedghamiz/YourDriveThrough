// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection' show MapView;
import 'dart:convert';
import 'dart:io';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/GlobalWidgets/Services/MapWidgets/FloatingButtons.dart';
import 'package:application/GlobalWidgets/Services/MapWidgets/MapWidget.dart';
import 'package:application/GlobalWidgets/Services/MapWidgets/Serach.dart';
import 'package:application/Handlers/Repository/ManagerRepo.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart';

class MapBuilder extends StatefulWidget {
  const MapBuilder({super.key, required this.username, this.image, required this.callBackFunction});

  final String username;
  final File? image;
  final VoidCallback? callBackFunction;

  @override
  State<MapBuilder> createState() => _MapBuilderState();
}

class _MapBuilderState extends State<MapBuilder> {
  bool isLoading = false;
  LocationData? userLocation;
  LatLng? selectedLocation;
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  bool isSearchExpanded = false;
  List<Itemm> searchResults = []; // Mock search results for now

  Future<void> getUserLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    userLocation = await location.getLocation();
    setState(() {});
    mapController.move(
      LatLng(userLocation!.latitude!, userLocation!.longitude!),
      18,
    );
  }

  @override
  void initState() {
    getUserLocation();
    super.initState();
  }

  void onSearch() async {
    final response = await HttpClient.searchGeo.get(
      'search?term=${searchController.text}&lat=${userLocation!.latitude.toString()}&lng=${userLocation!.longitude.toString()}',
      options: HttpClient.globalHeader,
    );
    setState(() {
      searchResults = LocationSearch.fromMap(response.data).items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      locale: const Locale('en'),
      context: context,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            // inside build() Stack children:
            children: [
              // Optional background image
              MapWidget(
                mapController: mapController,
                userLocation: userLocation,
                selectedLocation: selectedLocation,
                onTapPoint: (point) {
                  setState(() {
                    selectedLocation = point;
                  });
                },
              ),

              // search panel
              MapSearchPanel<Itemm>(
                isExpanded: isSearchExpanded,
                controller: searchController,
                results: searchResults,
                hintText: "Search",
                titleOf: (it) => it.address ?? "",
                latLngOf: (it) => LatLng(it.location.y, it.location.x),
                onChanged: (_) => onSearch(),
                onPick: (point) {
                  setState(() {
                    selectedLocation = point;
                  });
                  mapController.move(point, 18);
                },
                onClose: () {
                  setState(() {
                    isSearchExpanded = !isSearchExpanded;
                    if (!isSearchExpanded) {
                      searchController.clear();
                      searchResults.clear();
                    }
                  });
                },
              ),

              MapSearchFab(
                expanded: isSearchExpanded,
                onPressed: () {
                  setState(() {
                    isSearchExpanded = !isSearchExpanded;
                    if (!isSearchExpanded) {
                      searchController.clear();
                      searchResults.clear();
                    }
                  });
                },
              ),

              MapSubmitFab(
                isLoading: isLoading,
                enabled: !(isLoading || selectedLocation == null),
                onPressed: () async {
                  setState(() => isLoading = true);
                  final address = await HttpClient.reverseGeoCoding.get(
                    'reverse?lat=${selectedLocation!.latitude}&lng=${selectedLocation!.longitude}',
                    options: HttpClient.globalHeader,
                  );
                  await ManagerRepo()
                      .fillRestaurantProfile(
                        username: widget.username,
                        longitude: formatCoordinate(
                          selectedLocation!.longitude,
                        ),
                        latitude: formatCoordinate(selectedLocation!.latitude),
                        image: widget.image,
                        address: address.data['formatted_address'],
                      )
                      .then((value) {
                        if (value == ConnectionStates.Success) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            NavigationService.popAllAndPush(
                              AppRoutes.fade(DashboardManager(initialPage: 0)),
                            );
                          });
                        }
                      });
                },
              ),
            ],
          ),
          floatingActionButton: MapCenterFab(
            onPressed: () {
              if (userLocation != null) {
                mapController.move(
                  LatLng(userLocation!.latitude!, userLocation!.longitude!),
                  18,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class LocationSearch {
  int count;
  List<Itemm> items;
  LocationSearch({required this.count, required this.items});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'count': count,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory LocationSearch.fromMap(Map<String, dynamic> map) {
    return LocationSearch(
      count: map['count'] as int,
      items: List<Itemm>.from(
        (map['items']).map<Itemm>((x) => Itemm.fromMap(x)),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationSearch.fromJson(String source) =>
      LocationSearch.fromMap(json.decode(source));
}

class Itemm {
  String? title;
  String? address;
  String? neighbourhood;
  LocationSeri location;
  Itemm({
    required this.title,
    required this.address,
    required this.neighbourhood,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'address': address,
      'neighbourhood': neighbourhood,
      'location': location.toMap(),
    };
  }

  factory Itemm.fromMap(Map<String, dynamic> map) {
    return Itemm(
      title: map['title'],
      address: map['address'],
      neighbourhood: map['neighbourhood'],
      location: LocationSeri.fromMap(map['location']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Itemm.fromJson(String source) =>
      Itemm.fromMap(json.decode(source) as Map<String, dynamic>);
}

class LocationSeri {
  double x;
  double y;
  LocationSeri({required this.x, required this.y});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'x': x, 'y': y};
  }

  factory LocationSeri.fromMap(Map<String, dynamic> map) {
    return LocationSeri(x: map['x'] as double, y: map['y'] as double);
  }

  String toJson() => json.encode(toMap());

  factory LocationSeri.fromJson(String source) =>
      LocationSeri.fromMap(json.decode(source) as Map<String, dynamic>);
}

double formatCoordinate(double value) {
  return double.parse(value.toStringAsFixed(6));
}
