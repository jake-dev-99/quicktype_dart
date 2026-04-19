import '../args.dart';

/// Rust language specific options for quicktype code generation.
@Deprecated('Use RustRendererOptions instead — removal planned for v0.4.0')
class RustArgs {
  RustArgs._();

  static Map<String, Arg> get args => {
        density.name: density,
        visibility.name: visibility,
        deriveDebug.name: deriveDebug,
        deriveClone.name: deriveClone,
        derivePartialEq.name: derivePartialEq,
        edition2018.name: edition2018,
        leadingComments.name: leadingComments,
        skipSerializingNone.name: skipSerializingNone,
      };

  static EnumArg<Density> get density => EnumArg<Density>('density');

  static EnumArg<RustVisibility> get visibility =>
      EnumArg<RustVisibility>('visibility');

  static BoolArg get deriveDebug => BoolArg('derive-debug');
  static BoolArg get deriveClone => BoolArg('derive-clone');
  static BoolArg get derivePartialEq => BoolArg('derive-partial-eq');
  static BoolArg get edition2018 => BoolArg('edition-2018');
  static BoolArg get leadingComments => BoolArg('leading-comments');
  static BoolArg get skipSerializingNone => BoolArg('skip-serializing-none');
}
