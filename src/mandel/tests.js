import {
  TWO_F64_IN_ONE_I32_OUT,
  TWO_F64_ONE_I32_IN_ONE_I32_OUT,
  FOUR_F64_ONE_I32_IN_ONE_I32_OUT
} from "../js/wasmUtils.js"

import {
  WasmFunctionTest,
  WasmFunctionTestValues,
} from "../js/testUtils.js"

/*
 * Bailout early if the point lies within the Mandelbrot set's main cardioid
 */
const test01 = new WasmFunctionTest("is_in_main_cardioid", TWO_F64_IN_ONE_I32_OUT, "Point lies within the Mandelbrot set's main cardioid")
test01.setTestList([
    new WasmFunctionTestValues([0,0], [1], "boolean"),
    new WasmFunctionTestValues([0.25,0], [1], "boolean"),
    new WasmFunctionTestValues([0.2500001,0], [0], "boolean"),
    new WasmFunctionTestValues([1,0], [0], "boolean"),
    new WasmFunctionTestValues([-1,0], [0], "boolean"),
    new WasmFunctionTestValues([-0.135,0.75], [0], "boolean"),
    new WasmFunctionTestValues([-0.75,0], [1], "boolean"),
    new WasmFunctionTestValues([0,1], [0], "boolean"),
    new WasmFunctionTestValues([0,-1], [0], "boolean"),
  ]
)

/*
 * Bailout early if the point lies within the Mandelbrot set's period 2 bulb
 */
const test02 = new WasmFunctionTest("is_in_period_2_bulb", TWO_F64_IN_ONE_I32_OUT, "Point lies within the Mandelbrot set's period 2 bulb")
test02.setTestList([
  new WasmFunctionTestValues([-1.25,0], [1], "boolean"),
  new WasmFunctionTestValues([-0.7499999,0], [0], "boolean"),
  new WasmFunctionTestValues([-0.75,0], [1], "boolean"),
  new WasmFunctionTestValues([-1.2500001,0], [0], "boolean"),
  new WasmFunctionTestValues([-1.0025,0.24998], [1], "boolean"),
  new WasmFunctionTestValues([-1.0025,0.25], [0], "boolean"),
])

/*
 * Bailout early if the point lies within either of the above bailout areas
 */
const test03 = new WasmFunctionTest("mandel_early_bailout", TWO_F64_IN_ONE_I32_OUT, "Can we bail out of the Mandelbrot escape time algorithm early?")
test03.setTestList([
  new WasmFunctionTestValues([-1.25,0], [1], "boolean"),
  new WasmFunctionTestValues([-0.7499999,0], [1], "boolean"),
  new WasmFunctionTestValues([-0.75,0], [1], "boolean"),
  new WasmFunctionTestValues([-1.2500001,0], [0], "boolean"),
  new WasmFunctionTestValues([-1.0025,0.24998], [1], "boolean"),
  new WasmFunctionTestValues([-1.0025,0.25], [0], "boolean"),
  new WasmFunctionTestValues([0,0], [1], "boolean"),
  new WasmFunctionTestValues([0.25,0], [1], "boolean"),
  new WasmFunctionTestValues([0.2500001,0], [0], "boolean"),
  new WasmFunctionTestValues([1,0], [0], "boolean"),
  new WasmFunctionTestValues([-1,0], [1], "boolean"),
  new WasmFunctionTestValues([-0.135,0.75], [0], "boolean"),
  new WasmFunctionTestValues([-0.75,0], [1], "boolean"),
  new WasmFunctionTestValues([0,1], [0], "boolean"),
  new WasmFunctionTestValues([0,-1], [0], "boolean"),
])

/*
 * Run one invocation of the Mandelbrot escape time algorithm
 */
const test04 = new WasmFunctionTest("escape_time_mj", FOUR_F64_ONE_I32_IN_ONE_I32_OUT, "Escape time algorithm for calculating both the Mandelbrot set and Julia sets")
test04.setTestList([
  new WasmFunctionTestValues([0,0,0,0,100], [100]),
  new WasmFunctionTestValues([-2,0,0,0,100], [100]),
  new WasmFunctionTestValues([0.675,0,0,0,100], [4]),
  new WasmFunctionTestValues([1,0,0,0,100], [3]),
  new WasmFunctionTestValues([2,0,0,0,100], [2]),
  new WasmFunctionTestValues([2.00001,0,0,0,100], [1]),
])

/*
 * Iterate one point on the Mandelbrot set that may or may not be within one of the early bailout areas
 */
const test05 = new WasmFunctionTest("mandel_iter", TWO_F64_ONE_I32_IN_ONE_I32_OUT, "Return the iteration count of one pixel on the Mandelbrot set")
test05.setTestList([
  new WasmFunctionTestValues([0,0,100], [100]),
  new WasmFunctionTestValues([-2,0,100], [100]),
  new WasmFunctionTestValues([0.675,0,100], [4]),
  new WasmFunctionTestValues([1,0,100], [3]),
  new WasmFunctionTestValues([2,0,100], [2]),
  new WasmFunctionTestValues([2.00001,0,100], [1]),
])

const mandelTestMap = [test01, test02, test03, test04, test05].reduce(
  (map, test) => {
    map.set(test.function.name, test)
    return map
  }, new Map())

export {
  mandelTestMap
}
