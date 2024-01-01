import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State createState() => _Home();
}

class _Home extends State {
  VideoPlayerController? _controller;
  Future<bool> _initializeVideoPlayerFuture = Future(() => false);
  VideoPlayer? _player;
  List _listSongs = [];
  bool _showSongsList = false;
  bool _playVideo = false;
  final String _baseDirectory = "/storage/emulated/0/Personal/shorts";
  int _selectedSongIndex = 0;
  bool setVideoCompletionCondition = false;

  @override
  void initState() {
    initStateAsync();
    super.initState();
  }

  void initStateAsync() async {
    _listSongs = await _getFiles();
    _assignSong(_selectedSongIndex);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _videoPlayerTouchHandler,
      onVerticalDragEnd: _handleNextAndPreviousPlayingSongHandler,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            //Video
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (_, AsyncSnapshot snap) {
                if (snap.hasData) {
                  return Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: _player,
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),

            //Play/Pause Button
            Align(
              alignment: Alignment.center,
              child: Visibility(
                visible: false,
                child: GestureDetector(
                  onTap: () {
                    print("Play/Pause Button working");
                  },
                  child: const IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.play_arrow,
                      size: 150,
                    ),
                  ),
                ),
              ),
            ),

            //List of Songs Place
            Align(
              alignment: Alignment.bottomCenter,
              child: Visibility(
                visible: _showSongsList,
                child: Container(
                  color: Colors.white70,
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width,
                  child: ListView.builder(
                    itemCount: _listSongs.length,
                    itemBuilder: (_, index) => GestureDetector(
                      onTap: () => _selectSongHandler(index),
                      child: Container(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 6),
                        child: ListTile(
                          title: Text(
                            _listSongs[index],
                            style: const TextStyle(
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            //Footer
            // footer(),
          ],
        ),
        floatingActionButton: Opacity(
          opacity: _showSongsList ? 0.4 : 0.8,
          child: FloatingActionButton(
            backgroundColor: Colors.purple.shade50,
            onPressed: _showSongList,
            child: const Icon(Icons.list),
          ),
        ),
      ),
    );
  }

  void _handleNextAndPreviousPlayingSongHandler(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      _playPreviousSong();
    } else if (details.primaryVelocity! < 0) {
      _playNextSong();
    }
  }

  void _playNextSong() {
    if (_selectedSongIndex + 1 < _listSongs.length) {
      setState(() {
        _assignSong(_selectedSongIndex + 1);
      });
    } else {
      Fluttertoast.showToast(msg: "End of List");
    }
  }

  void _playPreviousSong() {
    if (_selectedSongIndex - 1 >= 0) {
      setState(() {
        _assignSong(_selectedSongIndex - 1);
      });
    } else {
      Fluttertoast.showToast(msg: "End of List");
    }
  }

  void _selectSongHandler(int index) {
    setState(() {
      _showSongsList = false;
      _assignSong(index);
    });
  }

  void _showSongList() async {
    _listSongs = await _getFiles();
    setState(() {
      _showSongsList = !_showSongsList;
    });
  }

  void _videoPlayerTouchHandler() {
    if (_showSongsList) {
      setState(() {
        _showSongsList = false;
      });
      return;
    }

    _playPauseSong();
  }

  void _playPauseSong() {
    if (_playVideo) {
      _pauseSong();
    } else {
      _playSong();
    }
  }

  void _playSong() {
    _playVideo = true;
    if (_controller != null) {
      _controller?.play();
    } else {
      Fluttertoast.showToast(
          msg: "Can't Play the song. _Controller returned null");
    }
  }

  void _pauseSong() {
    _playVideo = false;
    if (_controller != null) {
      _controller?.pause();
    } else {
      Fluttertoast.showToast(
          msg: "Can't Pause the song. _Controller returned null");
    }
  }

  Future<String?> _selectFolder() async {
    return await FilePicker.platform.getDirectoryPath();
  }

  Future<List> _getFiles() async {
    // String? path = await selectFolder();
    // if (path == null) {
    //   debugPrint("Directory Returned null");
    //   return;
    // }

    Directory dir = Directory(_baseDirectory);
    if (await dir.exists()) {
      List<FileSystemEntity> list = dir.listSync();

      List listSongs = [];
      for (var file in list) {
        listSongs.add(Uri.decodeComponent(_getFileName(file.uri.path)));
      }

      return listSongs;
    } else {
      debugPrint("Invalid Directory");
    }
    return [];
  }

  String _getFileName(String value) {
    return value.substring(value.lastIndexOf("/") + 1);
  }

  void _assignSong(int selectedIndex) {
    if (_listSongs.isEmpty) return;

    _selectedSongIndex = selectedIndex;
    _controller?.dispose();
    _controller = VideoPlayerController.file(
        File("$_baseDirectory/${_listSongs[selectedIndex]}"));

    setVideoCompletionCondition = false;
    _controller?.addListener(() {
      // print("Position: ${_controller?.value.position}");
      // print("Duration: ${_controller?.value.duration}");
      // print(
      //     "Condition: ${_controller?.value.position == _controller?.value.duration}");
      if (_controller?.value.position == _controller?.value.duration &&
          setVideoCompletionCondition) {
        _playNextSong();
      } else {
        setVideoCompletionCondition = true;
      }
    });

    // _controller?.setLooping(true);
    _player = VideoPlayer(_controller!);
    _initializeVideoPlayerFuture = _controller!.initialize().then((value) {
      setState(() {
        _playSong();
      });
      return true;
    });
  }
}
