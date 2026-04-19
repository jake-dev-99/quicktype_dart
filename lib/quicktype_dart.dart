/// Typed data classes generated from JSON, on every platform Flutter runs on.
///
/// Give `quicktype_dart` a JSON sample and a target language (Dart, Kotlin,
/// Swift, TypeScript, and 18 others) and it produces an idiomatic typed
/// model with `fromJson` / `toJson`.
///
/// Two entry points:
///
///   * [QuicktypeDart.generate] — runtime generation from any JSON-encodable
///     Dart value. Use this for on-demand conversions.
///   * The `build_runner` builders (see `build.yaml`) — compile-time
///     generation from `*.qt.json` files. Use this for permanent models
///     that should live next to your source files.
///
/// Pass language-specific options via a typed [RendererOptions] subclass —
/// `DartRendererOptions`, `KotlinRendererOptions`, `SwiftRendererOptions`,
/// and so on. Null fields are omitted, so anything you don't set inherits
/// quicktype-core's default.
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
///
/// Under the hood, `quicktype_dart` runs the full quicktype-core JS engine
/// in-process: via an embedded QuickJS runtime on native platforms (loaded
/// through FFI) and via `dart:js_interop` on Flutter Web. See the package
/// README for platform support, remote-bundle configuration, and the
/// `BundleSource` API.
library;

export 'src/bundle_source.dart'
    show BundleSource, EmbeddedBundleSource, RemoteBundleSource;
export 'src/quicktype_dart.dart' show GenerateTransport, QuicktypeDart;

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
export 'src/utils/validator.dart' show SchemaValidator;
export 'src/utils/type_infer.dart' show inferLangType;
