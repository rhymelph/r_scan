// Copyright 2019 The rhyme_lph Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../r_scan.dart';

const _scanType = 'com.rhyme_lph/r_scan_view';

typedef void ScanResultCallback(String result);

/// qr scan view , it need to  require camera permission.
@Deprecated("please use 'RScanCamera'")
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
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
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
    Widget child;
    if (Platform.isAndroid) {
      child = AndroidView(
        viewType: _scanType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: params,
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      child = UiKitView(
        viewType: _scanType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: params,
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      child = Container(
        child: Text('Not support ${Platform.operatingSystem} platform.'),
      );
    }

    return child;
  }
}

/// qr scan view controller .
/// can startScan or stopScan .
@Deprecated("please use 'RScanCameraController'")
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
    _channel = EventChannel('${_scanType}_$id/event');
    _methodChannel = MethodChannel('${_scanType}_$id/method');
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
