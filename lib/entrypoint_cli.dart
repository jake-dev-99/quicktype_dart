import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import 'src/config.dart';
import 'src/internal/quicktype_process.dart';
import 'src/quicktype.dart';
import 'src/version.dart';

/// Entry point for the `quicktype_dart` CLI.
///
/// Wired up from `bin/quicktype_dart.dart` — run it with:
///
/// ```bash
/// dart run quicktype_dart            # uses ./quicktype.json
/// dart run quicktype_dart -c foo.json
/// dart run quicktype_dart -- --help  # pass-through to the quicktype CLI
/// ```
class QuicktypeCLI {
  /// Runs the CLI with [args] and returns the exit code (0 on success).
  static Future<int> run(List<String> args) async {
    _installLogForwarder();

    final parser = ArgParser()
      ..addOption('config',
          abbr: 'c',
          defaultsTo: Config.defaultConfigFile,
          help: 'Path to configuration file')
      ..addFlag('help',
          abbr: 'h', negatable: false, help: 'Display usage information')
      ..addFlag('version',
          abbr: 'v', negatable: false, help: 'Display version information');

    try {
      final options = parser.parse(args);

      if (options.flag('help')) {
        _printUsage();
        return 0;
      }

      if (options.flag('version')) {
        await _printVersion();
        return 0;
      }

      // If any additional arguments provided, run against native quicktype
      if (options.rest.isNotEmpty) {
        return await Quicktype.executeNative(options.rest);
      }

      final configPath = options.option('config') ?? Config.defaultConfigFile;
      return await _generateFromConfig(configPath);
    } catch (e, stackTrace) {
      stderr.writeln('Error: $e');
      stderr.writeln(stackTrace);
      return 1;
    }
  }

  /// Loads [configPath] into a [Quicktype] instance, expands into
  /// commands, and executes them. Returns exit code 0 on full success,
  /// 1 if any command failed.
  static Future<int> _generateFromConfig(String configPath) async {
    stdout.writeln('Running quicktype with config: $configPath');

    // CLI invocations surface config-parse errors directly instead of
    // silently running with defaults — the user asked for this config,
    // we don't get to decide it's invalid.
    final quicktype =
        Quicktype(Config.loadOrDefaults(path: configPath, strict: true));
    final commands = await quicktype.buildCommandsFromConfig();
    final results = await quicktype.executeAll(commands);

    final successCount = results.where((r) => r.success).length;
    stdout.writeln(
        'Generated $successCount/${results.length} files successfully');

    final failures = results.where((r) => !r.success).toList();
    if (failures.isNotEmpty) {
      stderr.writeln('\nErrors:');
      for (final f in failures) {
        stderr.writeln(
            '  - ${f.sourcePath} → ${f.targetPath}: ${f.errorMessage}');
      }
      return 1;
    }

    return 0;
  }

  /// Print CLI usage information.
  static void _printUsage() {
    stdout.writeln('''
Quicktype Dart - Generate types from schemas

Usage:
  quicktype [options]

Options:
  --config, -c FILE   Config file path (default: quicktype.json)
  --help, -h          Show help
  --version, -v       Show version

Examples:
  quicktype                  Generate using quicktype.json
  quicktype -c custom.json   Generate using custom.json

For more details: https://github.com/jake-dev-99/quicktype_dart
''');
  }

  /// Print version information.
  static Future<void> _printVersion() async {
    stdout.writeln('Quicktype Dart v$packageVersion');
    try {
      final exe = await resolveQuicktypeExecutable();
      final result = Process.runSync(exe, ['--version']);
      if (result.exitCode == 0) {
        stdout.writeln('Native quicktype: ${(result.stdout as String).trim()}');
      } else {
        stdout.writeln('Native quicktype: exited ${result.exitCode}');
      }
    } on QuicktypeException {
      stdout.writeln('Native quicktype: not installed');
    } catch (e) {
      stdout.writeln('Native quicktype: $e');
    }
  }

  /// Wires `Logger('quicktype')` records to stdout/stderr so library
  /// diagnostics (`Log.info` etc.) reach the terminal when run as a CLI.
  /// Idempotent: re-runs in the same process (tests) just replace the
  /// single listener.
  static void _installLogForwarder() {
    Logger.root.level = Level.INFO;
    _logSubscription?.cancel();
    _logSubscription = Logger.root.onRecord.listen((record) {
      // Process stdout/stderr are owned by the runtime; never close them.
      if (record.level >= Level.WARNING) {
        stderr.writeln('[${record.level.name}] ${record.message}');
      } else {
        stdout.writeln('[${record.level.name}] ${record.message}');
      }
    });
  }

  // ignore: cancel_subscriptions
  // Subscription lives for the process lifetime; cancellation happens
  // on re-entry (tests) via _installLogForwarder above.
  static StreamSubscription<LogRecord>? _logSubscription;
}
