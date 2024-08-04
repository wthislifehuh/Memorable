import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'dart:developer' as developer;

class ModelDownloader {
  static var numLoaded = 0;

  HttpClient httpClient = new HttpClient();

  Future<void> downloadFile() async {
    const List<String> fileList = <String>[
      "flowers.glb",
      "free_low-poly_japanese_stone_lantern_ishi-doro.glb",
      "garden_flower_-_vegetation.glb",
      "historical_window.glb",
      "kiosk.glb",
      "kuih_lapis.glb",
      "lantern.glb",
      "mahogany_table.glb",
      "milk.glb",
      "nasi_lemak.glb",
      "nasi_lemak 2.glb",
      "otomos_-_cecilia_immergreens_mascot.glb",
      "quinney_spin.glb",
      "statues_of_generals.glb",
      "try first allglb.glb",
      "utar_wall.glb",
      "utarBlockMWall.glb",
      "white_flower.glb",
      "wooden_box.glb"
    ];

    for(var filename in fileList)
      {
        Directory directory = await getApplicationDocumentsDirectory();
        var dbPath = join(directory.path, filename);
        if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound) {
          ByteData data = await rootBundle.load("assets/models/"+filename);
          List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await File(dbPath).writeAsBytes(bytes);
        }
      }
  }
}