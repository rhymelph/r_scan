// Copyright 2019 The rhyme_lph Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:r_scan/r_scan.dart';

const _scanType = 'com.rhyme_lph/r_scan_camera';
final MethodChannel _channel = const MethodChannel('$_scanType/method');

Future<List<RScanCameraDescription>> availableRScanCameras() async {
  try {
    final List<Map<dynamic, dynamic>> cameras = await _channel
        .invokeListMethod<Map<dynamic, dynamic>>('availableCameras');
    return cameras.map((Map<dynamic, dynamic> camera) {
      return RScanCameraDescription(
        name: camera['name'],
        lensDirection: _parseCameraLensDirection(camera['lensFacing']),
      );
    }).toList();
  } on PlatformException catch (e) {
    throw RScanCameraException(e.code, e.message);
  }
}

class RScanCameraController extends ValueNotifier<RScanCameraValue> {
  final RScanCameraDescription description;
  final RScanCameraResolutionPreset resolutionPreset;
  RScanResult result; // qr code result
  int _textureId; // init finish will return id
  bool _isDisposed = false; // when the widget dispose will set true
  Completer<void> _creatingCompleter; // when the camera create finish
  StreamSubscription<dynamic> _resultSubscription; //the result subscription

  RScanCameraController(this.description, this.resolutionPreset)
      : super(const RScanCameraValue.uninitialized());

  Future<void> initialize() async {
    if (_isDisposed) return Future<void>.value();

    _creatingCompleter = Completer<void>();

    try {
      final Map<String, dynamic> reply =
          await _channel.invokeMapMethod('initialize', <String, dynamic>{
        'cameraName': description.name,
        'resolutionPreset': _serializeResolutionPreset(resolutionPreset),
      });
      _textureId = reply['textureId'];
      value = value.copyWith(
          isInitialized: true,
          previewSize: Size(reply['previewWidth'].toDouble(),
              reply['previewHeight'].toDouble()));
      _resultSubscription = EventChannel('${_scanType}_$_textureId/event')
          .receiveBroadcastStream()
          .listen(_handleResult);
    } on PlatformException catch (e) {
      //当发生权限问题的异常时会抛出
      throw RScanCameraException(e.code, e.message);
    }
    _creatingCompleter.complete();
    return _creatingCompleter.future;
  }

  //处理返回值
  void _handleResult(event) {
    if (_isDisposed) return;
    this.result = RScanResult.formMap(event);
    notifyListeners();
  }

  //开始扫描
  Future<void> startScan() async {
    await _channel.invokeMethod('startScan');
  }

  //停止扫描
  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  /// flash mode open or close.
  ///
  /// [isOpen] if false will close flash mode.
  ///
  /// It will return is success.
  Future<bool> setFlashMode(bool isOpen) async =>
      await _channel.invokeMethod('setFlashMode', {
        'isOpen': isOpen,
      });

  /// flash mode open or close.
  ///
  /// [isOpen] if false will close flash mode.
  ///
  /// It will return is success.
  Future<bool> getFlashMode() async =>
      await _channel.invokeMethod('getFlashMode');

  /// flash auto open when brightness value less then 600.
  ///
  /// [isAuto] auto
  Future<bool> setAutoFlashMode(bool isAuto) async =>
      await _channel.invokeMethod('setAutoFlashMode', {
        'isAuto': isAuto,
      });

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    super.dispose();
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      await _channel.invokeMethod('dispose', <String, dynamic>{
        'textureId': _textureId,
      });
      await _resultSubscription?.cancel();
    }
  }
}

/// camera value info
class RScanCameraValue {
  final bool isInitialized;
  final String errorDescription;
  final Size previewSize;

  const RScanCameraValue(
      {this.isInitialized, this.errorDescription, this.previewSize});

  const RScanCameraValue.uninitialized()
      : this(
          isInitialized: false,
        );

  double get aspectRatio => previewSize.height / previewSize.width;

  bool get hasError => errorDescription != null;

  RScanCameraValue copyWith({
    bool isInitialized,
    String errorDescription,
    Size previewSize,
  }) {
    return RScanCameraValue(
      isInitialized: isInitialized ?? this.isInitialized,
      errorDescription: errorDescription ?? this.errorDescription,
      previewSize: previewSize ?? this.previewSize,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription, '
        'previewSize: $previewSize)';
  }
}

class RScanCamera extends StatelessWidget {
  final RScanCameraController controller;

  const RScanCamera(this.controller, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return controller.value.isInitialized
        ? Texture(textureId: controller._textureId)
        : Container();
  }
}

/// camera description
class RScanCameraDescription {
  RScanCameraDescription({
    this.name,
    this.lensDirection,
  });

  final String name;
  final RScanCameraLensDirection lensDirection;

  @override
  bool operator ==(Object o) {
    return o is RScanCameraDescription &&
        o.name == name &&
        o.lensDirection == lensDirection;
  }

  @override
  int get hashCode {
    return hashValues(name, lensDirection);
  }

  @override
  String toString() {
    return '$runtimeType($name, $lensDirection)';
  }
}

/// camera lens direction
enum RScanCameraLensDirection { front, back, external }

RScanCameraLensDirection _parseCameraLensDirection(String string) {
  switch (string) {
    case 'front':
      return RScanCameraLensDirection.front;
    case 'back':
      return RScanCameraLensDirection.back;
    case 'external':
      return RScanCameraLensDirection.external;
  }
  throw ArgumentError('Unknown CameraLensDirection value');
}

/// Affect the quality of video recording and image capture:
///
/// If a preset is not available on the camera being used a preset of lower quality will be selected automatically.
enum RScanCameraResolutionPreset {
  /// 352x288 on iOS, 240p (320x240) on Android
  low,

  /// 480p (640x480 on iOS, 720x480 on Android)
  medium,

  /// 720p (1280x720)
  high,

  /// 1080p (1920x1080)
  veryHigh,

  /// 2160p (3840x2160)
  ultraHigh,

  /// The highest resolution available.
  max,
}

/// Returns the resolution preset as a String.
String _serializeResolutionPreset(
    RScanCameraResolutionPreset resolutionPreset) {
  switch (resolutionPreset) {
    case RScanCameraResolutionPreset.max:
      return 'max';
    case RScanCameraResolutionPreset.ultraHigh:
      return 'ultraHigh';
    case RScanCameraResolutionPreset.veryHigh:
      return 'veryHigh';
    case RScanCameraResolutionPreset.high:
      return 'high';
    case RScanCameraResolutionPreset.medium:
      return 'medium';
    case RScanCameraResolutionPreset.low:
      return 'low';
  }
  throw ArgumentError('Unknown ResolutionPreset value');
}

/// exception
class RScanCameraException implements Exception {
  RScanCameraException(this.code, this.description);

  String code;
  String description;

  @override
  String toString() => '$runtimeType($code, $description)';
}
