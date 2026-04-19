import '../args.dart';

/// Go language specific options for quicktype code generation.
class GoArgs {
  GoArgs._();

  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        justTypesAndPackage.name: justTypesAndPackage,
        package.name: package,
        multiFileTarget.name: multiFileTarget,
        fieldTags.name: fieldTags,
        omitEmpty.name: omitEmpty,
      };

  static BoolArg get justTypes => BoolArg('just-types');
  static BoolArg get justTypesAndPackage => BoolArg('just-types-and-package');
  static StringArg get package => StringArg('package');
  static BoolArg get multiFileTarget => BoolArg('multi-file-dest');
  static StringArg get fieldTags => StringArg('field-tags');
  static BoolArg get omitEmpty => BoolArg('omit-empty');
}
