# Quicktype Dart 🚀  

Quicktype Dart is a lightweight wrapper around the powerful [quicktype](https://quicktype.io/) CLI tool which supports generating **type-safe models** for multiple programming languages, including Dart, Swift, Kotlin, TypeScript, and more. No more `Map<String, dynamic>` soup or manually updating models across each platform – define your data once, then generate consistent and type-safe models for every platform you need.  

To quickly get started:

1. Run `dart pub add quicktype_dart`
2. Create a top-level `models/` folder with a .json, .graphqls, or .ts file containing sample data
3. Create a `models/` folder within each target directory

    >Quicktype Dart looks for the following globs by default:
    > |Lang|Target|
    > |----|------|
    > |C|src/**/models|
    > |Dart|lib/**/models|
    > |Kotlin|android/app/src/main/kotlin/**/models/|
    > |Java|android/app/src/main/java/**/models/|
    > |Swift|ios/**/models/|
    > |Web|web/**/models/|

4. Run `dart run quicktype_dart` and review the generated code.
5. That's it! Drink a beer (or a mai-tai mocktail - I won't judge)

---

## What Quicktype Dart Actually Does  

Quicktype originally launched in 2017 and has grown into one of the best JSON-to-model generators out there, supporting over 20+ languages. Quicktype Dart builds on top of that and adds a **configurable, Dart-native wrapper**. With a single config file (or command-line flags). This allows you to

- **Source** any json, graphql, or typescript file(s)
- **Target** any number of languages (Dart, Swift, Kotlin, etc.).  

Also? It handles custom objects and `fromJson`/`toJson` calls automatically

No 3rd-party websites, no circus-level file juggling. Just clean, consistent models from a single source of truth.

