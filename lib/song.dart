import 'package:flutter/services.dart';
import 'package:dart_tags/dart_tags.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'dart:io';

import './songProvider.dart';

final String tableSong = 'songs';
final String columnId = '_id';
final String columnPath = 'path';
final String columnTitle = 'title';
final String columnArtist = 'artist';
final String columnAlbum = 'album';
final String columnLyrics = 'lyrics';
final String columnImageData = 'image';

class Song {
  String path;
  String title;
  String artist;
  String album;
  String lyrics;
  Uint8List imageData;
  int id;

  Song();

  retrieveMetaData(File file) async {
    var meta;
    try {
      meta = await new TagProcessor().getTagsFromByteArray(file.readAsBytes());
    } catch (e) {
      return null;
    }
    return meta[1].tags;
  }

  Future<dynamic> saveFromFileTodb(
      FileSystemEntity file, SongProvider provider) async {
    path = file.path;
    var tags = await retrieveMetaData(file);
    title = formatText(tags['title']);
    album = formatText(tags['album']);
    artist = formatText(tags['artist']);
    lyrics = tags['lyrics'];
    imageData = await _getImageData(path);
    return provider.insert(this);
  }

  Song.fromFileTodb(FileSystemEntity file, SongProvider provider) {
    path = file.path;
    retrieveMetaData(file).then((tags) {
      title = formatText(tags['title']);
      album = formatText(tags['album']);
      artist = formatText(tags['artist']);
      lyrics = tags['lyrics'];
      imageData = tags['APIC'] != null
          ? Uint8List.fromList(tags['APIC'].imageData)
          : null;
      provider.insert(this);
    });
  }

  Future<int> updateInDb() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + 'demo.db';
    SongProvider provider = SongProvider();
    await provider.open(path);
    var count = await provider.update(this);
    await provider.close();
    return count;
  }

  Song.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    path = map[columnPath];
    title = map[columnTitle];
    artist = map[columnArtist];
    album = map[columnAlbum];
    lyrics = map[columnLyrics];
    imageData = map[columnImageData];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map[columnId] = id;
    map[columnPath] = path;
    map[columnTitle] = title;
    map[columnAlbum] = album;
    map[columnArtist] = artist;
    map[columnLyrics] = lyrics;
    map[columnImageData] = imageData;
    return map;
  }

  @override
  String toString() {
    return this.toMap().toString();
  }

  String formatText(String val) {
    if (val == null) return val;
    print(val);
    String formatted =
        val.replaceAll(new RegExp(r'(\(?[^ ]+?\.[^ ]+)|\(.*?\)|\d+'), '');
    // remove (ANYWORD)
    // formatted = formatted.replaceAll(
    //     new RegExp(r'\d+ \K\b\p\s'), ''); // remove - ANY TEXT AFTER HYPHEN
    // formatted = formatted.replaceAll(
    //     new RegExp(r'\- [^ ]+'), ''); // remove word.word ANY DOMAIN WORD
    formatted = formatted.replaceAll(new RegExp(r'-.*'), '');
    print(formatted);
    return formatted;
  }

  static const platform = const MethodChannel('flutter.io/solyrical');

  Future<Uint8List> _getImageData(path) async {
    Uint8List imageData;
    try {
      imageData = await platform.invokeMethod('getImage', {'path': path});
    } on PlatformException catch (e) {
      print('exception occured in getting image');
      imageData = null;
    }
    return imageData;
  }
}
