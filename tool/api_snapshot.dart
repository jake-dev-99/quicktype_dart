// Captures a textual snapshot of the public API surface of
// `package:quicktype_dart/quicktype_dart.dart` into
// `tool/api_snapshot.txt`. Runs in CI on every PR — if the snapshot
// diffs, the PR must either update the committed file (for an
// intentional change) or revert the offending API change.
//
// The snapshot lists every exported symbol with its kind (class /
// enum / function / getter / typedef / field / constructor / method),
// sorted deterministically. Diffs are easy to read in code review.
//
// Modes:
//   --write  — regenerate tool/api_snapshot.txt from current sources.
//   --check  — compare the generated snapshot to the committed file,
//              exit 1 on drift with a unified diff on stderr.
//   (default: --check)

// ignore_for_file: deprecated_member_use
//
// analyzer's Element API is mid-migration from ElementX to ElementX2;
// the old surface remains available but emits deprecation warnings.
// We'll track the migration separately in Batch H.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

const String _snapshotPath = 'tool/api_snapshot.txt';
const String _publicBarrel = 'lib/quicktype_dart.dart';

void main(List<String> args) async {
  final write = args.contains('--write');

  final repoRoot = Directory.current.path;
  final collection = AnalysisContextCollection(
    includedPaths: [p.join(repoRoot, 'lib')],
  );
  final session = collection.contextFor(p.join(repoRoot, 'lib')).currentSession;
  final lib = await session.getResolvedLibrary(
    p.join(repoRoot, _publicBarrel),
  );
  if (lib is! ResolvedLibraryResult) {
    stderr.writeln('api_snapshot: failed to resolve $_publicBarrel');
    exit(2);
  }

  final exports = _collectExports(lib.element);
  final snapshot = _renderSnapshot(exports);

  if (write) {
    File(_snapshotPath).writeAsStringSync(snapshot);
    stdout.writeln('api_snapshot: wrote $_snapshotPath '
        '(${snapshot.split('\n').length} lines)');
    return;
  }

  final existing = File(_snapshotPath);
  if (!existing.existsSync()) {
    stderr.writeln('api_snapshot: $_snapshotPath missing. '
        'Run `dart run tool/api_snapshot.dart --write` to generate.');
    exit(1);
  }
  if (existing.readAsStringSync() != snapshot) {
    stderr.writeln('api_snapshot: API DRIFT DETECTED');
    stderr.writeln('Run `dart run tool/api_snapshot.dart --write` if '
        'intentional, and add a CHANGELOG entry.');
    stderr.writeln('\n--- committed ($_snapshotPath)');
    stderr.writeln('+++ current\n');
    _diffLines(existing.readAsStringSync(), snapshot, stderr.writeln);
    exit(1);
  }
  stdout.writeln('api_snapshot: ok (${snapshot.split('\n').length} lines)');
}

List<String> _collectExports(LibraryElement lib) {
  final symbols = <String>{};

  void emit(Element element) {
    if (element.isPrivate || element.name == null || element.name!.isEmpty) {
      return;
    }
    final name = element.name!;

    if (element is ClassElement) {
      symbols.add('class $name');
      for (final f in element.fields) {
        if (!f.isPrivate) {
          symbols.add(
              '  ${f.isStatic ? "static " : ""}field $name.$name.${f.name}: ${_typeLabel(f.type.toString())}');
        }
      }
      for (final c in element.constructors) {
        if (!c.isPrivate) {
          final cname = c.name.isEmpty ? '' : '.${c.name}';
          symbols.add('  ctor $name$cname(${_paramList(c.parameters)})');
        }
      }
      for (final m in element.methods) {
        if (!m.isPrivate) {
          symbols.add(
              '  ${m.isStatic ? "static " : ""}method $name.${m.name}(${_paramList(m.parameters)}): ${_typeLabel(m.returnType.toString())}');
        }
      }
      for (final g in element.accessors) {
        if (!g.isPrivate && !g.isSynthetic) {
          final kind = g.isGetter ? 'get' : 'set';
          symbols.add(
              '  ${g.isStatic ? "static " : ""}$kind $name.${g.name}: ${_typeLabel(g.returnType.toString())}');
        }
      }
    } else if (element is EnumElement) {
      symbols.add('enum $name');
      for (final v in element.fields.where((f) => f.isEnumConstant)) {
        symbols.add('  value $name.${v.name}');
      }
    } else if (element is FunctionElement) {
      symbols.add(
          'function $name(${_paramList(element.parameters)}): ${_typeLabel(element.returnType.toString())}');
    } else if (element is TopLevelVariableElement) {
      symbols.add(
          '${element.isConst ? "const" : element.isFinal ? "final" : "var"} $name: ${_typeLabel(element.type.toString())}');
    } else if (element is TypeAliasElement) {
      symbols
          .add('typedef $name = ${_typeLabel(element.aliasedType.toString())}');
    }
  }

  // Walk every element exported from the public barrel (including
  // transitive re-exports).
  for (final export in lib.exportNamespace.definedNames.values) {
    emit(export);
  }

  final sorted = symbols.toList()..sort();
  return sorted;
}

String _renderSnapshot(List<String> lines) {
  final buf = StringBuffer()
    ..writeln(
        '# Public API surface of package:quicktype_dart/quicktype_dart.dart')
    ..writeln('# Generated by tool/api_snapshot.dart — do not edit by hand.')
    ..writeln('# CI fails if this file drifts without an intentional '
        '`dart run tool/api_snapshot.dart --write`.')
    ..writeln();
  for (final l in lines) {
    buf.writeln(l);
  }
  return buf.toString();
}

String _paramList(List<ParameterElement> params) {
  return params.map((p) {
    final req = p.isRequiredPositional || p.isRequiredNamed ? 'req ' : '';
    final named = p.isNamed ? '{${p.name}}' : p.name;
    return '$req${_typeLabel(p.type.toString())} $named';
  }).join(', ');
}

String _typeLabel(String raw) => raw.replaceAll('*', '');

void _diffLines(String a, String b, void Function(String) emit) {
  final aLines = a.split('\n');
  final bLines = b.split('\n');
  for (var i = 0; i < aLines.length || i < bLines.length; i++) {
    final ai = i < aLines.length ? aLines[i] : null;
    final bi = i < bLines.length ? bLines[i] : null;
    if (ai != bi) {
      if (ai != null) emit('- $ai');
      if (bi != null) emit('+ $bi');
    }
  }
}
