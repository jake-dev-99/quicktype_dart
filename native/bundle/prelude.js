// Prelude: minimal environment so the bundle can load under QuickJS.
globalThis.process = globalThis.process || { env: {}, stdout: {}, stderr: {}, nextTick: (fn) => fn() };
globalThis.self = globalThis;
// No-op polyfills — quicktype only pulls these in via unused stream/readable-stream deps.
globalThis.AbortController = class {
  constructor() { this.signal = { aborted: false, addEventListener() {}, removeEventListener() {} }; }
  abort() { this.signal.aborted = true; }
};
globalThis.AbortSignal = globalThis.AbortController.prototype.signal?.constructor ?? class {};
