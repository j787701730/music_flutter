import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map nowData = {};
  List sevenDayData = [];
  List hoursData = [];
  DateTime _lastQuitTime;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  _getCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // String logs = prefs.getString('logs');
  }

  String value; // 每次input的值
  String allText = ''; // 从本地文件获取的值

  /// 此方法返回本地文件地址
  Future<File> _getLocalFile() async {
    // 获取文档目录的路径
    Directory appDocDir = await getLibraryDirectory();
    String dir = appDocDir.path;
    print(dir);
    var directory = Directory(dir);

    print(directory.listSync());
    // final file = new File('$dir/demo.txt');
    // print(file);
    // return file;
  }

  void _readContent() async {
    File file = await _getLocalFile();
    // 从文件中读取变量作为字符串，一次全部读完存在内存里面
    // String contents = await file.readAsString();
    // setState(() {
    //   allText = contents;
    // });
  }

  _message(val) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Container(
          height: 34,
          alignment: Alignment.center,
          child: Text(val),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          title: Text('音乐播放器'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          children: [
            OutlineButton(
              onPressed: _readContent,
              child: Text('本地文件'),
            )
          ],
        ),
      ),
      onWillPop: () async {
        if (_lastQuitTime == null || DateTime.now().difference(_lastQuitTime).inSeconds > 1) {
          _message('再按一次 Back 按钮退出');
          _lastQuitTime = DateTime.now();
          return false;
        }
        return true;
      },
    );
  }
}
