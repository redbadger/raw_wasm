const microPrecision = val => Math.round(val * 10000) / 10000
const interval       = time => microPrecision(time.end - time.start)
const i32AsString    = n => ((n1, sign) => `${sign}0x${n1.toString(16).padStart(8,'0')}`)(Math.abs(n), n < 0 ? '-' : '')
const setProperty    = (obj, propName, propVal) => (_ => obj)(obj[propName] = propVal)

/* ---------------------------------------------------------------------------------------------------------------------
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

/* ---------------------------------------------------------------------------------------------------------------------
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

/* ---------------------------------------------------------------------------------------------------------------------
 * Instantiate a list of WASM modules that potentially have import dependencies on some previously instantiated module
 *
 * @param {WasmModule[]} moduleSequence - A list of WASM modules listed in instantiation order
 * @param {object}       initialHostFns - The object containing any host functions imported by the first WASM module
 *
 * @returns {object} An object containing a `hostFunctions` property.  This contains all the functions exported by the
 *                   instantiated WASM modules
 */
const instantiateWasmModuleSequence = async (moduleSequence, initialHostFns, worker_id) => {
  let wasmModAccumulator = {}

  wasmModAccumulator.hostFunctions = initialHostFns

  for (let idx=0; idx < moduleSequence.length; idx++) {
    const thisMod = moduleSequence[idx]
    const wasmObj = await WebAssembly.instantiateStreaming(fetch(thisMod.pathToWasmBin), wasmModAccumulator.hostFunctions)

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
 * These WASM modules must be instantiated in the order listed below due to the fact that later modules might have
 * import dependencies on earlier modules
 */
const instantiationSequence = [
  new WasmModule('../../build/colour_palette-3.wasm', 'colours'),
  new WasmModule('../../build/mj_plot-3.wasm',        'mj_plot'),
]

const WASM_LOG_MSGS = [
  { msg : "Mandelbrot: Pixel X,Y, value", asHex : [false, false, false] },
  { msg : "Julia: Pixel X, Y, value",     asHex : [false, false, false] },
]

let mandel_plot
let julia_plot
let paletteFn
let my_worker_id
let times = {
  init : { start : 0, end : 0 },
  exec : { start : 0, end : 0 },
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Worker inbound message handler
 */
onmessage = ({ data }) => {
  // data = {
  //   action,                 // Task to be performed
  //   payload                 // Payload specific for current task
  // }
  // payload = {
  //    host_fns,              // Needed during initialisation
  //    worker_id,             // Needed during initialisation
  //    fractal,               // Details of the current fractal being plotted
  //    max_iters
  // }
  const { action, payload } = data
  let { host_fns, worker_id, fractal, max_iters } = payload

  const logger = (idx, ...vals) => {
    let values = WASM_LOG_MSGS[idx].asHex.map((flag, idx2) => flag ? i32AsString(vals[idx2]) : vals[idx2])
    console.log(`${WASM_LOG_MSGS[idx].msg} = ${values}`)
  }

  switch(action) {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    case 'init':
      my_worker_id = worker_id
      times.init.start = performance.now()

      // Supplement the host_fns object with objects that cannot be cloned (like functions)
      host_fns.js.log3 = logger

      instantiateWasmModuleSequence(instantiationSequence, host_fns, worker_id)
        .then(wasmModules => {
          times.init.end = performance.now()
          console.log(`Worker ${worker_id}: Initialised in ${interval(times.init)} ms`)

          mandel_plot = wasmModules.mj_plot.instance.exports.mandel_plot
          julia_plot  = wasmModules.mj_plot.instance.exports.julia_plot
          // paletteFn   = wasmModules.colours.instance.exports.hsl_to_rgb
          paletteFn   = wasmModules.colours.instance.exports.gen_palette
        })
        .then(() => {
          // The colour palette calculation does not need to be distributed across mulitple workers
          // This task is performed only by worker 0
          if (worker_id === 0) {
            console.log("Worker 0: Calculating colour palette")
            paletteFn(max_iters)
          }

          // Create initial Mandelbrot Set
          times.exec.start = performance.now()
          mandel_plot(
            fractal.width,    fractal.height,
            fractal.origin_x, fractal.origin_y,
            fractal.zoom,     max_iters
          )
          times.exec.end = performance.now()

          // Report execution complete
          postMessage({
            status  : 'exec_complete',
            payload : {
              worker_id : worker_id,
              fractal   : "mandel",
              times     : times
            }
          })
        })

      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // max_iters has changed
    case 'refresh_colour_palette':
      console.log(`Worker ${my_worker_id}: Refreshing colour palette for new max_iters = ${max_iters}`)
      paletteFn(max_iters)
      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    case 'exec':
      times.exec.start = performance.now()

      switch(payload.fractal.name) {
        case "mandel":
          mandel_plot(
            fractal.width,    fractal.height,
            fractal.origin_x, fractal.origin_y,
            fractal.zoom,     max_iters
          )
          break

        case "julia":
          julia_plot(
            fractal.width,    fractal.height,
            fractal.origin_x, fractal.origin_y,
            fractal.mandel_x, fractal.mandel_y,
            fractal.zoom,     max_iters
          )
          break

        default:
      }

      times.exec.end = performance.now()

      postMessage({
        status  : 'exec_complete',
        payload : {
          worker_id : my_worker_id,
          fractal   : fractal.name,
          times     : times,
        }
      })

    default:
  }

}
