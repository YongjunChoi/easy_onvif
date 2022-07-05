import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VideoPlayer extends StatefulWidget {

  const VideoPlayer(this.url , {required Key? key}) : super(key: key);
  final String url;
  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {

  late String url ;
  late VlcPlayerController controller ;
  @override
  void initState() {

    url = widget.url;

    if (kDebugMode) {
      print(url);
    }

    //test url
    //url = "https://media.w3.org/2010/05/sintel/trailer.mp4";

    controller = VlcPlayerController.network(url,
      hwAcc: HwAcc.full, autoPlay: true, options: VlcPlayerOptions(),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(appBar: AppBar(),body: Center(
        child: VlcPlayer(
          controller: controller,
          aspectRatio: 16/9,
          placeholder: Center(child:CircularProgressIndicator()),

        ),
      ),);

  }
}