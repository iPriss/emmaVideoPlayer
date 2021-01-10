import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import "dart:math";
import 'package:wakelock/wakelock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      new MaterialApp(
        theme: ThemeData(
            // brightness: Brightness.dark,
            // primaryColor: Colors.blueGrey,
            // primaryColor: Colors.black,
            scaffoldBackgroundColor: Colors.black),
        title: 'Discovery Kid Omar',
        debugShowCheckedModeBanner: false,
        home: new SectionLobby(
          section: 'peppa',
        ),
      ),
    );
  });
}

class SectionLobby extends StatefulWidget {
  SectionLobby({Key key, @required this.section}) : super(key: key);

  final String section;

  @override
  _SectionLobbyState createState() => _SectionLobbyState();
}

class _SectionLobbyState extends State<SectionLobby> {
  String directory;
  List<String> ids = new List();

  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  getRandomList<String>(List list, int n) {
    List<String> randomList = new List();

    if (list.length > 0) {
      if (list.length < n) n = list.length;

      for (var i = 0; i <= n; i++) {
        final random = new Random();
        int i = random.nextInt(list.length);
        randomList.add(list[i]);
      }
    }
    return randomList;
  }

  Future<List<String>> _getIds() async {
    directory = (await getApplicationDocumentsDirectory()).path;
    List<String> ids = new List();
    List videosPath = new List();
    videosPath =
        new Directory("$directory/videos/${widget.section}/").listSync();

    videosPath.forEach((element) {
      String filename = basename(element.path);
      ids.add(filename.replaceAll('.mp4', ''));
    });

    return ids;
  }

  @override
  void initState() {
    super.initState();

    // createFolderInAppDocDir('videos');
    // createFolderInAppDocDir('videos/peppa');
    // createFolderInAppDocDir('thumbnails');
    // createFolderInAppDocDir('thumbnails/peppa');
    _setup();
    // _listofFiles();
  }

  _setup() async {
    List<String> _ids = await _getIds();

    setState(() {
      ids = _ids;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    print(getRandomList(ids, 30));

    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    final double itemHeight = (size.height - kToolbarHeight - 24) / 3;
    final double itemWidth = size.width / 11;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            // margin: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Container(
                    decoration: new BoxDecoration(
                      gradient: new LinearGradient(
                          colors: [
                            const Color(0xFF3366FF),
                            const Color(0xFF00CCFF),
                            const Color(0xFF00CCFF),
                            const Color(0xFF3366FF),
                          ],
                          begin: const FractionalOffset(0.0, 0.0),
                          end: const FractionalOffset(1.0, 0.0),
                          stops: [0.0, 0.3, 0.7, 1.0],
                          tileMode: TileMode.clamp),
                    ),
                    height: MediaQuery.of(context).size.height * 1,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 60.0, bottom: 60.0, left: 15, right: 15),
                      child: GridView.count(
                        scrollDirection: Axis.horizontal,
                        crossAxisCount: 2,
                        childAspectRatio: (itemWidth / itemHeight),
                        children: ids.map((String value) {
                          return new InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoApp(
                                      directory: directory,
                                      section: widget.section,
                                      video: value,
                                      related: getRandomList(ids, 30)),
                                ),
                              );
                            },
                            child: Container(
                              margin: new EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(File(
                                      '$directory/thumbnails/${widget.section}/$value.jpeg')),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 5.0,
                                      offset: Offset(0, 4))
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoApp extends StatefulWidget {
  VideoApp(
      {Key key,
      @required this.directory,
      @required this.section,
      @required this.video,
      @required this.related})
      : super(key: key);

  final String video;
  final String section;
  final String directory;
  final List related;

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller;
  Timer _timer;
  bool fullscreen = true;

  void startTimer() {
    const oneSec = const Duration(seconds: 5);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          fullscreen = true;
          _timer.cancel();
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    File file = new File(
        '${widget.directory}/videos/${widget.section}/${widget.video}.mp4');

    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
        });
      })
      ..addListener(() {
        if (_controller.value.isPlaying) {
          Wakelock.enable();
          if (fullscreen == false) {
            if (_timer == null || !_timer.isActive) startTimer();
          } else {
            if (_timer != null && _timer.isActive) _timer.cancel();
          }
        } else {
          Wakelock.disable();
          if (_timer != null && _timer.isActive) _timer.cancel();
        }

        if (_controller.value.position >= _controller.value.duration) {
          setState(
            () {
              fullscreen = false;
              _timer.cancel();
            },
          );
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight) / 2.9;
    final double itemWidth = size.width / 12;

    // widget.related.removeWhere((item) => item == widget.video);

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              fullscreen = !fullscreen;
            });
          },
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  child: AnimatedContainer(
                    margin: new EdgeInsets.symmetric(
                        vertical: fullscreen || (size.height * 0.10) < 50
                            ? 0
                            : size.height * 0.10),
                    width: fullscreen
                        ? size.width
                        : size.width / _controller.value.aspectRatio * 1.2,
                    height: fullscreen
                        ? size.height
                        : (size.height / _controller.value.aspectRatio * 1.2),
                    duration: Duration(milliseconds: 300),
                    child: _controller.value.initialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : Container(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, 0.22),
                child: AnimatedContainer(
                  width: (size.width / _controller.value.aspectRatio) * 1.15,
                  height: fullscreen ? 0 : 12,
                  duration: Duration(milliseconds: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: EdgeInsets.all(0),
                      colors: VideoProgressColors(
                          playedColor: Color(0xffff5076),
                          bufferedColor: Colors.white,
                          backgroundColor: Colors.white),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onPanDown: (details) {
                    if (_timer != null && _timer.isActive) _timer.cancel();
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 110.0),
                    child: AnimatedContainer(
                      margin: EdgeInsets.only(top: size.height * 0.025),
                      height: fullscreen ? 0 : size.height * 0.35,
                      duration: Duration(milliseconds: 300),
                      child: GridView.count(
                        crossAxisCount: 1,
                        scrollDirection: Axis.horizontal,
                        childAspectRatio: (itemWidth / itemHeight),
                        children: widget.related.map((value) {
                          return new InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => VideoApp(
                                      directory: widget.directory,
                                      section: widget.section,
                                      video: value,
                                      related: widget.related),
                                ),
                              );
                            },
                            child: Container(
                              margin: new EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(File(
                                      '${widget.directory}/thumbnails/${widget.section}/$value.jpeg')),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 5.0,
                                      offset: Offset(0, 4))
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          if (!fullscreen)
            Align(
              alignment: Alignment(0.05, -0.30),
              child: SizedBox(
                width: size.width * 0.16,
                height: size.height * 0.16,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  heroTag: null,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: size.width * 0.08,
                    color: Color(0xffff5076),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          if (!fullscreen)
            Align(
              alignment: Alignment(-0.95, -0.777),
              child: SizedBox(
                width: size.width * 0.12,
                height: size.height * 0.12,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  heroTag: null,
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: size.width * 0.06),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller.value.isPlaying) _controller.pause();
    _controller.dispose();
  }
}
