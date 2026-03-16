import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'my_plugin_ffi_bindings_generated.dart';
import 'package:ffi/ffi.dart';

/// A very short-lived native function.
///
/// For very short-lived functions, it is fine to call them on the main isolate.
/// They will block the Dart execution while running the native function, so
/// only do this for native functions which are guaranteed to be short-lived.
int sum(int a, int b) => _bindings.sum(a, b);

/// A longer lived native function, which occupies the thread calling it.
///
/// Do not call these kind of native functions in the main isolate. They will
/// block Dart execution. This will cause dropped frames in Flutter applications.
/// Instead, call these native functions on a separate isolate.
///
/// Modify this to suit your own use case. Example use cases:
///
/// 1. Reuse a single isolate for various different kinds of requests.
/// 2. Use multiple helper isolates for parallel execution.
Future<int> sumAsync(int a, int b) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextSumRequestId++;
  final _SumRequest request = _SumRequest(requestId, a, b);
  final Completer<int> completer = Completer<int>();
  _sumRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

int subtract(int a, int b) => _bindings.subtract(a, b);

String hello() {
  final ffi.Pointer<ffi.Char> result = _bindings.hello();
  return result.cast<Utf8>().toDartString();
}

List<String> getLanguages() {
  final ffi.Pointer<ffi.Int> outLen = malloc.allocate<ffi.Int>(ffi.sizeOf<ffi.Int>());
  final ffi.Pointer<ffi.Pointer<ffi.Char>> result = _bindings.get_languages(outLen);
  final int len = outLen.value;
  final List<String> languages = <String>[];
  for (int i = 0; i < len; i++) {
    final ffi.Pointer<ffi.Char> languagePtr = result.elementAt(i).value;
    languages.add(languagePtr.cast<Utf8>().toDartString());
  }
  malloc.free(outLen);
  _bindings.free_languages(result, len);
  return languages;
}

Map<String, String> getMap() {
  final ffi.Pointer<ffi.Int> outPairs = malloc.allocate<ffi.Int>(ffi.sizeOf<ffi.Int>());
  final ffi.Pointer<ffi.Pointer<ffi.Char>> arr = _bindings.get_map(outPairs);
  final int pairs = outPairs.value;
  malloc.free(outPairs);

  if (arr == ffi.nullptr || pairs == 0) return <String, String>{};

  final Map<String, String> result = <String, String>{};
  for (int i = 0; i < pairs; i++) {
    final ffi.Pointer<ffi.Char> keyPtr = arr.elementAt(i * 2).value;
    final ffi.Pointer<ffi.Char> valPtr = arr.elementAt(i * 2 + 1).value;
    final String key = keyPtr.cast<Utf8>().toDartString();
    final String val = valPtr.cast<Utf8>().toDartString();
    result[key] = val;
  }

  _bindings.free_map(arr, pairs);
  return result;
}

Coordinate createCoordinate(double x, double y) {
  final Coordinate c = _bindings.create_coordinate(x, y);
  return c;
}

Place createPlace(String name, double lat, double lon) {
  final ffi.Pointer<Utf8> utf8 = name.toNativeUtf8();
  final Place p = _bindings.create_place(utf8.cast<ffi.Char>(), lat, lon);
  return p;
}

double distance(Coordinate c1, Coordinate c2) {
  return _bindings.distance(c1, c2);
}

String reverse(String str) {
  final int len = str.length;
  final ffi.Pointer<Utf8> utf8 = str.toNativeUtf8();
  final result = _bindings.reverse(utf8.cast<ffi.Char>(), len);
  return result.cast<Utf8>().toDartString();
}

String getBaseVersion({int bufferSize = 256}) {
  final ffi.Pointer<ffi.Char> versionPtr = malloc<ffi.Char>(bufferSize);
  try {
    _bindings.getBaseVersion(versionPtr);
    return versionPtr.cast<Utf8>().toDartString();
  } finally {
    malloc.free(versionPtr);
  }
}

/// Function that takes a callback
void callCallback(int value, DartIntCallbackFunction callback) {
  final nativeCallback = ffi.NativeCallable<IntCallbackFunction>.isolateLocal(callback);
  try {
    _bindings.call_callback(value, nativeCallback.nativeFunction);
  } finally {
    nativeCallback.close();
  }
}

const String _libName = 'my_plugin_ffi';

/// The dynamic library in which the symbols for [MyPluginFfiBindings] can be found.
final ffi.DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final MyPluginFfiBindings _bindings = MyPluginFfiBindings(_dylib);

/// A request to compute `sum`.
///
/// Typically sent from one isolate to another.
class _SumRequest {
  final int id;
  final int a;
  final int b;

  const _SumRequest(this.id, this.a, this.b);
}

/// A response with the result of `sum`.
///
/// Typically sent from one isolate to another.
class _SumResponse {
  final int id;
  final int result;

  const _SumResponse(this.id, this.result);
}

/// Counter to identify [_SumRequest]s and [_SumResponse]s.
int _nextSumRequestId = 0;

/// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
final Map<int, Completer<int>> _sumRequests = <int, Completer<int>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _SumResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<int> completer = _sumRequests[data.id]!;
        _sumRequests.remove(data.id);
        completer.complete(data.result);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // On the helper isolate listen to requests and respond to them.
        if (data is _SumRequest) {
          final int result = _bindings.sum_long_running(data.a, data.b);
          final _SumResponse response = _SumResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();
