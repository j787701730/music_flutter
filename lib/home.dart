import 'dart:async';
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
  DateTime _lastQuitTime;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AudioPlayer audioPlayer;
  String currPlay = '';
  AudioPlayerState playState;
  StreamSubscription _playerStateSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerCompleteSubscription;
  List musicList = [];
  List dirs = ['/storage/emulated/0/Music/', '/storage/emulated/1/Music/'];

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

  playLocal(path) async {
    _setPlay(path);
    await audioPlayer.play(path, isLocal: true);
  }

  /// 此方法返回本地文件地址
  _getLocalFile() async {
    List arr = [];
    for (var dir in dirs) {
      if (await FileSystemEntity.isDirectory(dir)) {
        Directory directory = Directory(dir);
        if (directory.listSync() is List) {
          directory.listSync().forEach((element) {
            String path = element.path;
            if (['mp3'].contains(path.substring(path.lastIndexOf('.') + 1))) {
              arr.add(element.path);
            }
          });
        }
      }
    }
    if (arr.isEmpty) {
      _message('音乐文件放在手机存储或SD卡的Music下');
    } else {
      if (!mounted) return;
      setState(() {
        musicList = arr;
      });
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

  _playNext() {
    if (!mounted) return;
    int index = musicList.indexOf(currPlay);
    if (index != musicList.length - 1) {
      setState(() {
        currPlay = musicList[index + 1];
        playLocal(musicList[index + 1]);
      });
    } else if (musicList.isNotEmpty) {
      setState(() {
        currPlay = musicList[0];
        playLocal(musicList[0]);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _getLocalFile();
    _getPlay();

    // 播放状态
    _playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      // print('Current player state: $s');
      if (!mounted) return;
      setState(() {
        playState = s;
      });
    });
    //
    _playerCompleteSubscription = audioPlayer.onPlayerCompletion.listen((event) {
      _playNext();
    });

    // 错误事件
    _playerErrorSubscription = audioPlayer.onPlayerError.listen((msg) {
      // print('audioPlayer error: $msg');
      _message('$msg');
      _playNext();
    });
  }

  @override
  void deactivate() {
    audioPlayer.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _playerStateSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          title: Text('${musicList.length > 0 ? ' 共${musicList.length}首' : ''}'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                playState == null
                    ? Icons.play_arrow_outlined
                    : playState == AudioPlayerState.PLAYING
                        ? Icons.pause
                        : Icons.play_arrow_outlined,
              ),
              onPressed: () {
                if (playState == AudioPlayerState.PLAYING) {
                  audioPlayer.pause();
                } else if (playState == AudioPlayerState.PAUSED) {
                  audioPlayer.resume();
                } else {
                  if (musicList.isNotEmpty) {
                    if (musicList.contains(currPlay)) {
                      playLocal(currPlay);
                    } else {
                      playLocal(musicList[0]);
                    }
                  } else {
                    _message('无歌曲可播放');
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh_outlined),
              onPressed: _getLocalFile,
            ),
          ],
        ),
        body: ListView.builder(
          itemBuilder: (context, index) {
            String path = musicList[index];
            return ListTile(
              onTap: () {
                playLocal(path);
                setState(() {
                  currPlay = path;
                });
              },
              title: Text(
                '${path.substring(path.lastIndexOf('/') + 1)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: SizedBox(
                width: 48,
                child: currPlay == path
                    ? IconButton(
                        icon: Icon(
                          playState == null
                              ? Icons.play_arrow_outlined
                              : playState == AudioPlayerState.PLAYING
                                  ? Icons.pause
                                  : Icons.play_arrow_outlined,
                          color: Color(0xff000000),
                        ),
                        onPressed: () {
                          if (playState == AudioPlayerState.PLAYING) {
                            audioPlayer.pause();
                          } else if (playState == AudioPlayerState.PAUSED) {
                            audioPlayer.resume();
                          } else {
                            playLocal(path);
                          }
                        },
                      )
                    : SizedBox(),
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
