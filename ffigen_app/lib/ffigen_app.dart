import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart' as p; // Add this import

import 'duktape_bindings_generated.dart';

const String _libName = 'ffigen_app';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    // Add from here...
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return DynamicLibrary.open('build/macos/Build/Products/Debug'
          '/$_libName/$_libName.framework/$_libName');
    }
    // ...to here.
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    // Add from here...
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return DynamicLibrary.open(
          'build/linux/x64/debug/bundle/lib/lib$_libName.so');
    }
    // ...to here.
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    // Add from here...
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return DynamicLibrary.open(p.canonicalize(
          p.join(r'build\windows\runner\Debug', '$_libName.dll')));
    }
    // ...to here.
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final DuktapeBindings _bindings = DuktapeBindings(_dylib);

class Duktape {
  Duktape() {
    ctx =
        _bindings.duk_create_heap(nullptr, nullptr, nullptr, nullptr, nullptr);
  }

  // Modify this function
  String evalString(String jsCode) {
    var nativeUtf8 = jsCode.toNativeUtf8();
    final evalResult = _bindings.duk_eval_raw(
        ctx,
        nativeUtf8.cast<Char>(),
        0,
        0 |
            DUK_COMPILE_EVAL |
            DUK_COMPILE_SAFE |
            DUK_COMPILE_NOSOURCE |
            DUK_COMPILE_STRLEN |
            DUK_COMPILE_NOFILENAME);
    ffi.malloc.free(nativeUtf8);

    if (evalResult != 0) {
      throw _retrieveTopOfStackAsString();
    }

    return _retrieveTopOfStackAsString();
  }

  // Add this function
  String _retrieveTopOfStackAsString() {
    Pointer<Size> outLengthPtr = ffi.calloc<Size>();
    final errorStrPtr = _bindings.duk_safe_to_lstring(ctx, -1, outLengthPtr);
    final returnVal =
        errorStrPtr.cast<ffi.Utf8>().toDartString(length: outLengthPtr.value);
    ffi.calloc.free(outLengthPtr);
    return returnVal;
  }

  void dispose() {
    _bindings.duk_destroy_heap(ctx);
    ctx = nullptr;
  }

  late Pointer<duk_hthread> ctx;
}

// import 'dart:ffi';
// import 'dart:io' show Platform;
// import 'package:ffi/ffi.dart' as ffi;

// import 'duktape_bindings_generated.dart';

// const String _libName = 'ffigen_app';

// final DynamicLibrary _dylib = () {
//   if (Platform.isMacOS || Platform.isIOS) {
//     return DynamicLibrary.open('$_libName.framework/$_libName');
//   }
//   if (Platform.isAndroid || Platform.isLinux) {
//     return DynamicLibrary.open('lib$_libName.so');
//   }
//   if (Platform.isWindows) {
//     return DynamicLibrary.open('$_libName.dll');
//   }
//   throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
// }();

// final DuktapeBindings _bindings = DuktapeBindings(_dylib);

// class Duktape {
//   Duktape() {
//     ctx =
//         _bindings.duk_create_heap(nullptr, nullptr, nullptr, nullptr, nullptr);
//   }

//   void evalString(String jsCode) {
//     var nativeUtf8 = jsCode.toNativeUtf8();
//     _bindings.duk_eval_raw(
//         ctx,
//         nativeUtf8.cast<Char>(),
//         0,
//         0 |
//             DUK_COMPILE_EVAL |
//             DUK_COMPILE_SAFE |
//             DUK_COMPILE_NOSOURCE |
//             DUK_COMPILE_STRLEN |
//             DUK_COMPILE_NOFILENAME);
//     ffi.malloc.free(nativeUtf8);
//   }

//   int getInt(int index) {
//     return _bindings.duk_get_int(ctx, index);
//   }

//   void dispose() {
//     _bindings.duk_destroy_heap(ctx);
//     ctx = nullptr;
//   }

//   late Pointer<duk_hthread> ctx;
// }


// import 'dart:async';
// import 'dart:ffi';
// import 'dart:io';
// import 'dart:isolate';

// import 'ffigen_app_bindings_generated.dart';

