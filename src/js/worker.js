const i32AsString = n => ((n1, sign) => `${sign}0x${n1.toString(16).padStart(8,'0')}`)(Math.abs(n), n < 0 ? '-' : '')

const WASM_LOG_MSGS = [
  { msg : "Mandelbrot: Pixel X, Y, value", asHex : [false, false, false] },
  { msg : "Julia: Pixel X, Y, value",     asHex : [false, false, false] },
]

const gen_worker_msg_exec_complete = (worker_id, name, times) => ({
  status  : 'exec_complete',
  payload : {
    worker_id : worker_id,
    fractal   : name,
    times     : times,
  }
})

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
onmessage = async ({ data }) => {
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

      // Supplement the host_fns object with objects that cannot be cloned (such as functions)
      host_fns.js.log3 = logger

      times.init.start = performance.now()
      const wasmObj = await WebAssembly.instantiateStreaming(fetch('../../build/mj_plot-3.wasm'), host_fns)
      times.init.end = performance.now()

      mandel_plot = wasmObj.instance.exports.mandel_plot
      julia_plot  = wasmObj.instance.exports.julia_plot
      paletteFn   = wasmObj.instance.exports.gen_palette

      // The colour palette calculation does not need to be distributed across mulitple workers
      // This task is performed only by worker 0
      if (worker_id === 0) {
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
      postMessage(gen_worker_msg_exec_complete(worker_id, "mandel", times))

      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // max_iters has changed
    case 'refresh_colour_palette':
      paletteFn(max_iters)
      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    case 'exec':
      times.exec.start = performance.now()

      switch(fractal.name) {
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

      postMessage(gen_worker_msg_exec_complete(my_worker_id, fractal.name, times))

    default:
  }
}
