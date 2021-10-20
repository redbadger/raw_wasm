import {
  TWO_F64_IN_ONE_F64_OUT,
  TWO_F64_IN_TWO_F64_OUT,
  FOUR_F64_IN_TWO_F64_OUT
} from "../js/wasmUtils.js"

import {
  WasmFunctionTest,
  WasmFunctionTestValues,
} from "../js/testUtils.js"

const test01 = new WasmFunctionTest("real", TWO_F64_IN_ONE_F64_OUT, "Real part")
test01.setTestList([new WasmFunctionTestValues([5,2], [5])])

const test02 = new WasmFunctionTest("imag", TWO_F64_IN_ONE_F64_OUT, "Imaginary part")
test02.setTestList([new WasmFunctionTestValues([5,2], [2])])

const test03 = new WasmFunctionTest("hypot", TWO_F64_IN_ONE_F64_OUT, "Hypotenuse length")
test03.setTestList([new WasmFunctionTestValues([3,4], [5])])

const test04 = new WasmFunctionTest("arg", TWO_F64_IN_ONE_F64_OUT, "Argument")
test04.setTestList([new WasmFunctionTestValues([3,4], [0.9272952180016122])])

const test05 = new WasmFunctionTest("conj", TWO_F64_IN_TWO_F64_OUT, "Conjugate")
test05.setTestList([new WasmFunctionTestValues([7,4], [7,-4])])

const test06 = new WasmFunctionTest("norm_sqr", TWO_F64_IN_ONE_F64_OUT, "Normal square")
test06.setTestList([new WasmFunctionTestValues([7,4], [65])])

const test07 = new WasmFunctionTest("inv", TWO_F64_IN_TWO_F64_OUT, "Inverse")
test07.setTestList([new WasmFunctionTestValues([7,4], [(_ => 7/65)(), (_ => -4/65)()])])

const test08 = new WasmFunctionTest("to_polar", TWO_F64_IN_TWO_F64_OUT, "Convert to polar coordinates")
test08.setTestList([new WasmFunctionTestValues([3,4], [5,0.9272952180016122])])

const test09 = new WasmFunctionTest("to_rect", TWO_F64_IN_TWO_F64_OUT, "Convert to rectangular coordinates")
test09.setTestList([new WasmFunctionTestValues([5,0.9272952180016122], [3,4])])

const test10 = new WasmFunctionTest("mul_by_conj", TWO_F64_IN_ONE_F64_OUT, "Multiply a complex number by its own conjugate")
test10.setTestList([new WasmFunctionTestValues([7,4], [65])])

const test11 = new WasmFunctionTest("mul_by_i", TWO_F64_IN_TWO_F64_OUT, "Multiply a complex number by i")
test11.setTestList([new WasmFunctionTestValues([-5,-2], [2,-5])])

const test12 = new WasmFunctionTest("sqr", TWO_F64_IN_TWO_F64_OUT, "Square a complex number")
test12.setTestList([new WasmFunctionTestValues([5,2], [21,20])])

const test13 = new WasmFunctionTest("taxi", TWO_F64_IN_ONE_F64_OUT, "Taxi distance to origin")
test13.setTestList([new WasmFunctionTestValues([5,2], [7])])

const test14 = new WasmFunctionTest("sqrt_1mz2", TWO_F64_IN_TWO_F64_OUT, "Square root of one minus the complex number squared")
test14.setTestList([new WasmFunctionTestValues([5,2], [2.0352237281760823,-4.913464727026231])])

const test15 = new WasmFunctionTest("sqrt_1pz2", TWO_F64_IN_TWO_F64_OUT, "Square root of one plus the complex number squared")
test15.setTestList([new WasmFunctionTestValues([5,2], [5.085869517331181,1.9662321193893937])])

const test16 = new WasmFunctionTest("sum_of_sqrs", TWO_F64_IN_ONE_F64_OUT, "Sum of squares")
test16.setTestList([
  new WasmFunctionTestValues([5,2],     [29]),
  new WasmFunctionTestValues([1,1],      [2]),
  new WasmFunctionTestValues([-1,-1],    [2]),
  new WasmFunctionTestValues([0.5,0.5], [0.5]),
])

const test17 = new WasmFunctionTest("diff_of_sqrs", TWO_F64_IN_ONE_F64_OUT, "Difference of squares")
test17.setTestList([
  new WasmFunctionTestValues([5,2],     [21]),
  new WasmFunctionTestValues([1,1],     [0]),
  new WasmFunctionTestValues([-1,-1],   [0]),
  new WasmFunctionTestValues([0.5,0.5], [0]),
])

