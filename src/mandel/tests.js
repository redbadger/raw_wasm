import {
  TWO_F64_IN_ONE_I32_OUT,
  TWO_F64_ONE_I32_IN_ONE_I32_OUT,
  FOUR_F64_ONE_I32_IN_ONE_I32_OUT
} from "../js/wasmUtils.js"

const mandelTestMap = new Map()

mandelTestMap.set("is_in_period_2_bulb", {
  "description": "Point lies within the Mandelbrot set's period 2 bulb",
  "function": { "name": "is_in_period_2_bulb", "arity": TWO_F64_IN_ONE_I32_OUT },
  "testList" : [
    { "whenPassed": [-1.25,0], "shouldGet": [1] },
    { "whenPassed": [-0.7499999,0], "shouldGet": [0] },
    { "whenPassed": [-0.75,0], "shouldGet": [1] },
    { "whenPassed": [-1.2500001,0], "shouldGet": [0] },
    { "whenPassed": [-1.0025,0.24998], "shouldGet": [1] },
    { "whenPassed": [-1.0025,0.25], "shouldGet": [0] },
  ]
})

mandelTestMap.set("is_in_main_cardioid", {
  "description": "Point lies within the Mandelbrot set's main cardioid",
  "function": { "name": "is_in_main_cardioid", "arity": TWO_F64_IN_ONE_I32_OUT },
  "testList" : [
    { "whenPassed": [0,0], "shouldGet": [1] },
    { "whenPassed": [0.25,0], "shouldGet": [1] },
    { "whenPassed": [0.2500001,0], "shouldGet": [0] },
    { "whenPassed": [1,0], "shouldGet": [0] },
    { "whenPassed": [-1,0], "shouldGet": [0] },
    { "whenPassed": [-0.135,0.75], "shouldGet": [0] },
    { "whenPassed": [-0.75,0], "shouldGet": [1] },
    { "whenPassed": [0,1], "shouldGet": [0] },
    { "whenPassed": [0,-1], "shouldGet": [0] },
  ]
})

mandelTestMap.set("mandel_early_bailout", {
  "description": "Can we bail out of the Mandelbrot escape time algorithm early?",
  "function": { "name": "mandel_early_bailout", "arity": TWO_F64_IN_ONE_I32_OUT },
  "testList" : [
    { "whenPassed": [-1.25,0], "shouldGet": [1] },
    { "whenPassed": [-0.7499999,0], "shouldGet": [1] },
    { "whenPassed": [-0.75,0], "shouldGet": [1] },
    { "whenPassed": [-1.2500001,0], "shouldGet": [0] },
    { "whenPassed": [-1.0025,0.24998], "shouldGet": [1] },
    { "whenPassed": [-1.0025,0.25], "shouldGet": [0] },
    { "whenPassed": [0,0], "shouldGet": [1] },
    { "whenPassed": [0.25,0], "shouldGet": [1] },
    { "whenPassed": [0.2500001,0], "shouldGet": [0] },
    { "whenPassed": [1,0], "shouldGet": [0] },
    { "whenPassed": [-1,0], "shouldGet": [1] },
    { "whenPassed": [-0.135,0.75], "shouldGet": [0] },
    { "whenPassed": [-0.75,0], "shouldGet": [1] },
    { "whenPassed": [0,1], "shouldGet": [0] },
    { "whenPassed": [0,-1], "shouldGet": [0] },
  ]
})

mandelTestMap.set("escape_time_mj", {
  "description": "Escape time algorithm for calculating both the Mandelbrot set and Julia sets",
  "function": { "name": "escape_time_mj", "arity": FOUR_F64_ONE_I32_IN_ONE_I32_OUT },
  "testList" : [
    { "whenPassed": [0,0,0,0,100], "shouldGet": [100] },
    { "whenPassed": [-2,0,0,0,100], "shouldGet": [100] },
    { "whenPassed": [0.675,0,0,0,100], "shouldGet": [4] },
    { "whenPassed": [1,0,0,0,100], "shouldGet": [3] },
    { "whenPassed": [2,0,0,0,100], "shouldGet": [2] },
    { "whenPassed": [2.00001,0,0,0,100], "shouldGet": [1] },
  ]
})

mandelTestMap.set("mandel_iter", {
  "description": "Return the iteration count of one pixel on the Mandelbrot set",
  "function": { "name": "mandel_iter", "arity": TWO_F64_ONE_I32_IN_ONE_I32_OUT },
  "testList" : [
    { "whenPassed": [0,0,100], "shouldGet": [100] },
    { "whenPassed": [-2,0,100], "shouldGet": [100] },
    { "whenPassed": [0.675,0,100], "shouldGet": [4] },
    { "whenPassed": [1,0,100], "shouldGet": [3] },
    { "whenPassed": [2,0,100], "shouldGet": [2] },
    { "whenPassed": [2.00001,0,100], "shouldGet": [1] },
  ]
})

export {
  mandelTestMap
}
