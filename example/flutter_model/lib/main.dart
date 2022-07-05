import 'package:easy_onvif/onvif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:flutter_model/video_player.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:loggy/loggy.dart';
import 'package:yaml/yaml.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onvif Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Onvif Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final List<Profile> profiles;

  late final GetDeviceInformationResponse deviceInfo;

  late final MediaUri snapshotUri;

  late final YamlMap config;

  bool connecting = false;

  String model = '';

  String manufacturer = '';

  String firmwareVersion = '';

  String rtsp = '';

  VlcPlayerController? controller ;
  late Onvif onvif;
  @override
  void initState() {
    _initialize();
    super.initState();
  }

  _initialize() async {
    final yamlData = await services.rootBundle.loadString('assets/config.yaml');

    config = loadYaml(yamlData);

    setState(() {
      connecting = true;
    });

    // configure device connection
    onvif = await Onvif.connect(
        host: config['host'],
        username: config['username'],
        password: config['password'],
        logOptions: const LogOptions(
          LogLevel.debug,
          stackTraceLevel: LogLevel.off,
        ),
        printer: const PrettyDeveloperPrinter());

    setState(() {
      connecting = false;
    });

    deviceInfo = await onvif.deviceManagement.getDeviceInformation();

    profiles = await onvif.media.getProfiles();

    snapshotUri = await onvif.media.getStreamUri(profiles[0].token);


    var ptzConfigs = await onvif.ptz.getConfigurations();

    for (var ptzConfiguration in ptzConfigs) {
      print('${ptzConfiguration.name}  ${ptzConfiguration.token}');
    }

    print('panTiltLimits xMax: ${ptzConfigs[0].panTiltLimits!.range.xRange.max}');
    print('panTiltLimits xMin: ${ptzConfigs[0].panTiltLimits!.range.xRange.min}');
    print('panTiltLimits yMax: ${ptzConfigs[0].panTiltLimits!.range.yRange.max}');
    print('panTiltLimits yMin: ${ptzConfigs[0].panTiltLimits!.range.yRange.min}');

    print('zoomLimits xMax: ${ptzConfigs[0].zoomLimits!.range.xRange.max}');
    print('zoomLimits xMin: ${ptzConfigs[0].zoomLimits!.range.xRange.min}');

    //get get configuration
    var ptzConfig = await onvif.ptz.getConfiguration(ptzConfigs[0].token);

    print('ptzConfig: $ptzConfig');


    //get get presets
    // var presets = await onvif.ptz.getPresets(profiles[0].token, limit: 1);
    //
    // for (var preset in presets) {
    //   print('preset: ${preset.token} ${preset.name}');
    // }

    //get ptz status
    // var status = await onvif.ptz.getStatus(profiles[0].token);
    //
    // print('status: $status');

    //set preset
    //var res = await onvif.ptz.setPreset(profiles[0].token, 'new test', '20');
    //print(res);

  }

  void _update() {
    setState(() {
      model = deviceInfo.model;

      manufacturer = deviceInfo.manufacturer;

      firmwareVersion = deviceInfo.firmwareVersion;

      rtsp = OnvifUtil.authenticatingUri(
          snapshotUri.uri, config['username']!, config['password']!);

      controller = VlcPlayerController.network(rtsp,
        hwAcc: HwAcc.full, autoPlay: true, options: VlcPlayerOptions(),
      );
    });
  }

  // void _connect()async{
  //   Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayer(rtsp, key: null,)));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: connecting
                ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Connecting to camera'),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                ])
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Device Manufacturer:',
                  ),
                ),
                Text(
                  manufacturer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Model:',
                  ),
                ),
                Text(
                  model,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Firmware Version:',
                  ),
                ),
                Text(
                  firmwareVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Snapshot:',
                  ),
                ),
                controller != null ?
                VlcPlayer(
                  controller: controller!,
                  aspectRatio: 16/9,
                  placeholder: const Center(child:CircularProgressIndicator()),
                ) : Container(),
                TextButton(
                  onPressed: () async {
                    await onvif.ptz.moveDown(profiles[0].token);;
                  } ,
                  child: const Text('move down'),
                ),
                TextButton(
                  onPressed: () async {
                    await onvif.ptz.moveLeft(profiles[0].token);
                  } ,
                  child: const Text('move moveLeft'),
                ),
                TextButton(
                  onPressed: () async {
                    await onvif.ptz.moveRight(profiles[0].token);
                  } ,
                  child: const Text('move moveRight'),
                ),
                TextButton(
                  onPressed: () async {
                    await onvif.ptz.moveUp(profiles[0].token);
                  } ,
                  child: const Text('move moveUp'),
                ),
                TextButton(
                  onPressed: () async {
                    await onvif.ptz.zoomIn(profiles[0].token);
                  } ,
                  child: const Text('move zoomIn'),
                ),
                TextButton(
                  onPressed: () async {
                    await onvif.ptz.zoomOut(profiles[0].token);
                  } ,
                  child: const Text('move zoomOut'),
                ),
              ],
            ),
          ),
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _update,
        tooltip: 'Update',
        child: const Text('GetInfo'),
      ),
    );
  }
}
