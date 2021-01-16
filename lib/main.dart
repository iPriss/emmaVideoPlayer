import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:wakelock/wakelock.dart';
import 'package:dio/dio.dart';
import 'package:duration/duration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      new MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: Colors.black),
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
  bool downloading = false;

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

  getRandomList<String>(List<String> list, int n, String currentId) {
    if (list.length <= 0) return [];
    return (list.toList()..shuffle())
        .sublist(0, (list.length > n) ? n : list.length)
          ..remove(currentId);
  }

  parseIdsFromHtml<List>(String contents) {
    final ids = contents.split("\n");
    var parsedIds = <String>[];

    final idsRegex = RegExp(r'\b[0-9]{7}(?![0-9])');

    ids.forEach((element) {
      if (idsRegex.hasMatch(element)) {
        parsedIds.add(element.replaceAll('<a href="', '').substring(0, 7));
      }
    });
    return parsedIds;
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

  Future<void> downloadFile(String url, String destination) async {
    Dio dio = Dio();

    var progressString;

    var dir = await getApplicationDocumentsDirectory();
    print("path ${dir.path}");
    try {
      await dio.download(url, "${dir.path}/$destination",
          onReceiveProgress: (rec, total) {
        print("Rec: $rec , Total: $total");

        setState(() {
          downloading = true;
          progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
        });
      });
    } catch (e) {
      print(e);
    }

    setState(() {
      downloading = false;
      progressString = "Completed";
    });
    print("Download completed");
  }

  Future<void> downloadAllVideos() async {
    await downloadFile('http://192.168.0.49/series/peppa/', 'videos.html');
    List<String> currentIds = await _getIds();

    final dir = await getApplicationDocumentsDirectory();
    final rawListOfVideos = File('${dir.path}/videos.html');

    String contents = await rawListOfVideos.readAsString();
    List<String> ids = parseIdsFromHtml(contents);
    List<String> idNotDownloadedYet =
        ids.toSet().difference(currentIds.toSet()).toList();

    var i = 1;
    for (String element in idNotDownloadedYet) {
      print('Downloading video $element [$i from ' +
          idNotDownloadedYet.length.toString() +
          ']');
      await downloadFile(
          'http://192.168.0.49/series/${widget.section}/$element.mp4',
          'videos/${widget.section}/$element.mp4');
      await downloadFile(
          'http://192.168.0.49/series/${widget.section}/thumbnails/$element.jpeg',
          'thumbnails/${widget.section}/$element.jpeg');
      i++;
    }

    print(idNotDownloadedYet.length.toString() + ' Downloaded');
  }

  Future<void> downloadRandomVideo() async {
    await downloadFile('http://192.168.0.49/series/peppa/', 'videos.html');
    List<String> currentIds = await _getIds();

    final dir = await getApplicationDocumentsDirectory();
    final rawListOfVideos = File('${dir.path}/videos.html');

    String contents = await rawListOfVideos.readAsString();
    List<String> ids = parseIdsFromHtml(contents);
    List<String> idNotDownloadedYet =
        ids.toSet().difference(currentIds.toSet()).toList();

    if (idNotDownloadedYet.length > 0) {
      var randomItem = (idNotDownloadedYet.toList()..shuffle()).first;
      await downloadFile(
          'http://192.168.0.49/series/${widget.section}/$randomItem.mp4',
          'videos/${widget.section}/$randomItem.mp4');
      await downloadFile(
          'http://192.168.0.49/series/${widget.section}/thumbnails/$randomItem.jpeg',
          'thumbnails/${widget.section}/$randomItem.jpeg');
    } else {
      print("Up to Date...");
    }
  }

  @override
  void initState() {
    super.initState();

    createFolderInAppDocDir('videos');
    createFolderInAppDocDir('videos/peppa');
    createFolderInAppDocDir('thumbnails');
    createFolderInAppDocDir('thumbnails/peppa');
    _setup();
  }

  _setup() async {
    List<String> _ids = await _getIds();
    setState(
      () {
        ids = _ids;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: new Opacity(
        opacity: this.downloading ? 1 : 0.2,
        child: FloatingActionButton(
            onPressed: () {
              downloadRandomVideo();
              // downloadAllVideos();
            },
            child: Icon(this.downloading
                ? Icons.cloud_queue
                : Icons.cloud_download_outlined)),
      ),
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
                    height: size.height * 1,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: size.height * 0.20,
                          bottom: size.height * 0.20,
                          left: size.height * 0.015,
                          right: size.height * 0.015),
                      child: GridView.count(
                        scrollDirection: Axis.horizontal,
                        crossAxisCount: 2,
                        childAspectRatio: 0.56,
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
                                      related: getRandomList(ids, 30, value)),
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

  double position = 0.0;

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
        setState(
          () {
            position = _controller.value.position.inMilliseconds /
                _controller.value.duration.inMilliseconds;
          },
        );
        if (_controller.value.isPlaying) {
          Wakelock.enable();
          if (fullscreen == false) {
            if (_controller.value.position - _controller.value.duration >
                Duration(seconds: 5)) {
              if (_timer == null || !_timer.isActive) startTimer();
            } else {
              if (_timer != null && _timer.isActive) _timer.cancel();
            }
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
              if (_timer != null && _timer.isActive) _timer.cancel();
            },
          );
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    final double ratio = 1.77777778;
    final double magicRatio = ratio / 2.535;
    // 535
    double rHeight = size.width / ratio;
    if (rHeight > size.height) rHeight = size.height;
    // widget.related.removeWhere((item) => item == widget.video);
    final double margin = (size.height - rHeight) / 2;

    List<String> progressDuration = Duration(
            minutes: 0,
            seconds: 0,
            milliseconds: _controller.value.position.inMilliseconds)
        .toString()
        .split('.')[0]
        .split(':');
    String progressInMinutes =
        '${progressDuration[1].padLeft(2, "0")}:${progressDuration[2].padLeft(2, "0")}';

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
                    curve: Curves.easeOutQuart,
                    margin: new EdgeInsets.only(
                        top: fullscreen ? margin : margin * magicRatio,
                        bottom: fullscreen ? margin : margin * magicRatio),
                    width: fullscreen ? size.width : size.width * magicRatio,
                    height: fullscreen ? size.height : rHeight * magicRatio,
                    duration: Duration(milliseconds: 200),
                    child: _controller.value.initialized
                        ? AspectRatio(
                            aspectRatio: ratio,
                            child: VideoPlayer(_controller),
                          )
                        : Container(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(-0.39, 0.352), // 345
                child: AnimatedContainer(
                  width: size.width * 0.83,
                  // (size.width / _controller.value.aspectRatio) * 1.15, // Esto seria para cuando es celular?
                  height: fullscreen ? 0 : 6,
                  duration: Duration(milliseconds: 2),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        // margin: EdgeInsets.all(0),
                        height: 6,
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
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.lerp(Alignment(-0.916, 0.356),
                    Alignment(0.779, 0.356), position),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 2),
                  opacity: fullscreen ? 0 : 1,
                  child: IgnorePointer(
                    child: Container(
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(width: 3, color: Color(0xffff5076))),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 4,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0.9, 0.356), // 345
                child: AnimatedOpacity(
                  opacity: fullscreen ? 0 : 1,
                  duration: Duration(milliseconds: 2),
                  child: Text(
                    progressInMinutes,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'VAG'),
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
                    constraints: BoxConstraints(maxHeight: size.height / 4.74),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: !fullscreen
                          ? Container(
                              margin: EdgeInsets.only(top: size.height * 0.025),
                              // height: fullscreen ? 0 : size.height * 0.35,
                              height: size.height * 0.35,
                              // duration: Duration(milliseconds: 300),
                              child: GridView.count(
                                crossAxisCount: 1,
                                scrollDirection: Axis.horizontal,
                                childAspectRatio: 0.655,
                                children: widget.related.map((value) {
                                  return new InkWell(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              VideoApp(
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
                            )
                          : Container(),
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
              alignment: Alignment(0.05, -0.27),
              child: SizedBox(
                width: size.width * 0.1315,
                height: size.height * 0.1315,
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
                    size: size.width * 0.0957,
                    color: Color(0xffff5076),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          if (!fullscreen)
            Align(
              alignment: Alignment(-0.95, -0.868),
              child: SizedBox(
                width: size.width * 0.12,
                height: size.height * 0.12,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  heroTag: null,
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: size.width * 0.069),
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
