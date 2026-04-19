import '../args.dart';

/// PHP language specific options for quicktype code generation.
class PHPArgs {
  PHPArgs._();

  static Map<String, Arg> get args => {
        withGet.name: withGet,
        fastGet.name: fastGet,
        withSet.name: withSet,
        withClosing.name: withClosing,
        acronymStyle.name: acronymStyle,
      };

  static BoolArg get withGet => BoolArg('with-get');
  static BoolArg get fastGet => BoolArg('fast-get');
  static BoolArg get withSet => BoolArg('with-set');
  static BoolArg get withClosing => BoolArg('with-closing');

  static EnumArg<AcronymStyle> get acronymStyle =>
      EnumArg<AcronymStyle>('acronym-style');
}
