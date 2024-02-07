import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'constants.dart';
import 'dart:developer';

class FileFunctions {
  FileTypes determineFile(String fileName) {
    if (isVideoFile(fileName)) {
      return FileTypes.VIDEO;
    } else if (isImageFile(fileName)) {
      return FileTypes.IMAGE;
    } else {
      return FileTypes.UNDETERMINED;
    }
  }

  bool isImageFile(String fileName) {
    List imageExtensions = [".jpg", ".png"];

    // Checking if file is image.
    for (String extension in imageExtensions) {
      if (fileName.endsWith(extension)) {
        return true;
      }
    }
    return false;
  }

  bool isVideoFile(String fileName) {
    List videoExtensions = [".mp4", ".webm"];
    // Checking if file is video...
    for (String extension in videoExtensions) {
      if (fileName.endsWith(extension)) {
        return true;
      }
    }
    return false;
  }

  Future<List<String>> getFiles() async {
    VideoPlayerController? controller;
    // String? path = await selectFolder();
    // if (path == null) {
    //   debugPrint("Directory Returned null");
    //   return;
    // }

    Directory dir = Directory(Constants.basedirectory);
    if (await dir.exists()) {
      List<FileSystemEntity> list = dir.listSync();

      List<String> listSongs = [];
      for (FileSystemEntity file in list) {
        controller = VideoPlayerController.file(File(file.uri.path));
        await controller.initialize();
        if (controller.value.duration.inSeconds < 2) {
          log("Duration is: ${controller.value.duration}");
          listSongs.add(Uri.decodeComponent(_getFileName(file.uri.path)));
        }
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
}

enum FileTypes {
  IMAGE,
  VIDEO,
  UNDETERMINED,
}
