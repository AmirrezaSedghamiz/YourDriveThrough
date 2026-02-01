// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart';

class MapBuilder extends StatefulWidget {
  const MapBuilder(
      {super.key});



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
        LatLng(userLocation!.latitude!, userLocation!.longitude!), 18);
  }

  @override
  void initState() {
    getUserLocation();
    super.initState();
  }

  void onSearch() async {
    final response = await HttpClient.searchGeo.get(
        'search?term=${searchController.text}&lat=${userLocation!.latitude.toString()}&lng=${userLocation!.longitude.toString()}',
        options: HttpClient.globalHeader);
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
          body: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(35.715298, 51.404343),
                  initialZoom: 18,
                  onTap: (tapPosition, point) {
                    setState(() {
                      selectedLocation = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.data_base_project',
                  ),
                  MarkerLayer(markers: [
                    if (userLocation != null)
                      Marker(
                          point: LatLng(userLocation!.latitude!,
                              userLocation!.longitude!),
                          child: const Icon(
                            CupertinoIcons.location_fill,
                            size: 40,
                            color: Colors.blue,
                          )),
                    if (selectedLocation != null)
                      Marker(
                          point: selectedLocation!,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ))
                  ])
                ],
              ),
              if (isSearchExpanded)
                Localizations.override(
                  locale: const Locale('fa'),
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Bar Container
                          if (isSearchExpanded)
                            TextField(
                              controller: searchController,
                              onChanged: (value) {
                                onSearch();
                              },
                              style: const TextStyle(
                                  fontFamily: 'DanaFaNum', fontSize: 16),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: "جستجو",
                                prefixIcon: const Icon(Icons.search),
                                focusColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          // Search Results List
                          if (isSearchExpanded)
                            Expanded(
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  if (searchResults[index].address == null ||
                                      index > 6) return const SizedBox();
                                  return Container(
                                    color: Colors.white,
                                    child: ListTile(
                                      title: Text(
                                        searchResults[index].address ?? "",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedLocation = LatLng(
                                              searchResults[index].location.y,
                                              searchResults[index].location.x);
                                          isSearchExpanded = !isSearchExpanded;
                                          if (!isSearchExpanded) {
                                            searchController.clear();
                                            searchResults.clear();
                                          }
                                        });
                                        mapController.move(
                                            selectedLocation!, 18);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Floating Action Button to Expand Search
              Positioned(
                top: 10,
                right: 10,
                child: FloatingActionButton(
                  heroTag: 'search',
                  onPressed: () {
                    setState(() {
                      isSearchExpanded = !isSearchExpanded;
                      if (!isSearchExpanded) {
                        searchController.clear();
                        searchResults.clear();
                      }
                    });
                  },
                  child: Icon(
                    isSearchExpanded ? Icons.close : Icons.search,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionButton(
                  heroTag: 'submit',
                  onPressed: isLoading ||
                          (selectedLocation == null && userLocation == null)
                      ? () {}
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          final response = await HttpClient.reverseGeoCoding.get(
                              'reverse?lat=${selectedLocation != null ? selectedLocation!.latitude : userLocation?.latitude!}&lng=${selectedLocation != null ? selectedLocation!.longitude : userLocation?.longitude!}',
                              options: HttpClient.globalHeader);
                          
                        },
                  child: isLoading
                      ? Center(
                          child: LoadingAnimationWidget.fourRotatingDots(
                              color: Colors.green, size: 20),
                        )
                      : const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (userLocation != null) {
                mapController.move(
                    LatLng(userLocation!.latitude!, userLocation!.longitude!),
                    18);
              }
            },
            child: const Icon(Icons.location_searching_rounded),
          ),
        ),
      ),
    );
  }
}

class LocationSearch {
  int count;
  List<Itemm> items;
  LocationSearch({
    required this.count,
    required this.items,
  });

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
        (map['items']).map<Itemm>(
          (x) => Itemm.fromMap(x),
        ),
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
  LocationSeri({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
    };
  }

  factory LocationSeri.fromMap(Map<String, dynamic> map) {
    return LocationSeri(
      x: map['x'] as double,
      y: map['y'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationSeri.fromJson(String source) =>
      LocationSeri.fromMap(json.decode(source) as Map<String, dynamic>);
}
