import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'functions/constants.dart';
import 'functions/filetype.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State createState() => _Home();
}

class _Home extends State {
  VideoPlayerController? _controller;
  final FileFunctions _fileFunctions = FileFunctions();
  VideoPlayer? _player;
  List _listSongs = [];
  bool _showSongsList = false;
  bool _playVideo = false;
  int _selectedSongIndex = 0;
  bool setVideoCompletionCondition = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
              future: _assign(_selectedSongIndex),
              builder: (_, AsyncSnapshot snap) {
                if (snap.hasData) {
                  FileTypes type = snap.data;
                  if (type == FileTypes.VIDEO) {
                    return Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: _player,
                      ),
                    );
                  } else if (type == FileTypes.IMAGE) {
                    if (_fileFunctions
                        .isImageFile(_listSongs[_selectedSongIndex])) {
                      return Align(
                        alignment: Alignment.center,
                        child: Image.file(File(
                            "${Constants.basedirectory}/${_listSongs[_selectedSongIndex]}")),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  } else {
                    return Align(
                      alignment: Alignment.center,
                      child: Text(
                        "File Type (${_listSongs[_selectedSongIndex]}) Not Determined!",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
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

  Future<void> _handleNextAndPreviousPlayingSongHandler(
      DragEndDetails details) async {
    if (details.primaryVelocity! > 0) {
      await _playPreviousSong();
    } else if (details.primaryVelocity! < 0) {
      await _playNextSong();
    }
  }

  Future<void> _playNextSong() async {
    if (_selectedSongIndex + 1 < _listSongs.length) {
      setState(() {
        _selectedSongIndex = _selectedSongIndex + 1;
      });
    } else {
      Fluttertoast.showToast(msg: "End of List");
    }
  }

  Future<void> _playPreviousSong() async {
    if (_selectedSongIndex - 1 >= 0) {
      setState(() {
        _selectedSongIndex = _selectedSongIndex - 1;
      });
    } else {
      Fluttertoast.showToast(msg: "End of List");
    }
  }

  void _selectSongHandler(int index) {
    setState(() {
      _showSongsList = false;
      _assign(index);
    });
  }

  void _showSongList() async {
    _listSongs = await _fileFunctions.getFiles();
    setState(() {
      _showSongsList = !_showSongsList;
    });
  }

  Future<void> _videoPlayerTouchHandler() async {
    if (_showSongsList) {
      setState(() {
        _showSongsList = false;
      });
      return;
    }

    await _playPauseSong();
  }

  Future<void> _playPauseSong() async {
    if (_playVideo) {
      await _pauseSong();
    } else {
      await _playSong();
    }
  }

  Future<void> _playSong() async {
    _playVideo = true;
    if (_controller != null) {
      await _controller?.play();
    } else {
      Fluttertoast.showToast(
          msg: "Can't Play the song. _Controller returned null");
    }
  }

  Future<void> _pauseSong() async {
    _playVideo = false;
    if (_controller != null) {
      await _controller?.pause();
    } else {
      Fluttertoast.showToast(
          msg: "Can't Pause the song. _Controller returned null");
    }
  }

  Future<String?> _selectFolder() async {
    return await FilePicker.platform.getDirectoryPath();
  }

  Future<FileTypes> _assign(int selectedIndex) async {
    // Checking if the list of songs is empty then we gather the data.
    // and if still empty then data doesn't exists so program just returns with undetermined.
    if (_listSongs.isEmpty) {
      _listSongs = await _fileFunctions.getFiles();
      if (_listSongs.isEmpty) {
        return FileTypes.UNDETERMINED;
      }
    }

    FileTypes type = _fileFunctions.determineFile(_listSongs[selectedIndex]);
    if (type == FileTypes.VIDEO) {
      await _assignSong(selectedIndex);
    } else if (type == FileTypes.IMAGE) {
      await _assignImage(selectedIndex);
    }
    return type;
  }

  Future<void> _assignImage(int selectedIndex) async {
    if (_listSongs.isEmpty) return;
    await _controller?.dispose();
  }

  Future<void> _assignSong(int selectedIndex) async {
    if (_listSongs.isEmpty) return;
    await _controller?.dispose();
    _controller = VideoPlayerController.file(
        File("${Constants.basedirectory}/${_listSongs[selectedIndex]}"));

    setVideoCompletionCondition = false;
    _controller?.addListener(() async {
      if (_controller?.value.position == _controller?.value.duration &&
          setVideoCompletionCondition) {
        await _playNextSong();
      } else {
        setVideoCompletionCondition = true;
      }
    });

    _player = VideoPlayer(_controller!);
    await _controller!.initialize();
    await _playSong();
    log("Duration is: ${_controller!.value.duration}");
  }
}
