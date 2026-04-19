import 'package:build/build.dart';

import 'src/models/args.dart';
import 'src/models/type.dart';
import 'src/quicktype_dart.dart';
import 'src/utils/logging.dart';

/// Top-level factory referenced from `build.yaml`.
///
/// One `quicktypeBuilder` factory handles all target languages — the
/// target is selected via `BuilderOptions.config['target']` ('dart',
/// 'kotlin', 'swift', 'typescript', etc).
///
/// Input naming convention: files ending in `.qt.json` are processed.
/// Output extension is derived from the target language.
///
/// Extra CLI flags can be supplied via `BuilderOptions.config['args']`:
/// ```yaml
/// options:
///   target: dart
///   args:
///     use-freezed: true
///     null-safety: true
/// ```
Builder quicktypeBuilder(BuilderOptions options) {
  final targetName = options.config['target'] as String? ?? 'dart';
  final targetType = _resolveTarget(targetName);
  final args = _parseArgs(options.config['args'], targetType);
  return _QuicktypeBuilder(targetType: targetType, args: args);
}

class _QuicktypeBuilder implements Builder {
  _QuicktypeBuilder({required this.targetType, required this.args});

  final TargetType targetType;
  final List<Arg> args;

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
        args: args,
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

List<Arg> _parseArgs(dynamic rawArgs, TargetType targetType) {
  if (rawArgs is! Map) return const [];
  final registry = targetType.args;
  final out = <Arg>[];
  for (final entry in rawArgs.entries) {
    final key = entry.key.toString();
    final arg = registry[key];
    if (arg == null) {
      Log.warning(
        'Unknown arg "$key" for target ${targetType.name}; ignoring.',
        'QuicktypeBuilder',
      );
      continue;
    }
    _assignArgValue(arg, entry.value);
    out.add(arg);
  }
  return out;
}

void _assignArgValue(Arg arg, dynamic value) {
  if (arg is BoolArg || arg is SimpleArg) {
    if (value is bool) (arg as dynamic).value = value;
  } else if (arg is StringArg) {
    if (value is String) arg.value = value;
  } else if (arg is EnumArg) {
    Log.warning(
      'EnumArg "${arg.name}" cannot be set from build.yaml; '
      'configure programmatically.',
      'QuicktypeBuilder',
    );
  }
}