const test18 = new WasmFunctionTest("ln", TWO_F64_IN_TWO_F64_OUT, "Natural logarithm")
test18.setTestList([
  new WasmFunctionTestValues([5,0],  [1.6094379124341003,0]),
  new WasmFunctionTestValues([-5,0], [1.6094379124341003,-3.141592653589793]),
  new WasmFunctionTestValues([0,2],  [0.6931471805599453,1.5707963267948966]),
  new WasmFunctionTestValues([0,-2], [0.6931471805599453,-1.5707963267948966]),
  new WasmFunctionTestValues([5,2],  [1.6836479149932368,0.3805063771123649]),
  new WasmFunctionTestValues([5,-2], [1.6836479149932368,-0.3805063771123649]),
])

const test19 = new WasmFunctionTest("sqrt", TWO_F64_IN_TWO_F64_OUT, "Principal value of square root")
test19.setTestList([
  new WasmFunctionTestValues([0,0],   [0,0]),
  new WasmFunctionTestValues([5,0],   [2.23606797749979, 0]),
  new WasmFunctionTestValues([-5,0],  [0, 2.23606797749979]),
  new WasmFunctionTestValues([0,2],   [1,1]),
  new WasmFunctionTestValues([0,-2],  [1,-1]),
  new WasmFunctionTestValues([5,2],   [2.27872385417085, 0.43884211690225455]),
  new WasmFunctionTestValues([5,-2],  [2.27872385417085,-0.43884211690225455]),
  new WasmFunctionTestValues([-5,2],  [0.43884211690225466,2.27872385417085]),
  new WasmFunctionTestValues([-5,-2], [0.43884211690225466,-2.27872385417085]),
])

const test20 = new WasmFunctionTest("add", FOUR_F64_IN_TWO_F64_OUT, "Add two complex numbers")
test20.setTestList([
  new WasmFunctionTestValues([0,0,0,0],   [0,0]),
  new WasmFunctionTestValues([5,0,2,0],   [7,0]),
  new WasmFunctionTestValues([-5,0,2,0],  [-3,0]),
  new WasmFunctionTestValues([-5,0,-2,0], [-7,0]),
  new WasmFunctionTestValues([5,3,0,0],   [5,3]),
  new WasmFunctionTestValues([5,3,2,0],   [7,3]),
  new WasmFunctionTestValues([5,3,2,2],   [7,5]),
  new WasmFunctionTestValues([5,3,-2,0],  [3,3]),
  new WasmFunctionTestValues([5,3,2,-2],  [7,1]),
  new WasmFunctionTestValues([5,3,-2,-2], [3,1]),
])

const test21 = new WasmFunctionTest("sub", FOUR_F64_IN_TWO_F64_OUT, "Subtract two complex numbers")
test21.setTestList([
  new WasmFunctionTestValues([0,0,0,0],   [0,0]),
  new WasmFunctionTestValues([5,0,2,0],   [3,0]),
  new WasmFunctionTestValues([-5,0,2,0],  [-7,0]),
  new WasmFunctionTestValues([-5,0,-2,0], [-3,0]),
  new WasmFunctionTestValues([5,3,0,0],   [5,3]),
  new WasmFunctionTestValues([5,3,2,0],   [3,3]),
  new WasmFunctionTestValues([5,3,2,2],   [3,1]),
  new WasmFunctionTestValues([5,3,-2,0],  [7,3]),
  new WasmFunctionTestValues([5,3,2,-2],  [3,5]),
  new WasmFunctionTestValues([5,3,-2,-2], [7,5]),
])

const test22 = new WasmFunctionTest("mul", FOUR_F64_IN_TWO_F64_OUT, "Mutiply two complex numbers")
test22.setTestList([
  new WasmFunctionTestValues([0,0,0,0],   [0,0]),
  new WasmFunctionTestValues([5,0,2,0],   [10,0]),
  new WasmFunctionTestValues([-5,0,2,0],  [-10,0]),
  new WasmFunctionTestValues([-5,0,-2,0], [10,0]),
  new WasmFunctionTestValues([5,3,0,0],   [0,0]),
  new WasmFunctionTestValues([5,3,2,0],   [10,6]),
  new WasmFunctionTestValues([5,3,2,2],   [4,16]),
  new WasmFunctionTestValues([5,3,-2,0],  [-10,-6]),
  new WasmFunctionTestValues([5,3,2,-2],  [16,-4]),
  new WasmFunctionTestValues([5,3,-2,-2], [-4,-16]),
])

