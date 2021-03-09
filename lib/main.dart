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
        title: '本地音乐播发器墨水屏版',
        themeMode: ThemeMode.light,
        theme: ThemeData(
          // primarySwatch: Colors.blue,
          primaryColor: Colors.white,
          brightness: Brightness.light,
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
          ),
          appBarTheme: AppBarTheme(
            brightness: Brightness.light,
            // textTheme: TextTheme(
            //   headline6: TextStyle(
            //     fontSize: 18,
            //     color: Colors.black,
            //   ),
            // ),
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
            selectedItemColor: Colors.blue,
            unselectedItemColor: Color(0xff333333),
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
            elevation: 1,
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
