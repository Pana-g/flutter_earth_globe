// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(
      await _compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

let _isCompileStreamingSupported;
async function _compileStreaming(source, builtins) {
  _isCompileStreamingSupported ??= WebAssembly.compileStreaming(
    new Response(
      new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),
      {headers: {'Content-Type': 'application/wasm'}},
    ),
    builtins,
  ).then(() => false, (e) => e instanceof WebAssembly.CompileError);
  if (await _isCompileStreamingSupported) {
    return WebAssembly.compileStreaming(source, builtins);
  }
  return WebAssembly.compile(await (await source).arrayBuffer(), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            AB: (a, i, v) => a[i] = v,
      AC: o => o instanceof Uint16Array,
      AD: x0 => x0.platform,
      AE: () => globalThis.window.flutterConfiguration,
      AF: (x0,x1) => { x0.method = x1 },
      AG: x0 => globalThis.parseFloat(x0),
      AH: x0 => x0.clientWidth,
      AI: (x0,x1) => { x0.disabled = x1 },
      AJ: o => o.byteLength,
      B: s => printToConsole(s),
      BB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      BC: Function.prototype.call.bind(DataView.prototype.getUint16),
      BD: x0 => x0.navigator,
      BE: (x0,x1) => x0.attachShadow(x1),
      BF: (x0,x1) => { x0.noValidate = x1 },
      BG: (x0,x1) => x0.getComputedStyle(x1),
      BH: x0 => x0.innerWidth,
      BI: (x0,x1,x2,x3) => x0.drawImage(x1,x2,x3),
      BJ: (x0,x1,x2,x3) => x0.putImageData(x1,x2,x3),
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      CC: Function.prototype.call.bind(DataView.prototype.setUint16),
      CD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      CE: x0 => x0.preventDefault(),
      CF: x0 => x0.isConnected,
      CG: x0 => x0.documentElement,
      CH: (x0,x1) => x0.removeChild(x1),
      CI: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => x0.drawImage(x1,x2,x3,x4,x5,x6,x7,x8,x9),
      CJ: x0 => x0.arrayBuffer(),
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: Function.prototype.call.bind(String.prototype.toLowerCase),
      DC: o => o instanceof Int16Array,
      DD: Date.now,
      DE: (x0,x1) => x0.contains(x1),
      DF: x0 => x0.click(),
      DG: x0 => x0.computedStyleMap(),
      DH: x0 => x0.firstChild,
      DI: (x0,x1) => x0.getContext(x1),
      DJ: (x0,x1) => { x0.height = x1 },
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      EC: Function.prototype.call.bind(DataView.prototype.getInt16),
      ED: (x0,x1,x2) => x0.setAttribute(x1,x2),
      EE: (x0,x1) => x0.focus(x1),
      EF: (x0,x1) => x0.getElementsByClassName(x1),
      EG: (x0,x1) => x0.get(x1),
      EH: x0 => x0.viewConstraints,
      EI: (x0,x1) => { x0.height = x1 },
      EJ: (x0,x1) => { x0.width = x1 },
      F: () => new Error().stack,
      FB: () => ({}),
      FC: Function.prototype.call.bind(DataView.prototype.setInt16),
      FD: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      FE: (x0,x1) => x0.closest(x1),
      FF: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      FG: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      FH: x0 => x0.hostElement,
      FI: (x0,x1) => { x0.width = x1 },
      FJ: x0 => x0.convertToBlob(),
      G: s => JSON.stringify(s),
      GB: (o, p, v) => o[p] = v,
      GC: o => o instanceof Uint8ClampedArray,
      GD: x0 => x0.style,
      GE: (x0,x1) => x0.getAttribute(x1),
      GF: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      GG: x0 => x0.matches,
      GH: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      GI: (x0,x1) => x0.transferFromImageBitmap(x1),
      GJ: (x0,x1,x2) => new ImageData(x0,x1,x2),
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: () => [],
      HC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      HD: (x0,x1) => x0.createElement(x1),
      HE: x0 => x0.activeElement,
      HF: (x0,x1) => x0.contains(x1),
      HG: (x0,x1) => x0.matchMedia(x1),
      HH: x0 => ({runApp: x0}),
      HI: x0 => x0.height,
      HJ: (x0,x1) => x0.getContext(x1),
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: (a, i) => a.push(i),
      IC: Function.prototype.call.bind(DataView.prototype.setInt8),
      ID: x0 => x0.body,
      IE: (x0,x1) => x0.add(x1),
      IF: (s) => +s,
      IG: x0 => x0.matches,
      IH: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      II: x0 => x0.width,
      IJ: (x0,x1) => new OffscreenCanvas(x0,x1),
      J: (s, p, i) => s.lastIndexOf(p, i),
      JB: x0 => x0.random(),
      JC: Function.prototype.call.bind(DataView.prototype.getInt8),
      JD: x0 => x0.remove(),
      JE: x0 => x0.classList,
      JF: x0 => x0.target,
      JG: x0 => x0.timeStamp,
      JH: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      JI: x0 => x0.rasterEndMilliseconds,
      JJ: x0 => x0.allocationSize(),
      K: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      KB: o => o,
      KC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      KD: (x0,x1) => x0.getPropertyValue(x1),
      KE: x0 => x0.data,
      KF: (x0,x1) => x0.dispatchEvent(x1),
      KG: (x0,x1) => x0.hasAttribute(x1),
      KH: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      KI: x0 => x0.rasterStartMilliseconds,
      KJ: (x0,x1) => x0.copyTo(x1),
      L: o => o === undefined,
      LB: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      LC: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      LD: (x0,x1) => x0.warn(x1),
      LE: x0 => x0.scrollTop,
      LF: (x0,x1) => x0.createEvent(x1),
      LG: x0 => x0.type,
      LH: () => typeof dartUseDateNowForTicks !== "undefined",
      LI: x0 => x0.imageBitmaps,
      LJ: (x0,x1) => x0.toDataURL(x1),
      M: o => String(o),
      MB: () => globalThis.Math,
      MC: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      MD: x0 => x0.console,
      ME: (handle) => clearTimeout(handle),
      MF: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      MG: (x0,x1) => x0.getModifierState(x1),
      MH: () => Date.now(),
      MI: x0 => x0.canvasKitMaximumSurfaces,
      MJ: x0 => x0.format,
      N: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      NB: b => !!b,
      NC: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      ND: (x0,x1) => { x0.id = x1 },
      NE: (x0,x1) => x0.removeAttribute(x1),
      NF: x0 => x0.readText(),
      NG: x0 => x0.buttons,
      NH: () => 1000 * performance.now(),
      NI: x0 => x0.debugSkipFontRetryDelay,
      NJ: (x0,x1,x2,x3,x4) => x0.getImageData(x1,x2,x3,x4),
      O: (x0,x1) => x0.didCreateEngineInitializer(x1),
      OB: x0 => new Int8Array(x0),
      OC: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      OD: s => s.trimLeft(),
      OE: (x0,x1) => { x0.value = x1 },
      OF: x0 => x0.clipboard,
      OG: x0 => x0.ctrlKey,
      OH: x0 => new Uint8Array(x0),
      OI: (x0,x1,x2) => x0.set(x1,x2),
      OJ: x0 => x0.data,
      P: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      PB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      PC: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      PD: (o, p, r) => o.replaceAll(p, () => r),
      PE: (x0,x1) => { x0.value = x1 },
      PF: (x0,x1) => x0.writeText(x1),
      PG: x0 => x0.getBoundingClientRect(),
      PH: (x0,x1,x2) => x0.slice(x1,x2),
      PI: x0 => x0.fontFallbackBaseUrl,
      PJ: x0 => x0.hostElement,
      Q: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      QB: x0 => new Uint8Array(x0),
      QC: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      QD: (x0,x1) => x0[x1],
      QE: x0 => x0.value,
      QF: x0 => x0.unlock(),
      QG: x0 => x0.y,
      QH: (x0,x1) => x0.decode(x1),
      QI: (a, i) => a.splice(i, 1),
      QJ: x0 => x0.location,
      R: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      RB: x0 => new Uint8ClampedArray(x0),
      RC: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      RD: x0 => x0.length,
      RE: x0 => x0.selectionDirection,
      RF: (x0,x1) => x0.lock(x1),
      RG: x0 => x0.x,
      RH: (x0,x1) => x0.adoptText(x1),
      RI: a => a.pop(),
      RJ: (x0,x1) => x0.getModifierState(x1),
      S: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      SB: x0 => new Int16Array(x0),
      SC: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      SD: (x0,x1) => x0.exec(x1),
      SE: x0 => x0.selectionStart,
      SF: x0 => x0.orientation,
      SG: x0 => x0.top,
      SH: x0 => x0.first(),
      SI: x0 => new WeakRef(x0),
      SJ: x0 => x0.metaKey,
      T: x0 => new Promise(x0),
      TB: x0 => new Uint16Array(x0),
      TC: x0 => x0.history,
      TD: s => s.trim(),
      TE: x0 => x0.selectionEnd,
      TF: (x0,x1) => x0.querySelector(x1),
      TG: x0 => x0.left,
      TH: x0 => x0.next(),
      TI: x0 => x0.deref(),
      TJ: x0 => x0.altKey,
      U: (x0,x1,x2) => x0.call(x1,x2),
      UB: x0 => new Int32Array(x0),
      UC: () => globalThis.window,
      UD: (a, s) => a.join(s),
      UE: x0 => x0.value,
      UF: (x0,x1) => { x0.content = x1 },
      UG: x0 => x0.offsetTop,
      UH: x0 => x0.current(),
      UI: () => globalThis.WeakRef,
      UJ: x0 => x0.ctrlKey,
      V: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      VB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      VC: x0 => x0.search,
      VD: (x0,x1) => x0.error(x1),
      VE: x0 => x0.selectionDirection,
      VF: x0 => x0.head,
      VG: x0 => x0.scrollLeft,
      VH: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      VI: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      VJ: x0 => x0.isComposing,
      W: x0 => new Array(x0),
      WB: x0 => new Uint32Array(x0),
      WC: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      WD: () => globalThis.console,
      WE: x0 => x0.selectionStart,
      WF: (x0,x1) => { x0.name = x1 },
      WG: x0 => x0.offsetLeft,
      WH: x0 => x0.v8BreakIterator,
      WI: (a, s, e) => a.slice(s, e),
      WJ: x0 => x0.code,
      X: o => [o],
      XB: x0 => new Float32Array(x0),
      XC: x0 => x0.location,
      XD: s => s.trimRight(),
      XE: x0 => x0.selectionEnd,
      XF: (x0,x1) => { x0.title = x1 },
      XG: x0 => x0.offsetParent,
      XH: () => globalThis.Intl,
      XI: (handle) => clearInterval(handle),
      XJ: x0 => x0.repeat,
      Y: (o0, o1) => [o0, o1],
      YB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      YC: x0 => x0.pathname,
      YD: (x0,x1) => x0.requestAnimationFrame(x1),
      YE: (x0,x1) => { x0.name = x1 },
      YF: () => globalThis.document,
      YG: x0 => x0.offsetY,
      YH: (x0,x1) => x0.segment(x1),
      YI: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      YJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      Z: (o0, o1, o2) => [o0, o1, o2],
      ZB: x0 => new Float64Array(x0),
      ZC: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      ZD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      ZE: (x0,x1) => { x0.placeholder = x1 },
      ZF: (x0,x1) => x0.vibrate(x1),
      ZG: x0 => x0.offsetX,
      ZH: x0 => x0.index,
      ZI: () => Date.now(),
      ZJ: x0 => x0.extraAssets,
      a: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      aB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      aC: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      aD: x0 => x0.now(),
      aE: (x0,x1) => { x0.autocomplete = x1 },
      aF: (o, p) => p in o,
      aG: x0 => x0.deltaMode,
      aH: x0 => x0.next(),
      aI: x0 => x0.pop(),
      aJ: x0 => x0.fontManifest,
      b: (x0,x1,x2) => { x0[x1] = x2 },
      bB: x0 => new ArrayBuffer(x0),
      bC: o => Object.keys(o),
      bD: x0 => x0.performance,
      bE: (x0,x1) => { x0.type = x1 },
      bF: x0 => x0.arrayBuffer(),
      bG: x0 => x0.deltaY,
      bH: x0 => x0.value,
      bI: x0 => x0.close(),
      bJ: x0 => x0.assetManifest,
      c: o => o,
      cB: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      cC: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      cD: (x0,x1) => x0.unregister(x1),
      cE: (x0,x1) => { x0.name = x1 },
      cF: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      cG: x0 => x0.deltaX,
      cH: x0 => x0.done,
      cI: (x0,x1,x2,x3,x4,x5) => x0.createImageBitmap(x1,x2,x3,x4,x5),
      cJ: x0 => x0.buildConfig,
      d: (o, p) => o[p],
      dB: (x0,x1,x2) => new DataView(x0,x1,x2),
      dC: f => f.dartFunction,
      dD: () => globalThis.window.FinalizationRegistry,
      dE: (x0,x1) => { x0.placeholder = x1 },
      dF: x0 => x0.status,
      dG: x0 => x0.wheelDeltaY,
      dH: (o, m, a) => o[m].apply(o, a),
      dI: (x0,x1) => x0.createImageBitmap(x1),
      dJ: x0 => x0.length,
      e: () => globalThis,
      eB: (o, p) => o[p],
      eC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      eD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      eE: (x0,x1) => { x0.scrollTop = x1 },
      eF: (x0,x1) => x0.fetch(x1),
      eG: x0 => x0.wheelDeltaX,
      eH: x0 => x0.iterator,
      eI: x0 => new Blob(x0),
      eJ: x0 => x0.getReader(),
      f: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      fB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      fC: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      fD: x0 => new window.FinalizationRegistry(x0),
      fE: x0 => x0.tagName,
      fF: x0 => x0.content,
      fG: x0 => x0.bottom,
      fH: () => globalThis.Symbol,
      fI: x0 => x0.close(),
      fJ: x0 => x0.value,
      g: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gB: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      gC: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      gD: x0 => x0.scale,
      gE: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      gF: x0 => x0.document,
      gG: x0 => x0.right,
      gH: (x0,x1) => new Intl.Segmenter(x0,x1),
      gI: x0 => x0.naturalHeight,
      gJ: x0 => x0.done,
      h: (x0,x1) => ({addView: x0,removeView: x1}),
      hB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      hC: (o, i) => o[i],
      hD: x0 => x0.visualViewport,
      hE: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      hF: x0 => x0.language,
      hG: x0 => x0.clientY,
      hH: x0 => x0.Segmenter,
      hI: x0 => x0.naturalWidth,
      hJ: x0 => x0.read(),
      i: (l, r) => l === r,
      iB: o => o.byteOffset,
      iC: o => o.length,
      iD: x0 => x0.devicePixelRatio,
      iE: x0 => x0.visibilityState,
      iF: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      iG: x0 => x0.clientX,
      iH: x0 => x0.buffer,
      iI: (x0,x1) => { x0.src = x1 },
      iJ: x0 => x0.body,
      j: (string, token) => string.split(token),
      jB: o => o.buffer,
      jC: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      jD: (d, digits) => d.toFixed(digits),
      jE: x0 => x0.hasFocus(),
      jF: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      jG: x0 => x0.changedTouches,
      jH: x0 => x0.wasmMemory,
      jI: x0 => x0.displayHeight,
      jJ: x0 => x0.assetBase,
      k: o => o instanceof Array,
      kB: (b, o) => new DataView(b, o),
      kC: x0 => x0.state,
      kD: x0 => x0.maxHeight,
      kE: x0 => x0.relatedTarget,
      kF: (x0,x1) => x0.querySelector(x1),
      kG: x0 => x0.key,
      kH: () => globalThis.window._flutter_skwasmInstance,
      kI: x0 => x0.displayWidth,
      kJ: x0 => x0.loader,
      l: (a, i) => a[i],
      lB: (b, o, l) => new DataView(b, o, l),
      lC: x0 => x0.hash,
      lD: x0 => x0.maxWidth,
      lE: x0 => x0.index,
      lF: (x0,x1) => x0.querySelectorAll(x1),
      lG: x0 => x0.identifier,
      lH: () => new TextDecoder(),
      lI: x0 => x0.duration,
      lJ: () => globalThis._flutter,
      m: a => a.length,
      mB: Function.prototype.call.bind(DataView.prototype.getUint8),
      mC: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      mD: x0 => x0.minHeight,
      mE: x0 => x0.unicode,
      mF: x0 => x0.tabIndex,
      mG: x0 => x0.touches,
      mH: (map, o, v) => map.set(o, v),
      mI: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      n: (string, times) => string.repeat(times),
      nB: Function.prototype.call.bind(DataView.prototype.setUint8),
      nC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      nD: x0 => x0.minWidth,
      nE: (x0,x1) => { x0.lastIndex = x1 },
      nF: x0 => x0.parentNode,
      nG: x0 => x0.pressure,
      nH: (map, o) => map.get(o),
      nI: (x0,x1) => x0.decode(x1),
      o: (decoder, codeUnits) => decoder.decode(codeUnits),
      oB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      oC: x0 => x0.state,
      oD: x0 => x0.height,
      oE: x0 => x0.dotAll,
      oF: x0 => x0.clientY,
      oG: x0 => x0.tiltY,
      oH: () => new WeakMap(),
      oI: x0 => x0.image,
      p: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      pB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      pC: (x0,x1,x2) => x0.addEventListener(x1,x2),
      pD: x0 => x0.width,
      pE: x0 => x0.ignoreCase,
      pF: x0 => x0.clientX,
      pG: x0 => x0.tiltX,
      pH: (x0,x1,x2) => x0.insertBefore(x1,x2),
      pI: x0 => x0.close(),
      q: () => new TextDecoder("utf-8", {fatal: true}),
      qB: (t, s) => t.set(s),
      qC: (x0,x1) => x0.go(x1),
      qD: x0 => x0.screen,
      qE: x0 => x0.multiline,
      qF: x0 => x0.shiftKey,
      qG: x0 => x0.pointerType,
      qH: x0 => x0.id,
      qI: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      r: () => new TextDecoder("utf-8", {fatal: false}),
      rB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      rC: (x0,x1) => x0.append(x1),
      rD: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      rE: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      rF: x0 => x0.disconnect(),
      rG: x0 => x0.pointerId,
      rH: x0 => x0.offsetHeight,
      rI: x0 => new window.ImageDecoder(x0),
      s: s => s.toUpperCase(),
      sB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      sC: (x0,x1) => { x0.textContent = x1 },
      sD: (x0,x1) => x0.removeProperty(x1),
      sE: x0 => x0.keyCode,
      sF: x0 => new Intl.Locale(x0),
      sG: x0 => x0.getCoalescedEvents(),
      sH: x0 => x0.offsetWidth,
      sI: x0 => x0.name,
      t: Object.is,
      tB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      tC: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      tD: (x0,x1) => x0.appendChild(x1),
      tE: (x0,x1) => x0.scrollIntoView(x1),
      tF: x0 => x0.region,
      tG: x0 => x0.blur(),
      tH: x0 => x0.stopPropagation(),
      tI: x0 => x0.repetitionCount,
      u: (x0,x1) => x0.test(x1),
      uB: Function.prototype.call.bind(DataView.prototype.getUint32),
      uC: x0 => x0.parentElement,
      uD: x0 => x0.debugShowSemanticsNodes,
      uE: x0 => x0.multiViewEnabled,
      uF: x0 => x0.script,
      uG: x0 => x0.button,
      uH: x0 => x0.disabled,
      uI: x0 => x0.frameCount,
      v: o => o,
      vB: Function.prototype.call.bind(DataView.prototype.setUint32),
      vC: (x0,x1) => x0.querySelectorAll(x1),
      vD: (o, c) => o instanceof c,
      vE: x0 => x0.parent,
      vF: x0 => x0.language,
      vG: (x0,x1) => x0.prepend(x1),
      vH: (x0,x1) => { x0.min = x1 },
      vI: x0 => x0.selectedTrack,
      w: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      wB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      wC: x0 => x0.length,
      wD: x0 => x0.vendor,
      wE: (x0,x1) => x0.replaceWith(x1),
      wF: x0 => x0.languages,
      wG: x0 => x0.innerHeight,
      wH: (x0,x1) => { x0.max = x1 },
      wI: x0 => x0.completed,
      x: x0 => x0.flags,
      xB: Function.prototype.call.bind(DataView.prototype.getInt32),
      xC: (x0,x1) => x0.item(x1),
      xD: (x0,x1) => x0.createTextNode(x1),
      xE: (x0,x1) => { x0.className = x1 },
      xF: (x0,x1) => x0.observe(x1),
      xG: x0 => x0.height,
      xH: (x0,x1) => { x0.disabled = x1 },
      xI: x0 => x0.ready,
      y: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      yB: Function.prototype.call.bind(DataView.prototype.setInt32),
      yC: x0 => x0.userAgent,
      yD: (x0,x1) => { x0.nonce = x1 },
      yE: (x0,x1) => { x0.tabIndex = x1 },
      yF: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      yG: x0 => x0.width,
      yH: (x0,x1) => { x0.scrollLeft = x1 },
      yI: x0 => x0.tracks,
      z: o => o instanceof RegExp,
      zB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      zC: x0 => x0.maxTouchPoints,
      zD: x0 => x0.nonce,
      zE: (x0,x1) => { x0.action = x1 },
      zF: x0 => new ResizeObserver(x0),
      zG: x0 => x0.clientHeight,
      zH: (x0,x1) => { x0.spellcheck = x1 },
      zI: () => globalThis.window.ImageDecoder,

    };

    const baseImports = {
      _: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
