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
/// );
/// ```
library quicktype_dart;

export 'src/quicktype_dart.dart' show QuicktypeDart;

// Types
export 'src/models/type.dart'
    show DefaultPaths, SourceType, TargetType, TypeConfig, TypeEnum;

// Commands / results
export 'src/models/command.dart' show QuicktypeCommand;
export 'src/models/result.dart' show QuicktypeResult;

// Args surface (Arg base classes + all lang_*.dart + main_args + enums)
export 'src/models/args.dart';

// Config + orchestration
export 'src/config.dart' show Config, ConfigException;
export 'src/quicktype.dart' show Quicktype, QuicktypeException;

// Utilities
export 'src/utils/logging.dart' show Log;
export 'src/utils/validator.dart' show SchemaValidator;
export 'src/utils/type_infer.dart' show inferLangType;