const test23 = new WasmFunctionTest("div", FOUR_F64_IN_TWO_F64_OUT, "Divide two complex numbers")
test23.setTestList([
// new WasmFunctionTestValues([0,0,0,0],   [0,0]),
   new WasmFunctionTestValues([5,0,2,0],   [2.5,0]),
   new WasmFunctionTestValues([-5,0,2,0],  [-2.5,0]),
   new WasmFunctionTestValues([-5,0,-2,0], [2.5,0]),
// new WasmFunctionTestValues([5,3,0,0],   [0,0]),
   new WasmFunctionTestValues([5,3,2,0],   [2.5,1.5]),
   new WasmFunctionTestValues([5,3,2,2],   [2,-0.5]),
   new WasmFunctionTestValues([5,3,-2,0],  [-2.5,-1.5]),
   new WasmFunctionTestValues([5,3,2,-2],  [0.5,2]),
   new WasmFunctionTestValues([5,3,-2,-2], [-2,0.5]),
])

const test24 = new WasmFunctionTest("sin", TWO_F64_IN_TWO_F64_OUT, "Complex sine")
test24.setTestList([new WasmFunctionTestValues([5,2], [-3.6076607742131563,1.0288031496599335])])

const test25 = new WasmFunctionTest("asin", TWO_F64_IN_TWO_F64_OUT, "Complex arcsine")
test25.setTestList([new WasmFunctionTestValues([5,2], [1.1842316842750185,2.3705485373179185])])

const test26 = new WasmFunctionTest("sinh", TWO_F64_IN_TWO_F64_OUT, "Complex hyperbolic sine")
test26.setTestList([new WasmFunctionTestValues([5,2], [-30.879431343588244,67.47891523845588])])

const test27 = new WasmFunctionTest("asinh", TWO_F64_IN_TWO_F64_OUT, "Complex hyperbolic arcsine")
test27.setTestList([new WasmFunctionTestValues([-30.879431343588244,67.47891523845588], [-5.000000000001505,1.141592653589953])])

const test28 = new WasmFunctionTest("cos", TWO_F64_IN_TWO_F64_OUT, "Complex cosine")
test28.setTestList([new WasmFunctionTestValues([5,2], [1.0671926518731156,3.4778844858991573])])

const test29 = new WasmFunctionTest("acos", TWO_F64_IN_TWO_F64_OUT, "Complex arccosine")
test29.setTestList([new WasmFunctionTestValues([5,2], [0.38656464251987477,-2.37054853731792])])

const test30 = new WasmFunctionTest("cosh", TWO_F64_IN_TWO_F64_OUT, "Complex hyperbolic cosine")
test30.setTestList([new WasmFunctionTestValues([5,2], [-30.88223531891674,67.47278844058752])])

const test31 = new WasmFunctionTest("acosh", TWO_F64_IN_TWO_F64_OUT, "Complex hyperbolic arccosine")
test31.setTestList([new WasmFunctionTestValues([-30.88223531891674,67.47278844058752], [5,2])])

const test32 = new WasmFunctionTest("tan", TWO_F64_IN_TWO_F64_OUT, "Complex tangent")
test32.setTestList([new WasmFunctionTestValues([5,2], [-0.020553016568255644,1.0310080051524912])])

const test33 = new WasmFunctionTest("atan", TWO_F64_IN_TWO_F64_OUT, "Complex arctangent")
test33.setTestList([new WasmFunctionTestValues([5,2], [1.399284356584545,0.06706599664866997])])

const test34 = new WasmFunctionTest("tanh", TWO_F64_IN_TWO_F64_OUT, "Complex hyperbolic tangent")
test34.setTestList([new WasmFunctionTestValues([5,2], [1.000059350149,-0.00006872163880119275])])

const test35 = new WasmFunctionTest("atanh", TWO_F64_IN_TWO_F64_OUT, "Complex hyperbolic arctangent")
test35.setTestList([new WasmFunctionTestValues([1.000059350149,-0.00006872163880119275], [4.999999999999926,-1.1415926535898788])])

const complexTestMap = [
  test01, test02, test03, test04, test05,
  test06, test07, test08, test09, test10,
  test11, test12, test13, test14, test15,
  test16, test17, test18, test19, test20,
  test21, test22, test23, test24, test25,
  test26, test27, test28, test29, test30,
  test31, test32, test33, test34, test35,
].reduce(
  (map, test) => {
    map.set(test.function.name, test)
    return map
  }, new Map())

export {
  complexTestMap
}
