import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// the following file contains the key and url for Flask API
import 'auth/secrets.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Auralyse",
    theme: ThemeData(
      //brightness: Brightness.dark,
      primaryColor: Colors.greenAccent,
      hintColor: Colors.limeAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  late String _path;
  List<Image> _images = [];
  int _currentImageIndex = 0;
  late Timer _timer;
  bool isRecording = false;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    Directory tempDir = await getTemporaryDirectory();
    _path = '${tempDir.path}/audio.wav';
  }

  Future<void> record() async {
    PermissionStatus status = await Permission.microphone.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      await Permission.microphone.request().isGranted;
    }
    // Check if a playback is in progress
    if (_player.isPlaying) {
      // If a playback is in progress, stop it
      await _player.stopPlayer();
    }
    await _recorder.startRecorder(toFile: _path);
    setState(() {
      isRecording = true;
      _images = <Image>[];
    });
  }

  Future<void> stop() async {
    setState(() {
      isRecording = false;
    });
    await _recorder.stopRecorder();
    await sendAudio();
  }

  Future<void> sendAudio() async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('file', _path));
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Decode the zip file.
        final bytes = response.bodyBytes;
        final archive = ZipDecoder().decodeBytes(bytes);

        // Iterate over the files in the archive and decode any images.
        _images = <Image>[];
        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase().endsWith('.png')) {
            _images.add(Image.memory(file.content));
          }
        }

        _imagesLoaded = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Request Failed: $e');
      }
    }
  }

  Future<void> play() async {
    bool isSnackBarShown = false;
    await _player.startPlayer(fromURI: _path);
    Duration audioDuration = Duration.zero;

    _player.onProgress?.listen((event) {
      audioDuration = event.duration;
      if (event.duration == event.position) {
        // Audio has finished playing
        _timer.cancel();
        if (!isSnackBarShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scaffoldMessengerKey.currentState!.showSnackBar(
              const SnackBar(
                content: Text(
                    'Audio has finished playing. Press the Mic button to record and analyse new speeches.'),
              ),
            );
          });
          isSnackBarShown = true;
        }
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _images.length;
      });
      if (timer.tick >= audioDuration.inSeconds) {
        _currentImageIndex = 0;
        timer.cancel();
      }
    });

    _player.setSubscriptionDuration(const Duration(milliseconds: 10));

    // Use the GlobalKey here as well
    if (_images.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffoldMessengerKey.currentState!.showSnackBar(
          const SnackBar(
            content: Text(
                'Please press the Mic button to record the speech again for analysis.'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Auralyse'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (_images.isNotEmpty)
              Expanded(child: _images[_currentImageIndex]),
            if (_images.isEmpty && isRecording)
              Column(
                children: <Widget>[
                  Text(
                    isRecording ? 'Recording in progress' : 'Analysing',
                  ),
                  LinearProgressIndicator(
                    semanticsLabel:
                        isRecording ? 'Recording in progress' : 'Analysing',
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                AvatarGlow(
                  animate: isRecording,
                  glowColor: Theme.of(context).primaryColor,
                  endRadius: 80,
                  duration: const Duration(milliseconds: 20000),
                  repeatPauseDuration: const Duration(milliseconds: 1000),
                  repeat: true,
                  child: FloatingActionButton(
                    onPressed: (isRecording ? stop : record),
                    child: Icon(
                        isRecording ? Icons.hearing_outlined : Icons.mic_none),
                  ),
                ),
                if (!isRecording && _imagesLoaded)
                  AvatarGlow(
                    animate: true,
                    glowColor: Theme.of(context).primaryColor,
                    endRadius: 80,
                    duration: const Duration(milliseconds: 20000),
                    repeatPauseDuration: const Duration(milliseconds: 1000),
                    repeat: true,
                    child: FloatingActionButton(
                      onPressed: play,
                      child: const Icon(Icons.play_arrow),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
