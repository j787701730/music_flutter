import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gbk2utf8/gbk2utf8.dart';
import 'package:path_provider/path_provider.dart';
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
  DateTime _dateTime;
  int _duration = 0;

  // 读取播放歌曲的记录
  _getPlay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastPlaySong = prefs.getString('lastPlaySong');
    if (lastPlaySong != null) {
      setState(() {
        currPlay = lastPlaySong;
      });
    }
  }

  // 保存当前播放歌曲的记录
  _setPlay(path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastPlaySong', path);
  }

  // 播放歌曲
  playLocal(path) async {
    _setPlay(path);
    setState(() {
      currPlay = path;
    });
    await audioPlayer.play(path, isLocal: true);
  }

  // 获取mp3文件信息
  _getMp3Info(path) {
    final file = new File(path);
    print(path);
    List mp3Bytes = file.readAsBytesSync();
    var _header = mp3Bytes.sublist(mp3Bytes.length - 128, mp3Bytes.length);
    var _tag = _header.sublist(0, 3);
    Map metaTags = {};

    if (latin1.decode(_tag).toLowerCase() == 'tag') {
      // metaTags['Version'] = '1.0';
      var _title = _header.sublist(3, 33);
      var _artist = _header.sublist(33, 63);
      var _album = _header.sublist(63, 93);
      var _year = _header.sublist(93, 97);
      var _comment = _header.sublist(97, 127);
      // var _genre = _header[127];
      // print(utf8.decode(_title));
      metaTags['Title'] = gbk.decode(_title).trim();
      metaTags['Artist'] = gbk.decode(_artist).trim();
      metaTags['Album'] = gbk.decode(_album).trim();
      metaTags['Year'] = gbk.decode(_year).trim();
      metaTags['Comment'] = gbk.decode(_comment).trim();
      // metaTags['Genre'] = GENREv1[_genre];
      metaTags.forEach((key, value) {
        print(value);
      });
      return true;
    }
  }

  /// 此方法返回本地文件地址
  _getLocalFile() async {
    List arr = [];
    List<Directory> a = await getExternalStorageDirectories();
    for (var o in a) {
      String dir = o.path.substring(0, o.path.indexOf('Android')) + 'Music/';
      if (await FileSystemEntity.isDirectory(dir)) {
        Directory directory = Directory(dir);
        if (directory.listSync() is List) {
          directory.listSync().forEach((element) {
            String path = element.path;
            if (['mp3'].contains(path.substring(path.lastIndexOf('.') + 1))) {
              if (!arr.contains(element.path)) {
                arr.add(element.path);
                // _getMp3Info(path);
              }
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

  // 提示信息
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

  // 获取下一首歌曲
  String _getNext() {
    int index = musicList.indexOf(currPlay);
    if (index != musicList.length - 1) {
      return musicList[index + 1];
    } else {
      return musicList[0];
    }
  }

  // 播放下一首
  _playNext() {
    playLocal(_getNext());
  }

  // 在点击播放时判断是否超时长了, 超则时长改为0
  _durationCheck() {
    if (_duration != 0 && DateTime.now().difference(_dateTime).inMinutes >= _duration) {
      setState(() {
        _duration = 0;
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
      // print('Current player state: $s ');
      if (!mounted) return;
      setState(() {
        playState = s;
      });
    });
    // 播放成功
    _playerCompleteSubscription = audioPlayer.onPlayerCompletion.listen((event) {
      // 操过时长后关闭
      if (_duration != 0 && DateTime.now().difference(_dateTime).inMinutes >= _duration) {
        audioPlayer.pause();
        if (!mounted) return;
        String path = _getNext();
        _setPlay(path);
        setState(() {
          currPlay = path;
          _duration = 0;
        });
      } else {
        _playNext();
      }
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
          title: Text(
              '${musicList.length > 0 ? ' 共${musicList.length}首歌曲' : ''} ${_duration == 0 ? '' : '定时$_duration分钟'}'),
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
                _durationCheck();
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
            PopupMenuButton(
              itemBuilder: (context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    child: Text('不开启'),
                    value: '0',
                  ),
                  PopupMenuItem(
                    child: Text('15分钟'),
                    value: '15',
                  ),
                  PopupMenuItem(
                    child: Text('30分钟'),
                    value: '30',
                  ),
                  PopupMenuItem(
                    child: Text('45分钟'),
                    value: '45',
                  ),
                  PopupMenuItem(
                    child: Text('60分钟'),
                    value: '60',
                  ),
                ];
              },
              icon: Icon(Icons.timer),
              elevation: 1,
              onSelected: (val) {
                setState(() {
                  _dateTime = DateTime.now();
                  _duration = int.parse(val);
                });
              },
              tooltip: '定时关闭',
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
                _durationCheck();
                playLocal(path);
              },
              title: Text(
                '${path.substring(path.lastIndexOf('/') + 1, path.lastIndexOf('.'))}',
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
                          _durationCheck();
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
