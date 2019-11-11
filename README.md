# r_scan

A flutter plugin about qr code scan.

## Getting Started

###  Depend on it

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  r_scan: ^0.0.1
```
1.scan Image File

```dart

final result=await RScan.scanImagePath('your file path');

```

2.scan Image url

```dart

final result=await RScan.scanImagePath('your image url');

```

3.scan Image memory

```dart

 ByteData data=await rootBundle.load('images/qrCode.png');
 final result=await RScan.scanImageMemory(data.buffer.asUint8List());

```

4.scan view

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