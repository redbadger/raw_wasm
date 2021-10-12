/***********************************************************************************************************************
 * WASM interface data types
 *
 * @constructor
 * @param {string} label         - Datatype label
 * @param {number} [tolerance=0] - Optional comparison tolerance value
 */
function WasmDatatype(label, tolerance) {
  this.label = label
  this.tolerance = tolerance || 0
}

// Due to floating point inaccuracies, comparing test results against expected values requires the use of a tolerance
// values (these are somewhat arbitrary...)
const F64 = new WasmDatatype("f64", 0.0000000000000005)
const F32 = new WasmDatatype("f32", 0.0000000000000005)
const I32 = new WasmDatatype("i32")

/***********************************************************************************************************************
 * Arbitrarily assign property `propName` of object `obj` to have the value `propVal`
 * If `propName` already exists, its value is overwritten
 *
 * @param   {Object}  obj      - The object to be updated
 * @param   {string}  propName - The object property being set
 * @param   {*}       propVal  - The object property value
 *
 * @return  {object}  The updated object
 */
const setProperty = (obj, propName, propVal) => (_ => obj)(obj[propName] = propVal)

/***********************************************************************************************************************
 * WASM function interface type
 *
 * @constructor
 * @param {WasmDataType[]} inputTypes  - Array of WASM function input types
 * @param {WasmDataType[]} outputTypes - Array of WASM function output types
 */
function WasmInterfaceType(inputTypes, outputTypes) {
  this.input = inputTypes
  this.output = outputTypes
}

/***********************************************************************************************************************
 * Commonly used WASM function interface types
 */
const TWO_F64_IN_ONE_F64_OUT          = new WasmInterfaceType([F64, F64], [F64])
const TWO_F64_IN_ONE_I32_OUT          = new WasmInterfaceType([F64, F64], [I32])
const TWO_F64_ONE_I32_IN_ONE_I32_OUT  = new WasmInterfaceType([F64, F64, I32], [I32])
const TWO_F64_IN_TWO_F64_OUT          = new WasmInterfaceType([F64, F64], [F64, F64])
const FOUR_F64_IN_TWO_F64_OUT         = new WasmInterfaceType([F64, F64, F64, F64], [F64, F64])
const FOUR_F64_ONE_I32_IN_ONE_I32_OUT = new WasmInterfaceType([F64, F64, F64, F64, I32], [I32])

/***********************************************************************************************************************
 * Return an object containing the pathname to a compiled WASM module and the name of the library into which its
 * exported functions should be added
 *
 * @constructor
 * @param {string} pathToWasmBin - Pathname to compiled WASM module
 * @param {string} exportToLib   - The library name by which this WASM module's exported functions will be available
 */
function WasmModule(pathToWasmBin, exportToLib) {
  this.pathToWasmBin = pathToWasmBin
  this.exportToLib = exportToLib
}

/***********************************************************************************************************************
 * Add all the exports of a WASM instance to the possibly already existing `libName` property of object `hostFns`
 *
 * @param   {Object} wasmInstance - An instantiated WASM module that exports one or more functions
 * @param   {string} libName      - The library name by which the exported functions are grouped
 * @param   {string} hostFns      - The object acting as the repository for host functions
 *
 * @returns {Object} A new host functions object
 */
const packageWasmExports =
  (wasmInstance, libName, hostFns) =>
    Object
      .keys(wasmInstance.exports)
      .reduce(
        (acc, exp) => (_ => acc)(acc[libName][exp] = wasmInstance.exports[exp]),
        setProperty(hostFns, libName, !!hostFns[libName] ? hostFns[libName] : {})
      )

/***********************************************************************************************************************
 * Instantiate a list of WASM modules that potentially have import dependencies on some previously instantiated module
 *
 * @param {WasmModule[]} moduleSequence - A list of WASM modules in the order in which they need to be instantiated
 * @param {object}       initialHostFns - The object containing any host functions imported by the first WASM module
 *
 * @returns {object} An object containing a `hostFunctions` property.  This contains all the functions exported by the
 *                   instantiated WASM modules
 */
const instantiateWasmModuleSequence = async (moduleSequence, initialHostFns) => {
  let idx = 0
  let wasmModAccumulator = {}

  wasmModAccumulator.hostFunctions = initialHostFns

  for (idx=0; idx < moduleSequence.length; idx++) {
    const thisMod = moduleSequence[idx]

    console.log(`Instantiating ${thisMod.pathToWasmBin}`)

    let wasmObj = await WebAssembly.instantiateStreaming(fetch(thisMod.pathToWasmBin), wasmModAccumulator.hostFunctions)

    wasmModAccumulator.hostFunctions = packageWasmExports(
      wasmObj.instance,
      thisMod.exportToLib,
      wasmModAccumulator.hostFunctions
    )

    wasmModAccumulator[thisMod.exportToLib] = wasmObj
  }

  return wasmModAccumulator
}

/***********************************************************************************************************************
 * Public API
 */
export {
  WasmModule,
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
