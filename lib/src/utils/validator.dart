import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

import 'logging.dart';

/// Validates JSON files against JSON Schema definitions.
///
/// If a schema path isn't supplied, looks for a sibling `<basename>.schema.json`
/// next to the input file. Missing schemas don't fail validation — they warn
/// and pass through.
class SchemaValidator {
  final Map<String, JsonSchema> _schemaCache = {};

  /// Validate [jsonFile] against [schemaPath] (or its sibling schema).
  /// Returns `true` when the file matches the schema or no schema exists.
  Future<bool> validateJsonFile(File jsonFile, {String? schemaPath}) async {
    try {
      final effectiveSchemaPath = schemaPath ??
          p.join(
            p.dirname(jsonFile.path),
            '${p.basenameWithoutExtension(jsonFile.path)}.schema.json',
          );

      final schemaFile = File(effectiveSchemaPath);
      if (!schemaFile.existsSync()) {
        Log.warning(
          'Schema not found at $effectiveSchemaPath, skipping validation',
          'SchemaValidator',
        );
        return true;
      }

      final schema =
          _schemaCache[effectiveSchemaPath] ?? await _loadSchema(schemaFile);

      final jsonContent = await jsonFile.readAsString();
      final jsonData = jsonDecode(jsonContent);

      final validation = schema.validate(jsonData);
      if (!validation.isValid) {
        Log.severe(
          'JSON validation failed for ${jsonFile.path}: ${validation.errors}',
          'SchemaValidator',
        );
        return false;
      }

      Log.info(
          'JSON validation passed for ${jsonFile.path}', 'SchemaValidator');
      return true;
    } catch (e) {
      Log.severe('Error during validation: $e', 'SchemaValidator');
      return false;
    }
  }

  Future<JsonSchema> _loadSchema(File schemaFile) async {
    final schemaContent = await schemaFile.readAsString();
    final schema = JsonSchema.create(jsonDecode(schemaContent));
    _schemaCache[schemaFile.path] = schema;
    return schema;
  }
}
