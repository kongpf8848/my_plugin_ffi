import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:my_plugin_ffi/my_plugin_ffi.dart' as my_plugin_ffi;
import 'package:my_plugin_ffi/my_plugin_ffi_bindings_generated.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int sumResult;
  late Future<int> sumAsyncResult;
  late int subtractResult;

  @override
  void initState() {
    super.initState();
    sumResult = my_plugin_ffi.sum(1, 2);
    sumAsyncResult = my_plugin_ffi.sumAsync(3, 4);
    subtractResult = my_plugin_ffi.subtract(1, 2);
  }

  @override
  Widget build(BuildContext context) {
    print("++++++++++++++++++++Boxing main thread for sum(1, 2)...");
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Packages')),
        body: SingleChildScrollView(
          child: Container(
            padding: const .all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: .center,
                ),
                spacerSmall,
                Text(
                  'sum(1, 2) = $sumResult',
                  style: textStyle,
                  textAlign: .center,
                ),
                spacerSmall,
                FutureBuilder<int>(
                  future: sumAsyncResult,
                  builder: (BuildContext context, AsyncSnapshot<int> value) {
                    final displayValue = (value.hasData)
                        ? value.data
                        : 'loading';
                    return Text(
                      'await sumAsync(3, 4) = $displayValue',
                      style: textStyle,
                      textAlign: .center,
                    );
                  },
                ),
                spacerSmall,
                ElevatedButton(
                  onPressed: () {
                    if (kDebugMode) {
                      print('subtract(1, 2) = $subtractResult');
                    }
                  },
                  child: const Text('subtract'),
                ),
                spacerSmall,
                ElevatedButton(
                  onPressed: () {
                    if (kDebugMode) {
                      print('languages() = ${my_plugin_ffi.getLanguages()}');
                    }
                  },
                  child: const Text('languages'),
                ),
                spacerSmall,
                ElevatedButton(
                  onPressed: () {
                    if (kDebugMode) {
                      print('map() = ${my_plugin_ffi.getMap()}');
                    }
                  },
                  child: const Text('map'),
                ),
                spacerSmall,
                ElevatedButton(
                  onPressed: () {
                    final coordinate = my_plugin_ffi.createCoordinate(3.5, 4.6);
                    print(
                      'Coordinate is lat ${coordinate.latitude}, long ${coordinate.longitude}',
                    );

                    final place = my_plugin_ffi.createPlace("jack", 2.0, 24.0);
                    final name = place.name.cast<Utf8>().toDartString();
                    final coord = place.coordinate;
                    print(
                      'The name of my place is $name at ${coord.latitude}, ${coord.longitude}',
                    );

                    final dist = my_plugin_ffi.distance(
                      my_plugin_ffi.createCoordinate(2.0, 2.0),
                      my_plugin_ffi.createCoordinate(5.0, 6.0),
                    );
                    print("distance between (2,2) and (5,6) = $dist");
                  },
                  child: const Text('distance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
