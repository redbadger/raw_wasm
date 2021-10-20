import {
  FOUR_I32_IN_ONE_I32_OUT
} from "../js/wasmUtils.js"

import {
  WasmFunctionTest,
  WasmFunctionTestValues,
} from "../js/testUtils.js"

/*
 * Test RGBA value returned for a number in the range 0-255
 */
const test01 = new WasmFunctionTest("pixel_colour", FOUR_I32_IN_ONE_I32_OUT, "Value varies stepwise through range from 0 to 255")
test01.setTestList([
  new WasmFunctionTestValues([255,0,  0,255], [0xFFFF0000], "hex"),
  new WasmFunctionTestValues([255,0, 16,255], [0xFFDF2000], "hex"),
  new WasmFunctionTestValues([255,0, 32,255], [0xFFBF4000], "hex"),
  new WasmFunctionTestValues([255,0, 64,255], [0xFF7E8100], "hex"),
  new WasmFunctionTestValues([255,0, 96,255], [0xFF3EC100], "hex"),
  new WasmFunctionTestValues([255,0,128,255], [0xFF010001], "hex"),
  new WasmFunctionTestValues([255,0,160,255], [0xFF014041], "hex"),
  new WasmFunctionTestValues([255,0,192,255], [0xFF018081], "hex"),
  new WasmFunctionTestValues([255,0,224,255], [0xFF01C0C1], "hex"),
  new WasmFunctionTestValues([255,0,255,255], [0xFF01FEFF], "hex"),
])

const colourTestMap = [test01].reduce(
  (map, test) => {
    map.set(test.function.name, test)
    return map
  }, new Map())

export {
  colourTestMap
}
