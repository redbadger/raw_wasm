const setProperty = (obj, propName, propVal) => (_ => obj)(obj[propName] = propVal)

const typeOf     = x => Object.prototype.toString.apply(x).slice(8).slice(0, -1)
const isOfType   = t => x => typeOf(x) === t
const isArray    = isOfType("Array")
const isFunction = isOfType("Function")

// These tolerance values are somewhat arbitrary...
const F64 = { "label": "f64", "tolerance" : 0.0000000000000005 }
const F32 = { "label": "f32", "tolerance" : 0.0000000000000005 }

// -----------------------------------------------------------------------------
const TWO_F64_IN_ONE_F64_OUT  = { "input" : [F64, F64],           "output" : [F64] }
const TWO_F64_IN_TWO_F64_OUT  = { "input" : [F64, F64],           "output" : [F64, F64] }
const FOUR_F64_IN_TWO_F64_OUT = { "input" : [F64, F64, F64, F64], "output" : [F64, F64] }

// Yeah, whatever...
const closeEnough = (tol, val, req) => req + tol >= val && req - tol <= val

// -----------------------------------------------------------------------------
const isWithinTolerance =
  (datatype, actual, expected) =>
    datatype.label === F64.label
    ? closeEnough(F64.tolerance, actual, expected)
    : datatype.label === F32.label
      ? closeEnough(F32.tolerance, actual, expected)
      : actual === expected

// -----------------------------------------------------------------------------
const checkArrayEquality =
  (outTypes, a1, a2) => {
    let comparison = {
      "comparable" : true,
      "elementEquality" : []
    }

    // Are the arrays comparable?
    if (isArray(a1) && isArray(a2) && a1.length === a2.length) {
      // Yup, so determine equality of each array element
      comparison.elementEquality = a1.reduce(
        (acc, val, idx) => {
          acc.push(
            val === a2[idx]
            ? { "equal" : true, "withinTolerance" : false }
            : isWithinTolerance(outTypes[idx], val, a2[idx])
              ? { "equal" : false, "withinTolerance" : true }
              : { "equal" : false, "withinTolerance" : false }
          )

          return acc
        },
        [])
    } else
      comparison.comparable = false

    return comparison
  }

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
    setProperty(hostFns, libName, {}))

// -----------------------------------------------------------------------------
// Create a new instance of a WASM module passing in the `hostFns` object to
// satisfy any imports that module might have
// Once instantiated, the `hostsFns` object is then extended to include anything
// exported by the new WASM instance
const createWasmLib = (src, libName, hostFns) =>
  WebAssembly
  .instantiateStreaming(fetch(src), hostFns)
  .then(wasmObj => ({
      wasmObj : wasmObj,
      hostFns : packageWasmExports(wasmObj, libName, hostFns)
    }))

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------
export {
  isArray,
  isFunction,

  F64,
  F32,
  TWO_F64_IN_ONE_F64_OUT,
  TWO_F64_IN_TWO_F64_OUT,
  FOUR_F64_IN_TWO_F64_OUT,

  checkArrayEquality,

  packageWasmExports,
  createWasmLib
}
