# r_scan
[![pub package](https://img.shields.io/pub/v/r_scan.svg)](https://pub.dartlang.org/packages/r_scan)

![](screen/r_scan.png)

A flutter plugin about qr code or bar code scan , it can scan from file、url、memory and camera qr code or bar code .Welcome to feedback your issue.

## Getting Started

###  Depend on it

Add this to your package's pubspec.yaml file:
```yaml
dependencies:
  r_scan: last version
```

### Android Platform
require `read storage permission` and `camera permission`, use `permission_handler` plugin.
```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> canReadStorage() async {
    if(Platform.isIOS) return true;
    var status = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (status != PermissionStatus.granted) {
      var future = await PermissionHandler()
          .requestPermissions([PermissionGroup.storage]);
      for (final item in future.entries) {
        if (item.value != PermissionStatus.granted) {
          return false;
        }
      }
    } else {
      return true;
    }
    return true;
  }

Future<bool> canOpenCamera() async {
    var status =
        await PermissionHandler().checkPermissionStatus(PermissionGroup.camera);
    if (status != PermissionStatus.granted) {
      var future = await PermissionHandler()
          .requestPermissions([PermissionGroup.camera]);
      for (final item in future.entries) {
        if (item.value != PermissionStatus.granted) {
          return false;
        }
      }
    } else {
      return true;
    }
    return true;
  }
```

### IOS Platform
add the permissions in your Info.plist
```plist
    <key>NSCameraUsageDescription</key>
	<string>扫描二维码时需要使用您的相机</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>扫描二维码时需要访问您的相册</string>
	<key>io.flutter.embedded_views_preview</key>
    <true/>
```
no another.


## Usage
### 1.scan Image File

```dart

final result=await RScan.scanImagePath('your file path');

```

### 2.scan Image url

```dart

final result=await RScan.scanImagePath('your image url');

```

### 3.scan Image memory

```dart

 ByteData data=await rootBundle.load('images/qrCode.png');
 final result=await RScan.scanImageMemory(data.buffer.asUint8List());

```

### 4.scan camera(new! please upgrade this plugin to v0.1,4)

- Step First: Get available cameras
```dart
List<RScanCameraDescription> rScanCameras = await availableRScanCameras();;
```
if you want to get it in main() method, you can use this code.
```dart
List<RScanCameraDescription> rScanCameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  rScanCameras = await availableRScanCameras();
  runApp(...);
}
```
- Step Second:Use it.
```dart
class RScanCameraDialog extends StatefulWidget {
  @override
  _RScanCameraDialogState createState() => _RScanCameraDialogState();
}

class _RScanCameraDialogState extends State<RScanCameraDialog> {
  RScanCameraController _controller;
  bool isFirst = true;

  @override
  void initState() {
    super.initState();
    if (rScanCameras != null && rScanCameras.length > 0) {
      _controller = RScanCameraController(
          rScanCameras[1], RScanCameraResolutionPreset.max)
        ..addListener(() {
          final result = _controller.result;
          if (result != null) {
            if (isFirst) {
              Navigator.of(context).pop(result);
              isFirst = false;
            }
          }
        })
        ..initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (rScanCameras == null || rScanCameras.length == 0) {
      return Scaffold(
        body: Container(
          alignment: Alignment.center,
          child: Text('not have available camera'),
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          ScanImageView(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: RScanCamera(_controller),
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: FutureBuilder(
                future: getFlashMode(),
                builder: _buildFlashBtn,
              ))
        ],
      ),
    );
  }
  Future<bool> getFlashMode() async {
    bool isOpen = false;
    try {
      isOpen = await _controller.getFlashMode();
    } catch (_) {}
    return isOpen;
  }

  Widget _buildFlashBtn(BuildContext context, AsyncSnapshot<bool> snapshot) {
    return snapshot.hasData
        ? Padding(
      padding:  EdgeInsets.only(bottom:24+MediaQuery.of(context).padding.bottom),
      child: IconButton(
          icon: Icon(snapshot.data ? Icons.flash_on : Icons.flash_off),
          color: Colors.white,
          iconSize: 46,
          onPressed: () {
            if (snapshot.data) {
              _controller.setFlashMode(false);
            } else {
              _controller.setFlashMode(true);
            }
            setState(() {});
          }),
    )
        : Container();
  }
}
```

### 5.scan view(Deprecated)

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_scan/r_scan.dart';

class RScanDialog extends StatefulWidget {
  @override
  _RScanDialogState createState() => _RScanDialogState();
}

class _RScanDialogState extends State<RScanDialog> {
  RScanController _controller;

  @override
  void initState() {
    super.initState();
    initController();
  }
  bool isFirst=true;


  Future<void> initController() async {
    _controller = RScanController();
    _controller.addListener(() {

      final result = _controller.result;
      if (result != null) {
        if(isFirst){
          Navigator.of(context).pop(result);
          isFirst=false;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<bool>(
          future: canOpenCameraView(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return ScanImageView(
                child: RScanView(
                  controller: _controller,
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }

  Future<bool> canOpenCameraView() async {
    var status =
        await PermissionHandler().checkPermissionStatus(PermissionGroup.camera);
    if (status != PermissionStatus.granted) {
      var future = await PermissionHandler()
          .requestPermissions([PermissionGroup.camera]);
      for (final item in future.entries) {
        if (item.value != PermissionStatus.granted) {
          return false;
        }
      }
    } else {
      return true;
    }
    return true;
  }
}

```

### 6. open flash lamp / get flash lamp status.
You can use `RScanController` class.
```dart
//turn off the flash lamp.
await _controller.setFlashMode(false);

//turn on the flash lamp.
await _controller.setFlashMode(true);

// get the flash lamp status.

bool isOpen = await _controller.getFlashMode();

```

### 7. RScanResult

when you scan finish,will return the RScanResult...

```dart
class RScanResult {
  /// barcode type
  final RScanBarType type;

  ///barcode message
  final String message;

  ///barcode points include [x , y]
  final List<RScanPoint> points;
}

```
