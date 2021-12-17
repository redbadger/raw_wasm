let my_worker_id
let wasmObj

// Record initialisation execution times
let times = {
  init : { start : 0, end : 0 },
  exec : { start : 0, end : 0 },
}

const gen_msg_exec_complete = (worker_id, name, times) => ({
  action  : 'exec_complete',
  payload : {
    worker_id : worker_id,
    fractal   : name,
    times     : times,
  }
})

const draw_fractal = (fractal, max_iters) => {
  let start = performance.now()
  wasmObj.instance.exports.mj_plot(
    fractal.width,         fractal.height,
    fractal.origin_x,      fractal.origin_y,
    fractal.zx,            fractal.zy,
    fractal.ppu,           max_iters,
    fractal.is_mandelbrot, fractal.img_offset
  )

  return { "start" : start, "end": performance.now() }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Inbound message handler
onmessage = async ({ data }) => {
  const { action, payload } = data
  let { host_fns, worker_id, fractal, max_iters } = payload

  switch(action) {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Create WebAssembly module instance and draw initial Mandelbrot Set
    case 'init':
      my_worker_id = worker_id

      times.init.start = performance.now()
      wasmObj = await WebAssembly.instantiateStreaming(fetch('../wat/mj_plot.wasm'), host_fns)
      times.init.end = performance.now()

      // Draw initial Mandelbrot Set
      times.init = draw_fractal(fractal, max_iters)
      postMessage(gen_msg_exec_complete(worker_id, "mb", times))

      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Draw a fractal image
    case 'exec':
      times.exec = draw_fractal(fractal, max_iters)
      postMessage(gen_msg_exec_complete(my_worker_id, fractal.name, times))

    default:
  }
}
