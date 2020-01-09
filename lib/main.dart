import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_upgrade/r_upgrade.dart';

const version = 1;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int id;
  bool isAutoRequestInstall = false;

  bool isClickHotUpgrade;

  GlobalKey<ScaffoldState> _state = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildMultiPlatformWidget() {
    if (Platform.isAndroid) {
      return _buildAndroidPlatformWidget();
    } else if (Platform.isIOS) {
      return _buildIOSPlatformWidget();
    } else {
      return Container(
        child: Text('Sorry, your platform is not support'),
      );
    }
  }

  Widget _buildIOSPlatformWidget() => ListView(
        children: <Widget>[
          ListTile(
            title: Text('Go to app store'),
            onTap: () async {
              RUpgrade.upgradeFromAppStore(
                'https://mydata-1252536312.cos.ap-guangzhou.myqcloud.com/r_upgrade.apk',
              );
            },
          ),
        ],
      );

  Widget _buildAndroidPlatformWidget() => ListView(
        children: <Widget>[
          _buildDownloadWindow(),
          ListTile(
            title: Text('Atualizar aplicação'),
            onTap: () async {
              if (isClickHotUpgrade != null) {
                _state.currentState.showSnackBar(
                    SnackBar(content: Text('Aplicação já atualizada')));
                return;
              }
              isClickHotUpgrade = false;

              if (!await canReadStorage()) return;

              id = await RUpgrade.upgrade(
                  'http://192.168.0.108/teste/Perfect_Cheff.apk',
                  apkName: 'Perfect_Cheff.apk',
                  isAutoRequestInstall: true);
              setState(() {});
            },
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _state,
        appBar: AppBar(
          backgroundColor:
              version != 1 ? Colors.black : Theme.of(context).primaryColor,
          title: Text(_getAppBarText()),
        ),
        body: _buildMultiPlatformWidget(),
      ),
    );
  }

  String _getAppBarText() {
    switch (version) {
      case 1:
        return 'Normal version = $version';
      case 2:
        return 'hot upgrade version = $version';
      case 3:
        return 'all upgrade version = $version';
    }
    return 'unknow version  = $version';
  }

  Widget _buildDownloadWindow() => Container(
        height: 250,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: id != null
            ? StreamBuilder(
                stream: RUpgrade.stream,
                builder: (BuildContext context,
                    AsyncSnapshot<DownloadInfo> snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                getStatus(snapshot.data.status) ==
                                            'Aguardando download' ||
                                        getStatus(snapshot.data.status) ==
                                            'Baixando atualização'
                                    ? Text(
                                        "${getStatus(snapshot.data.status)} - ${snapshot.data.percent}%")
                                    : Text(
                                        "${getStatus(snapshot.data.status)}"),
                                LinearPercentIndicator(
                                  width: 300,
                                  lineHeight: 12.0,
                                  percent: snapshot.data.percent / 100,
                                  progressColor: Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                                '${snapshot.data.planTime.toStringAsFixed(0)}s'),
                          ],
                        )
                      ],
                    );
                  } else {
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    );
                  }
                },
              )
            : Text('Aguardando download'),
      );

  String getStatus(DownloadStatus status) {
    if (status == DownloadStatus.STATUS_FAILED) {
      id = null;
      isClickHotUpgrade = null;
      return "null";
    } else if (status == DownloadStatus.STATUS_PAUSED) {
      return "Download pausado";
    } else if (status == DownloadStatus.STATUS_PENDING) {
      return "Aguardando download";
    } else if (status == DownloadStatus.STATUS_RUNNING) {
      return "Baixando atualização";
    } else if (status == DownloadStatus.STATUS_SUCCESSFUL) {
      return "Download concluído";
    } else {
      id = null;
      isClickHotUpgrade = null;
      return "未知";
    }
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

  String getSpeech(double speech) {
    String unit = 'kb/s';
    String result = speech.toStringAsFixed(2);
    if (speech > 1024 * 1024) {
      unit = 'gb/s';
      result = (speech / (1024 * 1024)).toStringAsFixed(2);
    } else if (speech > 1024) {
      unit = 'mb/s';
      result = (speech / 1024).toStringAsFixed(2);
    }
    return '$result$unit';
  }
}

class CircleDownloadWidget extends StatelessWidget {
  final double progress;
  final Widget child;

  const CircleDownloadWidget({Key key, this.progress, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: CircleDownloadCustomPainter(
          Colors.grey[400],
          Theme.of(context).primaryColor,
          progress,
        ),
        child: child,
      ),
    );
  }
}

class CircleDownloadCustomPainter extends CustomPainter {
  final Color backgroundColor;
  final Color color;
  final double progress;

  Paint mPaint;

  CircleDownloadCustomPainter(this.backgroundColor, this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (mPaint == null) mPaint = Paint();
    double width = size.width;
    double height = size.height;

    Rect progressRect =
        Rect.fromLTRB(0, height * (1 - progress), width, height);
    Rect widgetRect = Rect.fromLTWH(0, 0, width, height);
    canvas.clipPath(Path()..addOval(widgetRect));

    canvas.drawRect(widgetRect, mPaint..color = backgroundColor);
    canvas.drawRect(progressRect, mPaint..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
