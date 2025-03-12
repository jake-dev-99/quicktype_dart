import '../args.dart';

/// Provides access to all core quicktype command-line arguments.
///
/// This utility class contains static getters to generate
/// properly formatted quicktype CLI arguments. Use this class to ensure
/// consistent argument formatting throughout your application.
///
/// Example:
/// ```dart
/// final args => [
///  .targetLang.withValue('dart'),
///  .src.withValue('schema.json'),
///  .target.withValue('target.dart'),
///  .sort,
/// ];
/// ```
class MainArgs {
  MainArgs({
    SimpleArg? noMaps,
  });

  @override
  String toString() {
    return argMap.values
        .where((element) => element.value != null)
        .map((element) => element.toString())
        .join(' ');
  }

  // This should pair 1-1 with the static getters below
  static Map<String, Arg> get argMap => {
        noMaps.name: noMaps,
        noEnums.name: noEnums,
        noUUIDs.name: noUUIDs,
        noDateTimes.name: noDateTimes,
        noIntegerStrings.name: noIntegerStrings,
        noBooleanStrings.name: noBooleanStrings,
        noCombineClasses.name: noCombineClasses,
        noIgnoreJsonRefs.name: noIgnoreJsonRefs,
        sort.name: sort,
        allPropertiesOptional.name: allPropertiesOptional,
        quiet.name: quiet,
        help.name: help,
        version.name: version,
        topLevel.name: topLevel,
        src.name: src,
        srcLang.name: srcLang,
        target.name: target,
        targetLang.name: targetLang,
        srcUrls.name: srcUrls,
        graphqlSchema.name: graphqlSchema,
        graphqlIntrospect.name: graphqlIntrospect,
        httpMethod.name: httpMethod,
        httpHeader.name: httpHeader,
        additionalSchema.name: additionalSchema,
        debugSingle.name: debugSingle,
        telemetry.name: telemetry,
      };

  /// Disables maps/dictionary types, representing them as objects instead
  static SimpleArg get noMaps => SimpleArg('no-maps');

  /// Disables enum types, representing them as strings instead
  static SimpleArg get noEnums => SimpleArg('no-enums');

  /// Disables UUID detection, representing them as strings instead
  static SimpleArg get noUUIDs => SimpleArg('no-uuids');

  /// Disables date/time detection, representing them as strings instead
  static SimpleArg get noDateTimes => SimpleArg('no-date-times');

  /// Disables integer String? detection, representing them as strings instead
  static SimpleArg get noIntegerStrings => SimpleArg('no-integer-strings');

  /// Disables boolean String? detection, representing them as strings instead
  static SimpleArg get noBooleanStrings => SimpleArg('no-boolean-strings');

  /// Disables class combination, generating a class for every object
  static SimpleArg get noCombineClasses => SimpleArg('no-combine-classes');

  /// Disables JSON references ($ref) resolution
  static SimpleArg get noIgnoreJsonRefs => SimpleArg('no-ignore-json-refs');

  /// Alphabetically sorts class properties
  static SimpleArg get sort => SimpleArg('alphabetize-properties');

  /// Makes all class properties optional
  static SimpleArg get allPropertiesOptional =>
      SimpleArg('all-properties-optional');

  /// Suppresses non-error target
  static SimpleArg get quiet => SimpleArg('quiet');

  /// Displays help message
  static SimpleArg get help => SimpleArg('help');

  /// Displays version information
  static SimpleArg get version => SimpleArg('version');

  // String? arguments (value required)

  /// Sets the name of the top-level type
  static StringArg get topLevel => StringArg('top-level');

  /// Sets the source file path
  static StringArg get src => StringArg('src');

  /// Sets the source Type/format
  static StringArg get srcLang => StringArg('src-lang');

  /// Sets the target file path
  static StringArg get target => StringArg('out');

  /// Sets the target Type
  static StringArg get targetLang => StringArg('lang');

  /// Sets URLs to fetch as source
  static StringArg get srcUrls => StringArg('src-urls');

  /// Sets the GraphQL schema file
  static StringArg get graphqlSchema => StringArg('graphql-schema');

  /// Sets the GraphQL introspection URL
  static StringArg get graphqlIntrospect => StringArg('graphql-introspect');

  /// Sets the HTTP method for URL requests
  static StringArg get httpMethod => StringArg('http-method');

  /// Sets HTTP headers for URL requests
  static StringArg get httpHeader => StringArg('http-header');

  /// Adds additional JSON Schema to use
  static StringArg get additionalSchema => StringArg('additional-schema');

  /// Enables debug target options
  static StringArg get debug => StringArg('debug');

  /// Enables a single debug option
  static StringArg get debugSingle => StringArg('debug');

  /// Controls telemetry settings
  static StringArg get telemetry => StringArg('telemetry');
}