// /// A very short-lived native function.
// ///
// /// For very short-lived functions, it is fine to call them on the main isolate.
// /// They will block the Dart execution while running the native function, so
// /// only do this for native functions which are guaranteed to be short-lived.
// int sum(int a, int b) => _bindings.sum(a, b);

// /// A longer lived native function, which occupies the thread calling it.
// ///
// /// Do not call these kind of native functions in the main isolate. They will
// /// block Dart execution. This will cause dropped frames in Flutter applications.
// /// Instead, call these native functions on a separate isolate.
// ///
// /// Modify this to suit your own use case. Example use cases:
// ///
// /// 1. Reuse a single isolate for various different kinds of requests.
// /// 2. Use multiple helper isolates for parallel execution.
// Future<int> sumAsync(int a, int b) async {
//   final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
//   final int requestId = _nextSumRequestId++;
//   final _SumRequest request = _SumRequest(requestId, a, b);
//   final Completer<int> completer = Completer<int>();
//   _sumRequests[requestId] = completer;
//   helperIsolateSendPort.send(request);
//   return completer.future;
// }

// const String _libName = 'ffigen_app';

// /// The dynamic library in which the symbols for [FfigenAppBindings] can be found.
// final DynamicLibrary _dylib = () {
//   if (Platform.isMacOS || Platform.isIOS) {
//     return DynamicLibrary.open('$_libName.framework/$_libName');
//   }
//   if (Platform.isAndroid || Platform.isLinux) {
//     return DynamicLibrary.open('lib$_libName.so');
//   }
//   if (Platform.isWindows) {
//     return DynamicLibrary.open('$_libName.dll');
//   }
//   throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
// }();

// /// The bindings to the native functions in [_dylib].
// final FfigenAppBindings _bindings = FfigenAppBindings(_dylib);


// /// A request to compute `sum`.
// ///
// /// Typically sent from one isolate to another.
// class _SumRequest {
//   final int id;
//   final int a;
//   final int b;

//   const _SumRequest(this.id, this.a, this.b);
// }

// /// A response with the result of `sum`.
// ///
// /// Typically sent from one isolate to another.
// class _SumResponse {
//   final int id;
//   final int result;

//   const _SumResponse(this.id, this.result);
// }

// /// Counter to identify [_SumRequest]s and [_SumResponse]s.
// int _nextSumRequestId = 0;

// /// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
// final Map<int, Completer<int>> _sumRequests = <int, Completer<int>>{};

// /// The SendPort belonging to the helper isolate.
// Future<SendPort> _helperIsolateSendPort = () async {
//   // The helper isolate is going to send us back a SendPort, which we want to
//   // wait for.
//   final Completer<SendPort> completer = Completer<SendPort>();

//   // Receive port on the main isolate to receive messages from the helper.
//   // We receive two types of messages:
//   // 1. A port to send messages on.
//   // 2. Responses to requests we sent.
//   final ReceivePort receivePort = ReceivePort()
//     ..listen((dynamic data) {
//       if (data is SendPort) {
//         // The helper isolate sent us the port on which we can sent it requests.
//         completer.complete(data);
//         return;
//       }
//       if (data is _SumResponse) {
//         // The helper isolate sent us a response to a request we sent.
//         final Completer<int> completer = _sumRequests[data.id]!;
//         _sumRequests.remove(data.id);
//         completer.complete(data.result);
//         return;
//       }
//       throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
//     });

//   // Start the helper isolate.
//   await Isolate.spawn((SendPort sendPort) async {
//     final ReceivePort helperReceivePort = ReceivePort()
//       ..listen((dynamic data) {
//         // On the helper isolate listen to requests and respond to them.
//         if (data is _SumRequest) {
//           final int result = _bindings.sum_long_running(data.a, data.b);
//           final _SumResponse response = _SumResponse(data.id, result);
//           sendPort.send(response);
//           return;
//         }
//         throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
//       });

//     // Send the port to the main isolate on which we can receive requests.
//     sendPort.send(helperReceivePort.sendPort);
//   }, receivePort.sendPort);

//   // Wait until the helper isolate has sent us back the SendPort on which we
//   // can start sending requests.
//   return completer.future;
// }();
