import { WasmInterfaceType, I32, F32 } from '../js/wasmUtils.js'

import {
  FOUR_I32_IN_ONE_I32_OUT
} from "../js/wasmUtils.js"

import {
  WasmFunctionTest,
  WasmFunctionTestValues,
} from "../js/testUtils.js"

const RANGE_MIN = 0
const RANGE_MAX = 1000

/*
 * Map iteration value over linear RGB colourspace
 */
const test01 = new WasmFunctionTest(
  "pixel_colour",
  FOUR_I32_IN_ONE_I32_OUT,
  "Map iteration value over linear RGB colourspace"
)
test01.setTestList([
  new WasmFunctionTestValues([RANGE_MIN,    0, RANGE_MAX], [0xFFFF0000], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,   32, RANGE_MAX], [0xFFEE1100], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,   64, RANGE_MAX], [0xFFDE2100], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,   96, RANGE_MAX], [0xFFCE3100], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  128, RANGE_MAX], [0xFFBD4200], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  160, RANGE_MAX], [0xFFAD5200], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  192, RANGE_MAX], [0xFF9D6200], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  224, RANGE_MAX], [0xFF8C7300], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  256, RANGE_MAX], [0xFF7C8300], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  288, RANGE_MAX], [0xFF6C9300], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  320, RANGE_MAX], [0xFF5BA400], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  352, RANGE_MAX], [0xFF4BB400], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  384, RANGE_MAX], [0xFF3BC400], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  416, RANGE_MAX], [0xFF2AD500], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  448, RANGE_MAX], [0xFF1AE500], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  480, RANGE_MAX], [0xFF0AF500], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  512, RANGE_MAX], [0xFF010506], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  544, RANGE_MAX], [0xFF011516], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  576, RANGE_MAX], [0xFF012526], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  608, RANGE_MAX], [0xFF013637], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  640, RANGE_MAX], [0xFF014647], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  672, RANGE_MAX], [0xFF015657], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  704, RANGE_MAX], [0xFF016768], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  736, RANGE_MAX], [0xFF017778], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  768, RANGE_MAX], [0xFF018788], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  800, RANGE_MAX], [0xFF019899], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  832, RANGE_MAX], [0xFF01A8A9], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  864, RANGE_MAX], [0xFF01B8B9], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  896, RANGE_MAX], [0xFF01C8C9], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  928, RANGE_MAX], [0xFF01D9DA], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  960, RANGE_MAX], [0xFF01E9EA], "hex"),
  new WasmFunctionTestValues([RANGE_MIN,  992, RANGE_MAX], [0xFF01F9FA], "hex"),
  new WasmFunctionTestValues([RANGE_MIN, 1000, RANGE_MAX], [0xFF01FEFF], "hex"),
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

/*
 * Map iteration value over HSL colourspace
 */
const HSL_MAX = 600

const test03 = new WasmFunctionTest(
  "value_to_rgb",
  FOUR_I32_IN_ONE_I32_OUT,
  "Map iteration value to HSL colourspace"
)
test03.setTestList([
  new WasmFunctionTestValues([   0, HSL_MAX], [0xFF0000FF], "hex"),
  new WasmFunctionTestValues([ 100, HSL_MAX], [0xFF00FFFF], "hex"),
  new WasmFunctionTestValues([ 200, HSL_MAX], [0xFF00FF00], "hex"),
  new WasmFunctionTestValues([ 300, HSL_MAX], [0xFFFFFF00], "hex"),
  new WasmFunctionTestValues([ 400, HSL_MAX], [0xFFFF0000], "hex"),
  new WasmFunctionTestValues([ 500, HSL_MAX], [0xFFFF00FF], "hex"),
  new WasmFunctionTestValues([ 600, HSL_MAX], [0xFF0000FF], "hex"),
])

const colourTestMap = [test01, test02, test03].reduce(
  (map, test) => {
    map.set(test.function.name, test)
    return map
  }, new Map())

export {
  colourTestMap
}
