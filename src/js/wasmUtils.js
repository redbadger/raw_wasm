const setProperty = (obj, propName, propVal) => (_ => obj)(obj[propName] = propVal)

// -----------------------------------------------------------------------------
// Unload all the exports of a WASM instance and package them into the `libName`
// property of the `hostFns` object
//
// The `hostFns` object uses a two-level namespace where the top level
// identifies the library name and the second level identifies the function
// within that library.
const packageWasmExports = (wasmObj, libName, hostFns) =>
  Object
  .keys(wasmObj.instance.exports)
  .reduce(
    (acc, exp) => (_ => acc)(acc[libName][exp] = wasmObj.instance.exports[exp]),
    setProperty(hostFns, libName, {})
  )

// -----------------------------------------------------------------------------
// Create a new instance of a WASM module passing in the `hostFns` object to
// satisfy any imports that module might have
// Once instantiated, the `hostsFns` object is then extended to include anything
// exported by the new WASM instance
const createWasmLib = (wasmSrc, wasmLibName, fnsImportedByWasm) =>
  WebAssembly
  .instantiateStreaming(fetch(wasmSrc), fnsImportedByWasm)
  .then(wasmObj => ({
      libName : wasmLibName,
      wasmObj : wasmObj,
      hostFns : packageWasmExports(wasmObj, wasmLibName, fnsImportedByWasm)
    }))

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------
export {
  createWasmLib,
}
