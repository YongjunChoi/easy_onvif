import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:mustache_template/mustache.dart';
import 'package:process_run/shell.dart';
import 'package:yaml/yaml.dart';

main(args) => grind(args);

@Task()
test() => new TestRunner().testAsync();

@DefaultTask()
@Depends(test)
build() {
  Pub.build();
}

@Task()
clean() => defaultClean();

@Task('publish')
@Depends(version, dartdoc, analyze, dryrun)
publish() async {
  log('publishing...');

  await shell(args: 'pub publish');
}

@Task('dartdoc')
dartdoc() async {
  log('drydoc...');

  await shell(exec: 'dartdoc');
}

@Task('dart pub publish --dry-run')
dryrun() async {
  log('dryrun...');

  await shell(args: 'pub publish --dry-run');
}

@Task('dart analyze')
analyze() async {
  log('analyzing...');

  await shell(args: 'analyze --fatal-infos');
}

@Task('version bump')
version() async {
  // final taskArgs = context.invocation.arguments;

  final config = loadYaml(File('tool/config.yaml').readAsStringSync());

  if (!config.containsKey('templates') ||
      !config.containsKey('version') ||
      !config.containsKey('change')) throw Exception();

  // final isBump = taskArgs.getFlag('bump');

  final newTag = await isNewTag(config['version']);

  if (newTag) {
    updateMarkdown(config);

    updatePubspec(config['version']);
  }

  commit(version: config['version'], change: config['change'], newTag: newTag);
}

Future<String> shell(
    {String exec = 'dart', String args = '', bool verbose: true}) async {
  final exectutable = whichSync(exec);

  if (exectutable == null) throw Exception();

  final shell = Shell(verbose: verbose);

  final result = await shell.run('$exectutable $args');

  String response = '';

  result.forEach((processResult) => response += processResult.outText);

  return response;
}

Future<bool> isNewTag(String version) async {
  final result =
      await shell(exec: 'git', args: 'tag -l "v$version"', verbose: false);

  return result.trim() != 'v$version';
}

commit(
    {required String version, required String change, required newTag}) async {
  shell(exec: 'git', args: 'add .');

  shell(exec: 'git', args: 'commit -m "$change"');

  if (newTag) {
    shell(exec: 'git', args: 'tag v$version');

    shell(exec: 'git', args: 'push --tags');
  } else {
    shell(exec: 'git', args: 'push');
  }
}

void updateMarkdown(config) {
  final templates = config['templates'].value;

  templates.forEach((templateFilename) {
    final mustacheTpl = File('tool/${templateFilename['name']}');

    if (!templateFilename.containsKey('name')) throw Exception();

    final String type = templateFilename.containsKey('type')
        ? templateFilename['type']!
        : 'append';

    final String templateFileName = templateFilename['name']!;

    final outputFile = File(templateFileName);

    final template =
        new Template(mustacheTpl.readAsStringSync(), name: templateFileName);

    switch (type) {
      case 'prepend':
        outputFile.writeAsStringSync(template.renderString(config));

        outputFile.writeAsStringSync(outputFile.readAsStringSync(),
            mode: FileMode.append);

        break;

      case 'overwrite':
        outputFile.deleteSync();

        outputFile.writeAsStringSync(template.renderString(config));

        break;

      default:
        outputFile.writeAsString(template.renderString(config),
            mode: FileMode.append);
    }
  });
}

void updatePubspec(String version) {
  final pubspecFile = File('pubspec.yaml');

  final String pubspecContent = pubspecFile.readAsStringSync();

  pubspecFile.renameSync('.pubspec.yaml.bak');

  File('pubspec.yaml').writeAsStringSync(
      pubspecContent.replaceAll(RegExp(r'version:.*'), 'version: $version'));
}