***For more info on quicktype, start with their FAQ [here](https://github.com/glideapps/quicktype/blob/master/FAQ.md)***

---

## Why I Built This  

Cross-platform type safety in dart creates a smooth blend of migraines and panic attacks when working with complicated datasets. Pigeon is an incredible tool, but requires model declaration inside of a single, isolated Pigeon file. This can create a lot of excess chaos. Alternatively, the FFI and FFI Gen libraries are super powerful, but requires extending their native c counter-parts. This creates a lot of extra complexity if the model needs to inherit an internal class.

After wasting ***2 [[insert SFW expletive here]](https://sweary.com/) weeks*** debugging mismatched JSON fields between Dart and Kotlin on a large project, I began imagining what would happen if my future replacement being a weekend serial killer. This project is my attempt to solve a simple problem: **making cross-platform type safety simple and maintainable.**

Here’s the Dart-specific pain points I kept running into:  


- **Pigeon**: Amazing for method channels but a nightmare for big datasets. Models declared in a single Pigeon file get messy fast, and nested data types turn into `Map<String, dynamic>` chaos.
- **FFI**: Powerful for low-level interop, but making Dart models C-compatible adds complexity. You end up writing verbose structs, creating more fragility as data is parsed from Dart -> C -> Kotlin / Swift / etc
- **Handwritten Platform-Specific Models**: Wastes hours of work any time someone changes an API field. This sucks. Don't do it.

Quicktype Dart solves these problems by allowing you to:  

1. Define your data in one place, using JSON, GraphQL, or Typescript
2. Generate models for **multiple languages** in one step, with full type safety.  
3. Keep cross-platform models in sync easily — no duplication, no forgetting fields. If you jsonify a map in Dart, it will decode accurately in Kotlin.

## Features

#### ✅ Cross-Platform Type Safety

- Generate identical models for every language
- Eliminate int? vs double? mismatches between platforms and other nuances

#### ✅ Supports Custom Objects

- Easily persist that Person object across every platform

#### ✅ Sourced by JSON, Typescript, or Graphql

- No intermediary C generation
- No lengthy single-file source of truth

#### ✅ No Boilerplate

- Auto-generates fromJson/toJson with proper null-safety
- Supports advanced Dart features (copyWith, json_serializable, Freezed)

#### ✅ Config-Driven Workflow

- Create a single quicktype.json file to configure sources and targets for your entire project
- Easily find dynamic target directories with glob patterns (ie, `api/**/*.json`)

#### ✅ Works with Existing Tools

- Generate Pigeon-compatible models
- Output C structs for FFI (roadmap)

---

## Known Issues and Drawbacks

⚠️ Requires Node.js

- Required as the backbone of quicktype

⚠️ Not a Silver Bullet

- Generated code usually works, but you still need to do your due diligence:
  - Verifying that the generated code matches what's expected
  - Reviewing edge cases (e.g., union types in TypeScript)
  - Manually handling platform-specific validation rules
  - Wiring up interoperability between platforms (more to come there)

⚠️ Currently limited to Dart-supported languages

- Works directly with Dart, C, CPP, Java, Javascript, Kotlin, Objective C, Swift, and Typescript
- Other native quicktype types are still supported by adding quicktype args to the run command. This will pass through the args directly to the quicktype command.

```bash
dart run quicktype_dart -s schema schema.json -o src/nodejs/Models.ts
```

⚠️ No Build Runner (Yet)

- Requires explicit dart run quicktype_dart generate calls
- Auto-generation during builds is planned

⚠️ No Interoperability (yet)

- Still requires Platform Channels to communicate cross-platform. Right now the biggest assurance is that dart -> json -> kotlin will work as expected.
- Future plans are to fully support both Platform Channels and FFI, allowing you the choice between the two

⚠️ Quicktype is open-source

- This means it may become stale or outdated over time, or it could have breaking changes introduced. Each quicktype release will be bundled into an updated version of Quicktype Dart.
- To get the current version of quicktype, run `dart run quicktype_dart --version`

---

## Installation  

**Step 1**: Add the package to your `pubspec.yaml` as a dev dependency:  

```bash
flutter pub add --dev quicktype_dart
```

**Step 2**: Install Quicktype itself (requires Node.js):  

```bash
npm install --global quicktype
```

**Step 3**: Try it out! Generate models directly from a JSON file:  

```bash
dart run quicktype_dart generate --source data/user.json --target dart
```

---

## Advanced Configuration  

### Using a Config File  


For larger projects, define your sources and language targets in a `quicktype.json`:  

```json
{
  "version": "1.0.0",
  "description": "Configures the quicktype code generation for this project",

  "global-options": {
    "enable-ffi-bridge": false
  },

  "quicktime-options": {
    "all-properties-optional": false,
    "alphabetize-properties": true,
    "debug": "print-graph,print-reconstitution,print-times",
    "graphql-introspect": "https://api.example.com/graphql",
    "graphql-schema": "schema.graphql",
    "help": false,
    "http-header": [
      "Authorization: Bearer token123",
      "Content-Type: application/json"
    ],
    "http-method": "POST",
    "lang": "dart",
    "no-boolean-strings": false,
    "no-combine-classes": true,
    "no-date-times": false,
    "no-enums": false,
    "no-ignore-json-refs": false,
    "no-integer-strings": true,
    "no-maps": true,
    "no-uuids": true,
    "out": "models/output.dart",
    "quiet": false,
    "src": "input.json",
    "src-lang": "json",
    "src-urls": [
      "https://api.example.com/schema1",
      "https://api.example.com/schema2"
    ],
    "telemetry": "disable",
    "top-level": "RootType",
    "version": false
  },

  "sources": {
    "json": [
      {
        "path": "**/models/**"
      }
    ],
    "jsonschema": [
      {
        "path": "**/models/**"
      }
    ],
    "graphql": [
      {
        "path": "**/models/**"
      }
    ],
    "typescript": [
      {
        "path": "**/models/**"
      }
    ]
  },

  "targets": {
    "c": [
      {
        "path": "models/",
        "description": "C Model Classes",
        "options": {
          "enumerator-style": "upper-underscore-case",
          "hashtable-size": "64",
          "integer-size": "int64_t",
          "member-style": "underscore-case",
          "print-style": "print-formatted",
          "source-style": "single-source",
          "type-style": "pascal-case",
          "typedef-alias": "no-typedef"
        }
      }
    ],
    "cpp": [
      {
        "path": "models/",
        "description": "C++ Model Classes",
        "options": {
          "boost": true,
          "code-format": "with-struct",
          "const-style": "west-const",
          "enum-type": "",
          "enumerator-style": "upper-underscore-case",
          "hide-null-optional": false,
          "include-location": "local-include",
          "just-types": false,
          "member-style": "underscore-case",
          "namespace": "",
          "source-style": "single-source",
          "type-style": "pascal-case",
          "wstring": "use-string"
        }
      }
    ],
    "dart": [
      {
        "path": "models/",
        "description": "Dart Model Classes",
        "options": {
          "coders-in-class": false,
          "copy-with": false,
          "final-props": false,
          "from-map": false,
          "just-types": false,
          "null-safety": true,
          "part-name": "",
          "required-props": false,
          "use-freezed": false,
          "use-hive": false,
          "use-json-annotation": false
        }
      }
    ],
    "java": [
      {
        "path": "models/",
        "description": "Java Model Classes",
        "options": {
          "acronym-style": "original",
          "array-type": "array",
          "datetime-provider": "java8",
          "just-types": false,
          "lombok": false,
          "lombok-copy-annotations": true,
          "package": ""
        }
      }
    ],
    "javascript": [
      {
        "path": "models/",
        "description": "JavaScript Model Classes",
        "options": {
          "acronym-style": "original",
          "converters": "top-level",
          "raw-type": "json",
          "runtime-typecheck": true,
          "runtime-typecheck-ignore-unknown-properties": false
        }
      }
    ],
    "kotlin": [
      {
        "path": "models/",
        "description": "Kotlin Model Classes",
        "options": {
          "acronym-style": "original",
          "framework": "just-types",
          "package": ""
        }
      }
    ],
    "objc": [
      {
        "path": "models/",
        "description": "Objective-C Model Classes",
        "options": {
          "class-prefix": "",
          "extra-comments": false,
          "features": "all",
          "functions": false,
          "just-types": false
        }
      }
    ],
    "swift": [
      {
        "path": "models/",
        "description": "Swift Model Classes",
        "options": {
          "access-level": "internal",
          "acronym-style": "original",
          "alamofire": false,
          "coding-keys": true,
          "coding-keys-protocol": "",
          "density": "normal",
          "initializers": true,
          "just-types": false,
          "multi-file-output": false,
          "mutable-properties": false,
          "objective-c-support": false,
          "optional-enums": false,
          "protocol": "none",
          "sendable": false,
          "struct-or-class": "struct",
          "support-linux": false,
          "swift-5-support": false,
          "type-prefix": ""
        }
      }
    ],
    "typescript": [
      {
        "path": "models/",
        "description": "TypeScript Model Classes",
        "options": {
          "acronym-style": "original",
          "converters": "top-level",
          "explicit-unions": false,
          "just-types": false,
          "nice-property-names": false,
          "prefer-const-values": false,
          "prefer-types": false,
          "prefer-unions": false,
          "raw-type": "json",
          "readonly": false,
          "runtime-typecheck": true,
          "runtime-typecheck-ignore-unknown-properties": false
        }
      }
    ]
  }
}

```

Then, run:  

```bash  
dart run quicktype_dart generate --config quicktype.json
```

---

## Roadmap  

Quicktype Dart is evolving, and here’s what’s in the works:  

1. **Pigeon Integration**: Use Quicktype-generated models to automate method channel creation.  

   ```dart
   // Auto-generate Pigeon APIs based on your models  
   @HostApi()
   abstract class UserApi {
     User getUser();
   }
   ```

2. **FFI Support**: Generate low-level C structs alongside Dart models to streamline FFI interop.

   ```dart
   final class User extends Struct {
     @Pointer<Uint8>
     external String get name;
   }
   ```

3. **Build Runner Integration**: Add seamless build_runner support to trigger generation during builds.  

---

## Why Use This?  

**Use Quicktype Dart If**:  

- Your app needs to sync models across Flutter, iOS, and web.  
- APIs change frequently, and you hate fixing serialization bugs late in dev.  
- You prioritize consistency and simplicity for setup and maintenance.

**Skip It If**:  

- You’re building a small app with only a handful of models.  
- Serialization bugs don’t bother you (they should, though).  

---

## Getting Help  

### Common Problems  

**“Where’s my generated code?”**  

- Double-check paths in your `quicktype.json`.  
- Run the CLI with `--verbose` to see exactly what’s happening.  

**“Quicktype isn’t installed.”**  

```bash
which quicktype  # or use `npx quicktype` for local installs
```

**“Why not just use the Quicktype website?”**  

- Because manual copy-pasting isn’t scalable.
- You can’t version control generated models.
- It’s 2025 – let automation handle the boring stuff.

---

# IMPORTANT

This is very much an alpha release. It should work fine for most general applications, but make sure to vet all output thoroughly before integrating with any production code.

If you find any bugs or code improvements, file an issue, and I’ll get on it: [GitHub Issues](https://github.com/jake-dev-99/quicktype_dart/issues).

If you're tired of fumbling with serialization, mismatched types, or managing changes across different languages, Quicktype Dart has your back.  


## Roadmap (What’s Coming)  

- **Continued code-quality improvements** (always)
- **Pigeon Bridges**: Auto-generate method channels from your models  
- **FFI Helpers**: Generate C structs alongside Dart models
## When Things Break (They Will)  

**“Where’s my generated code?!”**  

- Run with `--verbose` to see where it’s looking  
- Check glob patterns in `quicktype.json`  

**“Quicktype isn’t installed!”**  

- Create an issue [here](https://github.com/yourusername/quicktype_dart/issues) with detailed info. Likely this is a configuration error as the quicktype binary is bundled with this package.

**“Why not just use native quicktype or [quicktype.io](https://www.quicktype.io)?”**  

- Version history is not well maintained
- Teams will end up with 5 slightly different model versions 
- Each run may result in different behavior depending on the passed arguments, creating additional scripting requirements

---

## Takeaway

This aims to save you many hours a month by:

- 🔄 Syncing models across Flutter/iOS/TypeScript  
- 🔥 Preventing serialization bugs in prod  
- 🧑💻 Onboarding devs without “Where are the models?!” chaos  

Try it once:  

```bash  
dart run quicktype_dart generate --source your_api.json --target dart  
```  

If it breaks, let me know [here](https://github.com/jake-dev-99/quicktype_dart/issues) and I'll get it resolved as quick as I can
If it works, go talk about it to that one teammate who's afraid of letting go of the past

More to come:

- Implement a build_runner function
- Improve cross-platform communication using either FFI or Platform Channels

---

## Limitations  

Quicktype Dart isn’t perfect yet and is a work in progress. Some caveats to keep in mind:  

- Your project must have Node.js installed for Quicktype to work.  
- There may be bugs and unexpected hangups as this package is continued to be produced