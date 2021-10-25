import { WasmInterfaceType, I32, F32 } from '../js/wasmUtils.js'

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

/*
 * Test translation of a canvas X or Y position to the corresponding X or Y coordinate on the complex plane
 */
const CANVAS_WIDTH = 800
const CANVAS_HEIGHT = 450
const DEFAULT_ORIGIN_X = -0.5
const DEFAULT_ORIGIN_Y = 0.0
const PIXELS_PER_UNIT = 200

const test02 = new WasmFunctionTest(
  "pos_to_coord",
  new WasmInterfaceType([I32, I32, F32, I32], [F32]),
  "Translate canvas position to coordinate on the complex plane"
)
test02.setTestList([
  // Test points along the X axis
  new WasmFunctionTestValues(
    [0, CANVAS_WIDTH, DEFAULT_ORIGIN_X, PIXELS_PER_UNIT],
    [-2.5]
  ),
  new WasmFunctionTestValues(
    [CANVAS_WIDTH / 4, CANVAS_WIDTH, DEFAULT_ORIGIN_X, PIXELS_PER_UNIT],
    [-1.5]
  ),
  new WasmFunctionTestValues(
    [CANVAS_WIDTH / 2, CANVAS_WIDTH, DEFAULT_ORIGIN_X, PIXELS_PER_UNIT],
    [DEFAULT_ORIGIN_X]
  ),
  new WasmFunctionTestValues(
    [CANVAS_WIDTH * 0.75, CANVAS_WIDTH, DEFAULT_ORIGIN_X, PIXELS_PER_UNIT],
    [0.5]
  ),
  new WasmFunctionTestValues(
    [CANVAS_WIDTH, CANVAS_WIDTH, DEFAULT_ORIGIN_X, PIXELS_PER_UNIT],
    [1.5]
  ),

  // Test points along the Y axis
  new WasmFunctionTestValues(
    [0, CANVAS_HEIGHT, DEFAULT_ORIGIN_Y, PIXELS_PER_UNIT],
    [-1.125]
  ),
  new WasmFunctionTestValues(
    [CANVAS_HEIGHT / 4, CANVAS_HEIGHT, DEFAULT_ORIGIN_Y, PIXELS_PER_UNIT],
    [-0.565]
  ),
  new WasmFunctionTestValues(
    [CANVAS_HEIGHT / 2, CANVAS_HEIGHT, DEFAULT_ORIGIN_Y, PIXELS_PER_UNIT],
    [DEFAULT_ORIGIN_Y]
  ),
  new WasmFunctionTestValues(
    [CANVAS_HEIGHT * 0.75, CANVAS_HEIGHT, DEFAULT_ORIGIN_Y, PIXELS_PER_UNIT],
    [0.56]
  ),
  new WasmFunctionTestValues(
    [CANVAS_HEIGHT, CANVAS_HEIGHT, DEFAULT_ORIGIN_Y, PIXELS_PER_UNIT],
    [ 1.125]
  ),
])

const colourTestMap = [test01, test02].reduce(
  (map, test) => {
    map.set(test.function.name, test)
    return map
  }, new Map())

export {
  colourTestMap
}
