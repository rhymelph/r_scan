// Copyright 2019 The rhyme_lph Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// qr scan
class RScan {
  static const MethodChannel _channel = const MethodChannel('r_scan');

  /// scan qr image in path
  ///
  /// [path] your qr image path
  ///
  /// It will return your scan result.if not found qr,will return empty.
  static Future<RScanResult> scanImagePath(String path) async =>
      RScanResult.formMap(await _channel.invokeMethod('scanImagePath', {
        "path": path,
      }));

  /// scan qr image in url
  ///
  /// [url] your qr image url
  ///
  /// It will return your scan result.if not found qr,will return empty.
  static Future<RScanResult> scanImageUrl(String url) async =>
      RScanResult.formMap(await _channel.invokeMethod('scanImageUrl', {
        "url": url,
      }));

  /// scan qr image in memory
  ///
  /// [uint8list] your qr image memory
  ///
  /// It will return your scan result.if not found qr,will return empty.
  static Future<RScanResult> scanImageMemory(Uint8List uint8list) async =>
      RScanResult.formMap(await _channel.invokeMethod('scanImageMemory', {
        "uint8list": uint8list,
      }));
}

const scanViewType = 'com.rhyme/r_scan_view';

typedef void ScanResultCallback(String result);

/// qr scan view , it need to  require camera permission.
class RScanView extends StatefulWidget {
  final RScanController controller;

  const RScanView({this.controller}) : assert(controller != null);

  @override
  State<StatefulWidget> createState() => _RScanViewState();
}

class _RScanViewState extends State<RScanView> {
  RScanController _controller;

  void onPlatformViewCreated(int id) {
    _controller.attach(id);
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RScanController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.detach();
  }

  @override
  Widget build(BuildContext context) {
    dynamic params = {
      "isPlay": _controller.isPlay,
    };
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: scanViewType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: params,
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: scanViewType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: params,
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      return Container(
        child: Text('Not support ${Platform.operatingSystem} platform.'),
      );
    }
  }
}

/// qr scan view controller .
/// can startScan or stopScan .
class RScanController extends ChangeNotifier {
  Stream _stream;
  StreamSubscription _subscription;
  RScanResult result;
  EventChannel _channel;
  bool isPlay;
  MethodChannel _methodChannel;

  RScanController({this.isPlay: true})
      : assert(isPlay != null),
        super();

  void attach(int id) {
    _channel = EventChannel('r_scan/${scanViewType}_$id/event');
    _methodChannel = MethodChannel('r_scan/${scanViewType}_$id/method');
    _stream = _channel.receiveBroadcastStream(
      {
        "isPlay": isPlay,
      },
    );
    _subscription = _stream.listen((data) {
      this.result = RScanResult.formMap(data);
      notifyListeners();
    });
  }

  //开始扫描
  Future<void> startScan() async {
    await _methodChannel.invokeMethod('startScan');
  }

  //停止扫描
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stopScan');
  }

  /// flash mode open or close.
  ///
  /// [isOpen] if false will close flash mode.
  ///
  /// It will return is success.
  Future<bool> setFlashMode(bool isOpen) async =>
      await _methodChannel.invokeMethod('setFlashMode', {
        'isOpen': isOpen,
      });

  /// flash mode open or close.
  ///
  /// [isOpen] if false will close flash mode.
  ///
  /// It will return is success.
  Future<bool> getFlashMode() async =>
      await _methodChannel.invokeMethod('getFlashMode');

  void detach() {
    _subscription?.cancel();
    notifyListeners();
  }
}

/// barcode type
enum RScanBarType {
  azetc,
  codabar, // ios not found
  code_39,
  code_93,
  code_128,
  data_matrix,
  ean_8,
  ean_13, // ios include upc_a
  itf,
  maxicode, // ios not found
  pdf_417,
  qr_code,
  rss_14, // ios not found
  rss_expanded, // ios not found
  upc_a, // ios not found
  upc_e,
  upc_ean_extension, // ios not found
}

/// barcode point
class RScanPoint {
  /// barcode point x
  final double x;

  /// barcode point y
  final double y;

  RScanPoint(this.x, this.y);

  @override
  String toString() {
    return 'RScanPoint{x: $x, y: $y}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RScanPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// scan result
class RScanResult {
  /// barcode type
  final RScanBarType type;

  ///barcode message
  final String message;

  ///barcode points
  final List<RScanPoint> points;


  const RScanResult({this.type, this.message, this.points});

  factory RScanResult.formMap(Map map) {
    return map == null
        ? null
        : RScanResult(
            type: map['type'] != null
                ? RScanBarType.values[map['type'] as int]
                : null,
            message: map['message'] as String,
            points: map['points'] != null
                ? (map['points'] as List)
                    .map(
                      (data) => RScanPoint(
                        data['X'],
                        data['Y'],
                      ),
                    )
                    .toList()
                : null,
          );
  }

  @override
  String toString() {
    return 'RScanResult{type: $type, message: $message, points: $points}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RScanResult &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          points == other.points;

  @override
  int get hashCode =>
      type.hashCode ^ message.hashCode ^ points.hashCode;
}
