// These comparison tolerance values are somewhat arbitrary...
const F64 = { "label": "f64", "tolerance" : 0.0000000000000005 }
const F32 = { "label": "f32", "tolerance" : 0.0000000000000005 }
const I64 = { "label": "i64", "tolerance" : 0 }
const I32 = { "label": "i32", "tolerance" : 0 }

// ---------------------------------------------------------------------------------------------------------------------
const setProperty = (obj, propName, propVal) => (_ => obj)(obj[propName] = propVal)
const mergeObjects = (sourceObj, targetObj) => ({ ...targetObj, ...sourceObj })

// ---------------------------------------------------------------------------------------------------------------------
const TWO_F64_IN_ONE_F64_OUT  = {
  "input"  : [F64, F64],
  "output" : [F64]
}

const TWO_F64_IN_ONE_I32_OUT  = {
  "input"  : [F64, F64],
  "output" : [I32]
}

const TWO_F64_ONE_I32_IN_ONE_I32_OUT  = {
  "input"  : [F64, F64, I32],
  "output" : [I32]
}

const TWO_F64_IN_TWO_F64_OUT  = {
  "input"  : [F64, F64],
  "output" : [F64, F64]
}

const FOUR_F64_IN_TWO_F64_OUT = {
  "input"  : [F64, F64, F64, F64],
  "output" : [F64, F64]
}

const FOUR_F64_ONE_I32_IN_ONE_I32_OUT = {
  "input"  : [F64, F64, F64, F64, I32],
  "output" : [I32]
}

// ---------------------------------------------------------------------------------------------------------------------
// Unload all the exports of a WASM instance and add them to the possibly already existing `libName` property in the
// `hostFns` object
const packageWasmExports =
  (wasmInstance, libName, hostFns) =>
    Object
      .keys(wasmInstance.exports)
      .reduce(
        (acc, exp) => (_ => acc)(acc[libName][exp] = wasmInstance.exports[exp]),
        setProperty(hostFns, libName, !!hostFns[libName] ? hostFns[libName] : {})
      )

// ---------------------------------------------------------------------------------------------------------------------
// Instantiate a sequence of WASM modules that potentially have import dependencies on some predecessor in the list
const instantiateWasmModuleSequence = async moduleSequence => {
  let idx = 0
  let wasmModAccumulator = {}

  wasmModAccumulator.hostFunctions = moduleSequence[0].hostFunctions

  for (idx=0; idx < moduleSequence.length; idx++) {
    const thisMod = moduleSequence[idx]

    console.log(`Instantiating ${thisMod.wasmBin}`)

    let wasmObj = await WebAssembly.instantiateStreaming(fetch(thisMod.wasmBin), wasmModAccumulator.hostFunctions)

    wasmModAccumulator.hostFunctions = packageWasmExports(
      wasmObj.instance,
      thisMod.addWasmExportsToLibName,
      wasmModAccumulator.hostFunctions
    )

    wasmModAccumulator[thisMod.addWasmExportsToLibName] = wasmObj
  }

  return wasmModAccumulator
}

// ---------------------------------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------------------------------
export {
  instantiateWasmModuleSequence,

  F64,
  F32,
  TWO_F64_IN_ONE_F64_OUT,
  TWO_F64_IN_ONE_I32_OUT,
  TWO_F64_ONE_I32_IN_ONE_I32_OUT,
  TWO_F64_IN_TWO_F64_OUT,
  FOUR_F64_IN_TWO_F64_OUT,
  FOUR_F64_ONE_I32_IN_ONE_I32_OUT,
}
