// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'common.dart';
import '_extension_io.dart' if (dart.library.html) '_extension_web.dart';

/// A subclass of [LiveTestWidgetsFlutterBinding] that reports tests results
/// on a channel to adapt them to native instrumentation test format.
class E2EWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding {
  /// Sets up a listener to report that the tests are finished when everything is
  /// torn down.
  E2EWidgetsFlutterBinding() {
    // TODO(jackson): Report test results as they arrive
    tearDownAll(() async {
      try {
        // For web integration tests we are not using the
        // `plugins.flutter.io/e2e`. Mark the tests as complete before invoking
        // the channel.
        if (kIsWeb) {
          if (!_allTestsPassed.isCompleted) {
            _allTestsPassed.complete(true);
          }
        }
        await _channel.invokeMethod<void>(
          'allTestsFinished',
          <String, dynamic>{'results': results},
        );
      } on MissingPluginException {
        print('Warning: E2E test plugin was not detected.');
      }
      if (!_allTestsPassed.isCompleted) _allTestsPassed.complete(true);
    });

    // TODO(jackson): Report the results individually instead of all at once
    // See https://github.com/flutter/flutter/issues/38985
    final TestExceptionReporter oldTestExceptionReporter = reportTestException;
    reportTestException =
        (FlutterErrorDetails details, String testDescription) {
      results[testDescription] = 'failed';
      _failureMethodsDetails.add(Failure(testDescription, details.toString()));
      if (!_allTestsPassed.isCompleted) {
        _allTestsPassed.complete(false);
      }
      oldTestExceptionReporter(details, testDescription);
    };
  }

  // TODO(dnfield): Remove the ignore once we bump the minimum Flutter version
  // ignore: override_on_non_overriding_member
  @override
  bool get overrideHttpClient => false;

  // TODO(dnfield): Remove the ignore once we bump the minimum Flutter version
  // ignore: override_on_non_overriding_member
  @override
  bool get registerTestTextInput => false;

  Size _surfaceSize;

  /// Artificially changes the surface size to `size` on the Widget binding,
  /// then flushes microtasks.
  ///
  /// Set to null to use the default surface size.
  @override
  Future<void> setSurfaceSize(Size size) {
    return TestAsyncUtils.guard<void>(() async {
      assert(inTest);
      if (_surfaceSize == size) {
        return;
      }
      _surfaceSize = size;
      handleMetricsChanged();
    });
  }

  @override
  ViewConfiguration createViewConfiguration() {
    final double devicePixelRatio = window.devicePixelRatio;
    final Size size = _surfaceSize ?? window.physicalSize / devicePixelRatio;
    return TestViewConfiguration(
      size: size,
      window: window,
    );
  }

  final Completer<bool> _allTestsPassed = Completer<bool>();

  /// Stores failure details.
  ///
  /// Failed test method's names used as key.
  final List<Failure> _failureMethodsDetails = List<Failure>();

  /// Similar to [WidgetsFlutterBinding.ensureInitialized].
  ///
  /// Returns an instance of the [E2EWidgetsFlutterBinding], creating and
  /// initializing it if necessary.
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) {
      E2EWidgetsFlutterBinding();
    }
    assert(WidgetsBinding.instance is E2EWidgetsFlutterBinding);
    return WidgetsBinding.instance;
  }

  static const MethodChannel _channel = MethodChannel('plugins.flutter.io/e2e');

  /// Test results that will be populated after the tests have completed.
  ///
  /// Keys are the test descriptions, and values are either `success` or
  /// `failed`.
  @visibleForTesting
  Map<String, String> results = <String, String>{};

  /// The extra data for the reported result.
  ///
  /// The values in `reportData` must be json-serializable objects or `null`.
  /// If it's `null`, no extra data is attached to the result.
  ///
  /// The default value is `null`.
  Map<String, dynamic> reportData;

  /// the callback function to response the driver side input.
  @visibleForTesting
  Future<Map<String, dynamic>> callback(Map<String, String> params) async {
    final String command = params['command'];
    Map<String, String> response;
    switch (command) {
      case 'request_data':
        final bool allTestsPassed = await _allTestsPassed.future;
        response = <String, String>{
          'message': allTestsPassed
              ? Response.allTestsPassed(data: reportData).toJson()
              : Response.someTestsFailed(
                  _failureMethodsDetails,
                  data: reportData,
                ).toJson(),
        };
        break;
      case 'get_health':
        response = <String, String>{'status': 'ok'};
        break;
      default:
        throw UnimplementedError('$command is not implemented');
    }
    return <String, dynamic>{
      'isError': false,
      'response': response,
    };
  }

  // Emulates the Flutter driver extension, returning 'pass' or 'fail'.
  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    if (kIsWeb) {
      registerWebServiceExtension(callback);
    }

    registerServiceExtension(name: 'driver', callback: callback);
  }

  @override
  Future<void> runTest(
    Future<void> testBody(),
    VoidCallback invariantTester, {
    String description = '',
    Duration timeout,
  }) async {
    await super.runTest(
      testBody,
      invariantTester,
      description: description,
      timeout: timeout,
    );
    results[description] ??= 'success';
  }
}
