import 'dart:async';

// import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_flutter/scrollNoWave.dart';

// import 'package:gbk2utf8/gbk2utf8.dart';
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
  List<String> playList = [];
  DateTime _dateTime;
  int _duration = 0;
  int _mode = 1; // 1: 顺序循环, 2: 单曲循环
  int _navIndex = 1;

  // 自定义弹框
  OverlayEntry overlayEntry;
  int overlayEntryIndex;

  // 读取播放歌曲的记录和播放列表
  _getPlay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List playListTemp = prefs.getStringList('playList');
    String lastPlaySong = prefs.getString('lastPlaySong');
    int mode = prefs.getInt('mode');

    if (playListTemp != null) {
      List<String> arr = [];
      playListTemp.forEach((element) {
        if (musicList.contains(element)) {
          arr.add(element);
        }
      });
      setState(() {
        playList = arr;
      });
    }

    if (lastPlaySong != null) {
      setState(() {
        currPlay = lastPlaySong;
      });
    }

    if (mode != null) {
      setState(() {
        _mode = mode;
      });
    }
  }

  // 保存当前播放歌曲的记录
  _setPlay(path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastPlaySong', path);
  }

  _setPlayList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('playList', playList);
  }

  // 保存当前播放歌曲的记录
  _setMode(mode) async {
    overlayEntry.remove();
    overlayEntryIndex = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('mode', int.parse(mode));
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
  // _getMp3Info(path) {
  //   final file = new File(path);
  //   print(path);
  //   List mp3Bytes = file.readAsBytesSync();
  //   var _header = mp3Bytes.sublist(mp3Bytes.length - 128, mp3Bytes.length);
  //   var _tag = _header.sublist(0, 3);
  //   Map metaTags = {};
  //
  //   if (latin1.decode(_tag).toLowerCase() == 'tag') {
  //     // metaTags['Version'] = '1.0';
  //     var _title = _header.sublist(3, 33);
  //     var _artist = _header.sublist(33, 63);
  //     var _album = _header.sublist(63, 93);
  //     var _year = _header.sublist(93, 97);
  //     var _comment = _header.sublist(97, 127);
  //     // var _genre = _header[127];
  //     // print(utf8.decode(_title));
  //     metaTags['Title'] = gbk.decode(_title).trim();
  //     metaTags['Artist'] = gbk.decode(_artist).trim();
  //     metaTags['Album'] = gbk.decode(_album).trim();
  //     metaTags['Year'] = gbk.decode(_year).trim();
  //     metaTags['Comment'] = gbk.decode(_comment).trim();
  //     // metaTags['Genre'] = GENREv1[_genre];
  //     metaTags.forEach((key, value) {
  //       print(value);
  //     });
  //     return true;
  //   }
  // }

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
        _getPlay();
      });
    }
  }

  // 提示信息
  _message(val) {
    ScaffoldMessenger.of(context).showSnackBar(
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
    int index = playList.indexOf(currPlay);
    if (_mode == 1) {
      if (index != playList.length - 1) {
        return playList[index + 1];
      } else {
        return playList[0];
      }
    } else {
      return playList[index];
    }
  }

  // 播放下一首
  _playNext() {
    playLocal(_getNext());
  }

  // 在点击播放时判断是否超时长了, 超则时长初始化为0
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

  _timeClose(val) {
    setState(() {
      _dateTime = DateTime.now();
      _duration = val;
    });
    overlayEntry.remove();
    overlayEntryIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double onePx = 1 / MediaQuery.of(context).devicePixelRatio;
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_navIndex == 0 ? '曲库共${musicList.length}首' : '列表共${playList.length}首'),
          actions: [
            IconButton(
              icon: Icon(
                CupertinoIcons.refresh,
                size: 20,
              ),
              onPressed: _getLocalFile,
            ),
          ],
        ),
        body: ScrollNoWave(
          child: ListView.builder(
            itemBuilder: (context, index) {
              String path = _navIndex == 0 ? musicList[index] : playList[index];
              return ListTile(
                onTap: () {
                  _durationCheck();
                  playLocal(path);
                  if (_navIndex == 0 && !playList.contains(path)) {
                    setState(() {
                      playList.insert(0, path);
                      _setPlayList();
                    });
                  }
                },
                title: Text(
                  '${path.substring(path.lastIndexOf('/') + 1, path.lastIndexOf('.'))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 48,
                  child: _navIndex == 0
                      ? playList.contains(path)
                          ? currPlay == path
                              ? IconButton(
                                  icon: Icon(
                                    playState == null
                                        ? CupertinoIcons.play
                                        : playState == AudioPlayerState.PLAYING
                                            ? CupertinoIcons.pause
                                            : CupertinoIcons.play,
                                    size: 20,
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
                              : SizedBox()
                          : IconButton(
                              icon: Icon(
                                CupertinoIcons.add,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  playList.add(path);
                                  _setPlayList();
                                });
                              },
                            )
                      : currPlay == path
                          ? IconButton(
                              icon: Icon(
                                playState == null
                                    ? CupertinoIcons.play
                                    : playState == AudioPlayerState.PLAYING
                                        ? CupertinoIcons.pause
                                        : CupertinoIcons.play,
                                size: 20,
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
                          : IconButton(
                              icon: Icon(
                                CupertinoIcons.clear,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                  () {
                                    playList.remove(path);
                                    _setPlayList();
                                  },
                                );
                              },
                            ),
                ),
              );
            },
            itemCount: _navIndex == 0 ? musicList.length : playList.length,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _navIndex,
          onTap: (index) {
            if (index < 2) {
              setState(() {
                _navIndex = index;
              });
            } else if (index == 2) {
              _durationCheck();
              if (playState == AudioPlayerState.PLAYING) {
                audioPlayer.pause();
              } else if (playState == AudioPlayerState.PAUSED) {
                audioPlayer.resume();
              } else {
                if (playList.isNotEmpty) {
                  if (playList.contains(currPlay)) {
                    playLocal(currPlay);
                  } else {
                    playLocal(playList[0]);
                  }
                } else {
                  _message('无歌曲可播放');
                }
              }
              // 播放暂停
            } else if (index == 3) {
              // 循环模式
              overlayEntryIndex = 1;
              overlayEntry = OverlayEntry(builder: (context) {
                return Stack(
                  children: [
                    GestureDetector(
                      child: Container(
                        width: width,
                        height: height,
                      ),
                      onTap: () {
                        overlayEntry.remove();
                        overlayEntryIndex = 0;
                      },
                      behavior: HitTestBehavior.opaque,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Material(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xff999999),
                                width: onePx,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: _mode == 1 ? Colors.black38 : Colors.transparent,
                                  size: 20,
                                ),
                                title: Text('顺序循环'),
                                onTap: () {
                                  setState(() {
                                    _mode = 1;
                                    _setMode('1');
                                  });
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: _mode == 2 ? Colors.black38 : Colors.transparent,
                                  size: 20,
                                ),
                                title: Text('单曲循环'),
                                onTap: () {
                                  setState(() {
                                    _mode = 2;
                                    _setMode('2');
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                );
              });
              Overlay.of(context).insert(overlayEntry);
            } else if (index == 4) {
              // 定时
              overlayEntryIndex = 1;
              overlayEntry = OverlayEntry(builder: (context) {
                return Stack(
                  children: [
                    GestureDetector(
                      child: Container(
                        width: width,
                        height: height,
                      ),
                      onTap: () {
                        overlayEntry.remove();
                        overlayEntryIndex = 0;
                      },
                      behavior: HitTestBehavior.opaque,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Material(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xff999999),
                                width: onePx,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [0, 15, 30, 45, 60].map<Widget>((item) {
                              return ListTile(
                                leading: Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: _duration == item ? Colors.black38 : Colors.transparent,
                                  size: 20,
                                ),
                                title: Text(item == 0 ? '不开启' : '$item分钟'),
                                onTap: () {
                                  _timeClose(item);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              });
              Overlay.of(context).insert(overlayEntry);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.double_music_note),
              label: '曲库',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.music_note_list),
              label: '列表',
            ),
            BottomNavigationBarItem(
              icon: Icon(playState == null
                  ? CupertinoIcons.play
                  : playState == AudioPlayerState.PLAYING
                      ? CupertinoIcons.pause
                      : CupertinoIcons.play),
              label: playState == null
                  ? '播放'
                  : playState == AudioPlayerState.PLAYING
                      ? '暂停'
                      : '播放',
            ),
            BottomNavigationBarItem(
              icon: Icon(_mode == 1 ? CupertinoIcons.repeat : CupertinoIcons.repeat_1),
              label: '循环',
            ),
            BottomNavigationBarItem(
              icon: Icon(_duration == 0 ? CupertinoIcons.time : CupertinoIcons.timer),
              label: '定时',
            ),
          ],
        ),
      ),
      onWillPop: () async {
        if (overlayEntryIndex == 1) {
          overlayEntry.remove();
          overlayEntryIndex = 0;
          return false;
        }
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
