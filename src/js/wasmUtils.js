import { setProperty } from './genericUtils.js'

// These tolerance values are somewhat arbitrary...
const F64 = { "label": "f64", "tolerance" : 0.0000000000000005 }
const F32 = { "label": "f32", "tolerance" : 0.0000000000000005 }

// ---------------------------------------------------------------------------------------------------------------------
const TWO_F64_IN_ONE_F64_OUT  = { "input" : [F64, F64],           "output" : [F64] }
const TWO_F64_IN_TWO_F64_OUT  = { "input" : [F64, F64],           "output" : [F64, F64] }
const FOUR_F64_IN_TWO_F64_OUT = { "input" : [F64, F64, F64, F64], "output" : [F64, F64] }

// ---------------------------------------------------------------------------------------------------------------------
// Unload all the exports of a WASM instance and package them into the `libName` property of the `hostFns` object
//
// The `hostFns` object uses a two-level namespace where the top level identifies the library name and the second level
// identifies the function within that library.
const packageWasmExports =
  (wasmObj, libName, hostFns) =>
    Object
    .keys(wasmObj.instance.exports)
    .reduce(
      (acc, exp) => (_ => acc)(acc[libName][exp] = wasmObj.instance.exports[exp]),
      setProperty(hostFns, libName, {})
    )

// ---------------------------------------------------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------------------------------
export {
  instantiateWasmModuleSequence,

  F64,
  F32,
  TWO_F64_IN_ONE_F64_OUT,
  TWO_F64_IN_TWO_F64_OUT,
  FOUR_F64_IN_TWO_F64_OUT,
}
