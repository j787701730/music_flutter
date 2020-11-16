import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  AudioPlayer audioPlayer;
  String currPlay = '';
  AudioPlayerState playState;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _getLocalFile();
    _getPlay();
    // 音频长度
    // audioPlayer.onDurationChanged.listen((Duration d) {
    //   print('Max duration: $d');
    //   // setState(() => duration = d);
    // });

    //  位置事件
    // audioPlayer.onAudioPositionChanged.listen((Duration  p){
    // print('Current position: $p');
    //   setState(() => position = p);
    // });

    // 播放状态
    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      // print('Current player state: $s');
      if (s == AudioPlayerState.COMPLETED) {
        int index = musicList.indexOf(currPlay);
        if (index != musicList.length - 1) {
          setState(() {
            currPlay = musicList[index + 1];
            playLocal(musicList[index + 1]);
          });
        } else {
          setState(() {
            currPlay = musicList[0];
            playLocal(musicList[0]);
          });
        }
      }
      setState(() {
        playState = s;
      });
    });
    //
    // audioPlayer.onPlayerCompletion.listen((event) {
    //   // onComplete();
    //   // setState(() {
    //   //   position = duration;
    //   // });
    // });

    // 错误事件
    audioPlayer.onPlayerError.listen((msg) {
      // print('audioPlayer error : $msg');
      _message('$msg');
    });
  }

  _getPlay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastPlaySong = prefs.getString('lastPlaySong');
    if (lastPlaySong != null) {
      setState(() {
        currPlay = lastPlaySong;
      });
    }
  }

  _setPlay(path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastPlaySong', path);
  }

  List musicList = [];

  playLocal(path) async {
    _setPlay(path);
    await audioPlayer.play(path, isLocal: true);
  }

  /// 此方法返回本地文件地址
  Future<File> _getLocalFile() async {
    try {
      Directory directory = Directory('/storage/emulated/0/Music/');
      if (directory.listSync() is List) {
        List arr = [];
        directory.listSync().forEach((element) {
          String path = element.path;
          if (['mp3'].contains(path.substring(path.lastIndexOf('.') + 1))) {
            arr.add(element.path);
          }
        });
        setState(() {
          musicList = arr;
        });
      }
    } catch (error) {
      setState(() {
        musicList = [];
      });
      _message('读取不到/storage/emulated/0/Music/');
    }
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
  void dispose() {
    super.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          title: Text('音乐播放器${musicList.length > 0 ? ' 共${musicList.length}首' : ''}'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_outlined),
              onPressed: _getLocalFile,
            ),
          ],
        ),
        body: ListView.builder(
          itemBuilder: (context, index) {
            String path = musicList[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                playLocal(path);
                setState(() {
                  currPlay = path;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xffdddddd),
                    ),
                  ),
                ),
                height: 45,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          '${path.substring(path.lastIndexOf('/') + 1)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      width: 44,
                      child: currPlay == path
                          ? GestureDetector(
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: Icon(
                                    playState == AudioPlayerState.PLAYING ? Icons.play_arrow_outlined : Icons.pause),
                              ),
                              onTap: () {
                                if (playState == AudioPlayerState.PLAYING) {
                                  audioPlayer.pause();
                                } else {
                                  audioPlayer.resume();
                                }
                              },
                            )
                          : Container(),
                    )
                  ],
                ),
              ),
            );
          },
          itemCount: musicList.length,
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
