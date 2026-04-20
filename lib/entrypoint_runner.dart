import 'package:build/build.dart';

import 'src/models/renderer_options.dart';
import 'src/models/type.dart';
import 'src/facade.dart';
import 'src/utils/logging.dart';

/// Top-level factory referenced from `build.yaml`.
///
/// One `quicktypeBuilder` factory handles all target languages — the
/// target is selected via `BuilderOptions.config['target']` ('dart',
/// 'kotlin', 'swift', 'typescript', etc.).
///
/// Input naming convention: files ending in `.qt.json` are processed.
/// Output extension is derived from the target language.
///
/// Extra renderer options can be supplied via
/// `BuilderOptions.config['args']` — each entry is passed straight through
/// to quicktype-core as a `rendererOptions` key/value pair:
///
/// ```yaml
/// options:
///   target: dart
///   args:
///     use-freezed: true
///     null-safety: true
///     part-name: user.g.dart
/// ```
///
/// See the target-language `*RendererOptions` class (e.g.
/// `DartRendererOptions`) for the authoritative list of recognized keys.
Builder quicktypeBuilder(BuilderOptions options) {
  final targetName = options.config['target'] as String? ?? 'dart';
  final targetType = _resolveTarget(targetName);
  final rendererOptions =
      _coerceRendererOptions(options.config['args'], targetType);
  return _QuicktypeBuilder(
      targetType: targetType, rendererOptions: rendererOptions);
}

class _QuicktypeBuilder implements Builder {
  _QuicktypeBuilder({
    required this.targetType,
    required this.rendererOptions,
  });

  final TargetType targetType;
  final Map<String, String> rendererOptions;

  @override
  Map<String, List<String>> get buildExtensions => {
        '.qt.json': [targetType.extensions.first],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    if (!input.path.endsWith('.qt.json')) return;

    final json = await buildStep.readAsString(input);
    final label = _labelFromAsset(input);

    try {
      final generated = await QuicktypeDart.generateFromString(
        label: label,
        json: json,
        target: targetType,
        options: _MapRendererOptions(rendererOptions),
      );

      final outputId = _outputAssetId(input, targetType);
      await buildStep.writeAsString(outputId, generated);
      Log.info(
        'Generated ${outputId.path} from ${input.path}',
        'QuicktypeBuilder',
      );
    } catch (e, s) {
      Log.severe(
        'Failed to generate ${targetType.name} for ${input.path}: $e\n$s',
        'QuicktypeBuilder',
      );
      rethrow;
    }
  }
}

/// Thin adapter that lets the builder pass an already-coerced
/// `Map<String, String>` through the typed [options] parameter on
/// [QuicktypeDart.generateFromString] without having to pick a
/// specific `*RendererOptions` subclass per language.
class _MapRendererOptions extends RendererOptions {
  const _MapRendererOptions(this._map);
  final Map<String, String> _map;

  @override
  Map<String, String> toRendererOptions() => _map;
}

/// Derives a PascalCase top-level type name from `foo_bar.qt.json`.
String _labelFromAsset(AssetId input) {
  final basename = input.pathSegments.last.replaceAll('.qt.json', '');
  final parts =
      basename.split(RegExp(r'[^A-Za-z0-9]+')).where((s) => s.isNotEmpty);
  if (parts.isEmpty) return 'Generated';
  return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// Replaces `.qt.json` with the target's primary extension.
AssetId _outputAssetId(AssetId input, TargetType targetType) {
  final ext = targetType.extensions.first;
  final newPath = input.path.replaceAll(RegExp(r'\.qt\.json$'), ext);
  return AssetId(input.package, newPath);
}

TargetType _resolveTarget(String name) {
  for (final t in TargetType.values) {
    if (t.name == name || t.argName == name) return t;
  }
  throw ArgumentError(
    'Unknown quicktype target "$name". Valid targets: '
    '${TargetType.values.map((t) => t.name).join(", ")}',
  );
}

/// Coerces the raw `args:` map from `build.yaml` into the
/// `Map<String, String>` shape quicktype-core's `rendererOptions`
/// accepts. Delegates to [coerceRendererOptionsMap] so
/// `quicktype.json` and `build.yaml` reject the same invalid shapes
/// with the same error — no surprise that `build.yaml` silently
/// accepts what `quicktype.json` rejects.
Map<String, String> _coerceRendererOptions(
  dynamic rawArgs,
  TargetType targetType,
) {
  if (rawArgs is! Map) return const {};
  // YAML maps land as `Map<dynamic, dynamic>`; normalize keys to String
  // before handing off to the shared coercer.
  final normalized = <String, Object?>{
    for (final entry in rawArgs.entries) entry.key.toString(): entry.value,
  };
  return coerceRendererOptionsMap(
    normalized,
    sectionLabel: '${targetType.name} builder args',
  );
}
