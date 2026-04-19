// Entry module for the quicktype-core bundle shipped with quicktype_dart.
//
// Exposes a single global `qtConvert(lang, name, jsonString, rendererOptions)`
// that the C shim (`native/shim/qt_shim.c`) invokes. All four parameters
// arrive as real JS values — the C side interpolates them as pre-encoded
// JSON into the JS invoker so strings/objects come in typed, not stringified.
//
// Regenerate the bundle with:
//
//   cd native/bundle && npm install && ./build_bundle.sh
//
// Then regenerate bundle_data.c:
//
//   python3 native/shim/embed_bundle.py \
//     native/bundle/prelude.js \
//     native/bundle/quicktype_bundle.js \
//     native/shim/bundle_data.c

import {
  InputData,
  jsonInputForTargetLanguage,
  quicktype,
} from 'quicktype-core';

globalThis.qtConvert = async function (lang, name, jsonString, rendererOptions) {
  const jsonInput = jsonInputForTargetLanguage(lang);
  await jsonInput.addSource({ name, samples: [jsonString] });
  const inputData = new InputData();
  inputData.addInput(jsonInput);
  const result = await quicktype({
    inputData,
    lang,
    rendererOptions: rendererOptions || {},
  });
  return result.lines.join('\n');
};
