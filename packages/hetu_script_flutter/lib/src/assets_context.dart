import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu_script.dart';

class HTAssetsSourceContext extends HTResourceContext<HTSource> {
  @override
  final String root;

  @override
  Set<String> get included => _cached.keys.toSet();

  final _cached = <String, HTSource>{};

  /// Create a [HTAssetsSourceContext] with every script file
  /// placed under folder of [root], which defaults to 'scripts/'
  HTAssetsSourceContext({this.root = 'scripts/'});

  Future<void> init() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final scriptPaths = manifestMap.keys
        .where((String key) => key.contains(root))
        .where((String key) =>
            key.contains(HTSource.hetuModuleFileExtension) ||
            key.contains(HTSource.hetuScriptFileExtension))
        .toList();

    for (final fileName in scriptPaths) {
      final content = await rootBundle.loadString(fileName);
      final ext = path.extension(fileName);
      // final name = HTResourceContext.checkHetuModuleName(fileName);
      final source = HTSource(content,
          name: fileName, isScript: ext == HTSource.hetuScriptFileExtension);
      addResource(fileName, source);
    }
  }

  String getFullName(String name) {
    late String fullName;
    if (name.startsWith(root)) {
      fullName = name;
    } else {
      fullName = path.join(root, name);
    }
    return fullName;
  }

  @override
  bool contains(String key) {
    return _cached.keys.contains(getFullName(key));
  }

  @override
  void addResource(String fullName, HTSource resource) {
    resource.name = fullName;
    _cached[fullName] = resource;
  }

  @override
  void removeResource(String fullName) {
    _cached.remove(fullName);
    included.remove(fullName);
  }

  @override
  HTSource getResource(String key, {String? from}) {
    var normalized = key;
    // if (!key.startsWith(HTResourceContext.hetuModulesPrefix)) {
    if (!key.startsWith(root)) {
      normalized = getAbsolutePath(
          key: key, dirName: from != null ? path.dirname(from) : root);
    }
    // }
    if (_cached.containsKey(normalized)) {
      return _cached[normalized]!;
    }
    throw HTError.sourceProviderError(normalized);
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    if (!_cached.containsKey(fullName)) {
      throw HTError.sourceProviderError(fullName);
    }
    _cached[fullName] = resource;
  }
}
