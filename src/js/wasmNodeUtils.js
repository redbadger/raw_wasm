import { readFileSync } from 'fs'
import { packageWasmExports } from './wasmUtils.js'

/* ---------------------------------------------------------------------------------------------------------------------
 * Instantiate a list of WASM modules that potentially have import dependencies on some previously instantiated module
 *
 * @param {WasmModule[]} moduleSequence - A list of WASM modules listed in instantiation order
 * @param {object}       initialHostFns - The object containing any host functions imported by the first WASM module
 *
 * @returns {object} An object containing a `hostFunctions` property.  This contains all the functions exported by the
 *                   instantiated WASM modules
 */
const instantiateWasmModuleSequence = async (moduleSequence, initialHostFns) => {
  let wasmModAccumulator = {}

  wasmModAccumulator.hostFunctions = initialHostFns

  for (let idx=0; idx < moduleSequence.length; idx++) {
    const thisMod = moduleSequence[idx]
    const wasmObj = await WebAssembly.instantiate(new Uint8Array(readFileSync(thisMod.pathToWasmBin)), wasmModAccumulator.hostFunctions)

    console.log(`${thisMod.pathToWasmBin} instantiated`)

    wasmModAccumulator.hostFunctions = packageWasmExports(
      wasmObj.instance,
      thisMod.exportToLib,
      wasmModAccumulator.hostFunctions
    )

    wasmModAccumulator[thisMod.exportToLib] = wasmObj
  }

  return wasmModAccumulator
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Public API
 */
export {
  instantiateWasmModuleSequence,
}
