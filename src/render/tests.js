import {
  FOUR_I32_IN_ONE_I32_OUT
} from "../js/wasmUtils.js"

import {
  WasmFunctionTest,
  WasmFunctionTestValues,
} from "../js/testUtils.js"

const ALPHA = 255
const RANGE_MIN = 0
const RANGE_MAX = 255

/*
 * Test RGBA value returned for a number in the range 0-255
 */
const test01 = new WasmFunctionTest("pixel_colour", FOUR_I32_IN_ONE_I32_OUT, "Value varies stepwise through range from 0 to 255")
test01.setTestList([
  new WasmFunctionTestValues([RANGE_MIN,   0, RANGE_MAX, ALPHA], [0xFFFF0000], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  16, RANGE_MAX, ALPHA], [0xFFDF2000], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  32, RANGE_MAX, ALPHA], [0xFFBF4000], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  64, RANGE_MAX, ALPHA], [0xFF7E8100], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  96, RANGE_MAX, ALPHA], [0xFF3EC100], "hex"),
  new WasmFunctionTestValues([RANGE_MIN, 128, RANGE_MAX, ALPHA], [0xFF010001], "hex"),
  new WasmFunctionTestValues([RANGE_MIN, 160, RANGE_MAX, ALPHA], [0xFF014041], "hex"),
  new WasmFunctionTestValues([RANGE_MIN, 192, RANGE_MAX, ALPHA], [0xFF018081], "hex"),
  new WasmFunctionTestValues([RANGE_MIN, 224, RANGE_MAX, ALPHA], [0xFF01C0C1], "hex"),
  new WasmFunctionTestValues([RANGE_MIN, 255, RANGE_MAX, ALPHA], [0xFF01FEFF], "hex"),
])

const colourTestMap = [test01].reduce(
  (map, test) => {
    map.set(test.function.name, test)
    return map
  }, new Map())

export {
  colourTestMap
}
