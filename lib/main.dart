import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flutter/home.dart';

void main() {
  runApp(MyApp());
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(statusBarColor: Colors.white);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      child: MaterialApp(
        title: '本地音乐播放器墨水屏版',
        themeMode: ThemeMode.light,
        theme: ThemeData(
          // primarySwatch: Colors.blue,
          primaryColor: Colors.white,
          brightness: Brightness.light,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          // cupertinoOverrideTheme: CupertinoThemeData(
          //   brightness: Brightness.light,
          // ),
          platform: TargetPlatform.android,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.white,
          textTheme: TextTheme(
            bodyText2: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
            subtitle1: TextStyle(
              fontSize: 14,
            ),
          ),
          appBarTheme: AppBarTheme(
            brightness: Brightness.light,
            textTheme: TextTheme(
              headline6: TextStyle(
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedIconTheme: IconThemeData(
              size: 20,
            ),
            unselectedIconTheme: IconThemeData(
              size: 20,
            ),
            selectedItemColor: Color(0xff000000),
            unselectedItemColor: Color(0xff999999),
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
          ),
        ),
        home: MyHomePage(title: '本地音乐播发器墨水屏版'),
        debugShowCheckedModeBanner: false,
        routes: <String, WidgetBuilder>{
          '/home': (_) => MyHomePage(),
        },
      ),
      value: SystemUiOverlayStyle.dark,
    );
  }
}
