/// Cross-platform type generation from JSON.
///
/// Use [QuicktypeDart.generate] for runtime, in-memory JSON → code, or wire
/// up the `build_runner` builders declared in [build.yaml] for build-time
/// generation from `*.qt.json` files.
///
/// ```dart
/// import 'package:quicktype_dart/quicktype_dart.dart';
///
/// final dartSource = await QuicktypeDart.generate(
///   label: 'User',
///   data: [{'id': 1, 'name': 'Jake'}],
///   target: TargetType.dart,
///   options: const DartRendererOptions(useFreezed: true),
/// );
/// ```
library;

export 'src/bundle_source.dart'
    show BundleSource, EmbeddedBundleSource, RemoteBundleSource;
export 'src/facade.dart' show GenerateTransport, QuicktypeDart;

// Types
export 'src/models/type.dart'
    show DefaultPaths, SourceType, TargetType, TypeConfig, TypeEnum;

// Commands / results
export 'src/models/command.dart' show QuicktypeCommand;
export 'src/models/result.dart' show QuicktypeResult;

// Typed renderer options — `DartRendererOptions`, `KotlinRendererOptions`,
// `SwiftRendererOptions`, etc. Plus the enums they reference
// (`CSharpFramework`, `NamingStyle`, etc.).
export 'src/models/options/options.dart';
export 'src/models/renderer_options.dart' show RendererOptions;
export 'src/models/enums.dart';

// Config + orchestration
export 'src/config.dart' show Config, ConfigException;
export 'src/quicktype.dart' show Quicktype, QuicktypeException;

// Utilities
export 'src/utils/logging.dart' show Log;
export 'src/utils/type_infer.dart' show inferLangType;
