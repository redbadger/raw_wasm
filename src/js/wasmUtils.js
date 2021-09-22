const setProperty =
  (obj, propName, propVal) =>
    (_ => obj)(obj[propName] = propVal)

// -----------------------------------------------------------------------------
// Unload all the exports of a WASM instance and package them into the `libName`
// property of the `hostFns` object
//
// The `hostFns` object uses a two-level namespace where the top level
// identifies the library name and the second level identifies the function
// within that library.
const packageWasmExports =
  (wasmObj, libName, hostFns) =>
    Object
    .keys(wasmObj.instance.exports)
    .reduce(
      (acc, exp) => (_ => acc)(acc[libName][exp] = wasmObj.instance.exports[exp]),
      setProperty(hostFns, libName, {})
    )

// -----------------------------------------------------------------------------
// Instantiate a sequence of WASM modules
async function instantiateWasmModuleSequence(wasmSequence, hostFunctions) {
  return (await Promise.all(
    wasmSequence
      .map(async (wasmSeq) => {
        wasmSeq.wasmObj = await WebAssembly.instantiateStreaming(fetch(wasmSeq.wasmSrc), hostFunctions)
        hostFunctions = packageWasmExports(wasmSeq.wasmObj, wasmSeq.libName, hostFunctions)
        return wasmSeq
      })
  )).reduce((acc, wasmMod) => setProperty(acc, wasmMod.libName, wasmMod), {})
}

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------
export {
  instantiateWasmModuleSequence,
}
