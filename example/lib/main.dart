import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_scan_example/scan_dialog.dart';
import 'scan_camera_dialog.dart';
import 'package:r_scan/r_scan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPage(),
    );
  }
}

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  RScanResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('scan example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
              child: Text(result == null
                  ? '点击下方按钮开始扫码'
                  : '扫码结果${result.toString().split(',').join('\n')}')),
          Center(
            child: FlatButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            RScanCameraDialog()));
                setState(() {
                  this.result = result;
                });
              },
              child: Text('RScanCamera开始扫码'),
            ),
          ),
          Center(
            child: FlatButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context) => RScanDialog()));
                setState(() {
                  this.result = result;
                });
              },
              child: Text('RScanView开始扫码(已弃用)'),
            ),
          ),
          Center(
            child: FlatButton(
              onPressed: () async {
                if (await canReadStorage()) {
                  var image =
                      await ImagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final result = await RScan.scanImagePath(image.path);
                    setState(() {
                      this.result = result;
                    });
                  }
                }
              },
              child: Text('选择图片扫描'),
            ),
          ),
          Center(
            child: FlatButton(
              onPressed: () async {
                final result = await RScan.scanImageUrl(
                    "https://s.cn.bing.net/th?id=OJ.5F0gxqWmxskS0Q&w=75&h=75&pid=MSNJVFeeds");
                setState(() {
                  this.result = result;
                });
              },
              child: Text('网络图片解析'),
            ),
          ),
          Center(
            child: FlatButton(
              onPressed: () async {
                ByteData data = await rootBundle.load('images/qrCode.png');
                final result =
                    await RScan.scanImageMemory(data.buffer.asUint8List());
                setState(() {
                  this.result = result;
                });
              },
              child: Text('内存图片解析'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> canReadStorage() async {
    if (Platform.isIOS) return true;
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
}
