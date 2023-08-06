import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Gps Image Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? imageUrl;
  bool hasConnection = true;

  LocationPermission? permission;

  bool get isAllowed => ![
        LocationPermission.denied,
        LocationPermission.deniedForever,
        LocationPermission.unableToDetermine
      ].contains(permission);

  String get randomImage =>
      'https://loremflickr.com/320/240/all?${DateTime.now().millisecondsSinceEpoch}';

  @override
  initState() {
    // initState cannot be async. Hence we call checkPermissionAndInitGpsStream here.
    checkPermissionAndInitGpsStream();
    // Same goes for
    setInternetConnectionListener();
    super.initState();
  }

  Future<void> setInternetConnectionListener() async {
    await setHasConnection();
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      await setHasConnection();
    });
  }

  Future<void> setHasConnection() async {
    final bool newHasConnection =
        await InternetConnectionChecker().hasConnection;
    // Calling setState with an async closure is not allowed :(
    setState(() {
      hasConnection = newHasConnection;
    });
  }

  Future<void> checkPermissionAndInitGpsStream() async {
    final LocationPermission currentPermission =
        await Geolocator.checkPermission();
    setState(() {
      permission = currentPermission;
    });

    if (!isAllowed) {
      final LocationPermission newPermission =
          await Geolocator.requestPermission();
      setState(() {
        permission = newPermission;
      });
    }

    positionStreamInit();
  }

  void positionStreamInit() {
    if (isAllowed) {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      Stream<Position> serviceStatusStream =
          Geolocator.getPositionStream(locationSettings: locationSettings);

      // The stream will be triggered if listen is called
      serviceStatusStream.listen((Position? position) async {
        _loadNewImage();
      });
    }
  }

  void _loadNewImage() {
    setState(() {
      imageUrl = randomImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: (isAllowed)
                ? [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Some random image...',
                      ),
                    ),
                    SizedBox(
                      height: 320,
                      width: 320,
                      child: (hasConnection)
                          ? (imageUrl == null)
                              ? Container()
                              : CachedNetworkImage(
                                  imageUrl: imageUrl!,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                )
                          : const Center(child: Text("No internet connection")),
                    ),
                  ]
                : [
                    const Text(
                        'You have to permit the access to your location'),
                    TextButton(
                        onPressed: checkPermissionAndInitGpsStream,
                        style: TextButton.styleFrom(
                          surfaceTintColor: Colors.blue,
                        ),
                        child: const Text('Permit'))
                  ],
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
