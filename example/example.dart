import 'package:easy_onvif/onvif.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  //get connection infomration from the config.yaml file
  final config = loadYaml(File('example/cli/config.yaml').readAsStringSync());

  //configure device connection
  final onvif = await Onvif.connect(
      host: config['host'],
      username: config['username'],
      password: config['password']);

  //get service addresses
  var serviceList = await onvif.deviceManagement.getServices();

  for (Service service in serviceList) {
    print('${service.nameSpace} ${service.xAddr}');
  }

  //get device info
  var deviceInfo = await onvif.deviceManagement.getDeviceInformation();

  print('Model: ${deviceInfo.model}');

  var ptzConfigs = await onvif.ptz.getConfigurations();

  for (var ptzConfiguration in ptzConfigs) {
    print(ptzConfiguration.name + ' ' + ptzConfiguration.token);
  }

  print('xMax: ${ptzConfigs[0].panTiltLimits!.range.xRange.max}');
  print('xMin: ${ptzConfigs[0].panTiltLimits!.range.xRange.min}');
  print('yMax: ${ptzConfigs[0].panTiltLimits!.range.yRange.max}');
  print('yMin: ${ptzConfigs[0].panTiltLimits!.range.yRange.min}');

  // get device profiles
  var profs = await onvif.media.getProfiles();

  for (var profile in profs) {
    print('name: ${profile.name}, token: ${profile.token}');
  }

  final uri = await onvif.media.getStreamUri(profs[2].token);

  final rtsp = OnvifUtil.authenticatingUri(
      uri.uri, config['username'], config['password']);

  print('stream uri: $rtsp');
}