import {
  TWO_F64_IN_ONE_F64_OUT,
  TWO_F64_IN_TWO_F64_OUT,
  FOUR_F64_IN_TWO_F64_OUT
} from "../js/wasmUtils.js"

const complexTestMap = new Map()

complexTestMap.set("real", {
  "description": "Real part",
  "function": { "name": "real", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2], "shouldGet": [5] }
  ]
})

complexTestMap.set("imag", {
  "description": "Imaginary part",
  "function": { "name": "imag", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2], "shouldGet": [2] }
  ]
})

complexTestMap.set("hypot", {
  "description": "Hypotenuse length",
  "function": { "name": "hypot", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [3,4], "shouldGet": [5] }
  ]
})

complexTestMap.set("arg", {
  "description": "Argument",
  "function": { "name": "arg", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [3,4], "shouldGet": [0.9272952180016122] }
  ]
})

complexTestMap.set("conj", {
  "description": "Conjugate",
  "function": { "name": "conj", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [7,4], "shouldGet": [7,-4] }
  ]
})

complexTestMap.set("norm_sqr", {
  "description": "Normal square",
  "function": { "name": "norm_sqr", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [7,4], "shouldGet": [65] }
  ]
})

complexTestMap.set("inv", {
  "description": "Inverse",
  "function": { "name": "inv", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [7,4], "shouldGet": [(_ => 7/65)(), (_ => -4/65)()] }
  ]
})

complexTestMap.set("to_polar", {
  "description": "Convert to polar coordinates",
  "function": { "name": "to_polar", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [3,4], "shouldGet": [5,0.9272952180016122] }
  ]
})

complexTestMap.set("to_rect", {
  "description": "Convert to rectangular coordinates",
  "function": { "name": "to_rect", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [5,0.9272952180016122], "shouldGet": [3,4] }
  ]
})

complexTestMap.set("mul_by_conj", {
  "description": "Multiply a complex number by its own conjugate",
  "function": { "name": "mul_by_conj", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [7,4], "shouldGet": [65] }
  ]
})

complexTestMap.set("mul_by_i", {
  "description": "Multiply a complex number by i",
  "function": { "name": "mul_by_i", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [-5,-2], "shouldGet": [2,-5] }
  ]
})

complexTestMap.set("sqr", {
  "description": "Square a complex number",
  "function": { "name": "sqr", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2], "shouldGet": [21,20] }
  ]
})

complexTestMap.set("taxi", {
  "description": "Taxi distance to origin",
  "function": { "name": "taxi", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2], "shouldGet": [7] }
  ]
})

complexTestMap.set("sqrt_1mz2", {
  "description": "Square root of one minus the complex number squared",
  "function": { "name": "sqrt_1mz2", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2], "shouldGet": [2.0352237281760823,-4.913464727026231] }
  ]
})

complexTestMap.set("sqrt_1pz2", {
  "description": "Square root of one plus the complex number squared",
  "function": { "name": "sqrt_1pz2", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2], "shouldGet": [5.085869517331181,1.9662321193893937] }
  ]
})

complexTestMap.set("sum_of_sqrs", {
  "description": "Sum of squares",
  "function": { "name": "sum_of_sqrs", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2],     "shouldGet": [29] },
    { "whenPassed": [1,1],     "shouldGet": [2] },
    { "whenPassed": [-1,-1],   "shouldGet": [2] },
    { "whenPassed": [0.5,0.5], "shouldGet": [0.5] }
  ]
})

complexTestMap.set("diff_of_sqrs", {
  "description": "Difference of squares",
  "function": { "name": "diff_of_sqrs", "arity": TWO_F64_IN_ONE_F64_OUT },
  "testList" : [
    { "whenPassed": [5,2],     "shouldGet": [21] },
    { "whenPassed": [1,1],     "shouldGet": [0] },
    { "whenPassed": [-1,-1],   "shouldGet": [0] },
    { "whenPassed": [0.5,0.5], "shouldGet": [0] }
  ]
})

complexTestMap.set("ln", {
  "description": "Natural logarithm",
  "function": { "name": "ln", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [5,0],  "shouldGet" : [1.6094379124341003,0] },
    { "whenPassed": [-5,0], "shouldGet" : [1.6094379124341003,-3.141592653589793] },
    { "whenPassed": [0,2],  "shouldGet" : [0.6931471805599453,1.5707963267948966] },
    { "whenPassed": [0,-2], "shouldGet" : [0.6931471805599453,-1.5707963267948966] },
    { "whenPassed": [5,2],  "shouldGet" : [1.6836479149932368,0.3805063771123649] },
    { "whenPassed": [5,-2], "shouldGet" : [1.6836479149932368,-0.3805063771123649] }
  ]
})

complexTestMap.set("sqrt", {
  "description": "Principal value of square root",
  "function": { "name": "sqrt", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [0,0],   "shouldGet": [0,0] },
    { "whenPassed": [5,0],   "shouldGet": [2.23606797749979, 0] },
    { "whenPassed": [-5,0],  "shouldGet": [0, 2.23606797749979] },
    { "whenPassed": [0,2],   "shouldGet": [1,1] },
    { "whenPassed": [0,-2],  "shouldGet": [1,-1] },
    { "whenPassed": [5,2],   "shouldGet": [2.27872385417085, 0.43884211690225455] },
    { "whenPassed": [5,-2],  "shouldGet": [2.27872385417085,-0.43884211690225455] },
    { "whenPassed": [-5,2],  "shouldGet": [0.43884211690225466,2.27872385417085] },
    { "whenPassed": [-5,-2], "shouldGet": [0.43884211690225466,-2.27872385417085] }
  ]
})

complexTestMap.set("add", {
  "description": "Add two complex numbers",
  "function": { "name": "add", "arity": FOUR_F64_IN_TWO_F64_OUT },
  "testList" : [
    { "whenPassed": [0,0,0,0],   "shouldGet": [0,0] },
    { "whenPassed": [5,0,2,0],   "shouldGet": [7,0] },
    { "whenPassed": [-5,0,2,0],  "shouldGet": [-3,0] },
    { "whenPassed": [-5,0,-2,0], "shouldGet": [-7,0] },
    { "whenPassed": [5,3,0,0],   "shouldGet": [5,3] },
    { "whenPassed": [5,3,2,0],   "shouldGet": [7,3] },
    { "whenPassed": [5,3,2,2],   "shouldGet": [7,5] },
    { "whenPassed": [5,3,-2,0],  "shouldGet": [3,3] },
    { "whenPassed": [5,3,2,-2],  "shouldGet": [7,1] },
    { "whenPassed": [5,3,-2,-2], "shouldGet": [3,1] }
  ]
})

complexTestMap.set("sub", {
  "description": "Subtract two complex numbers",
  "function": { "name": "sub", "arity": FOUR_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [0,0,0,0],   "shouldGet" : [0,0] },
    { "whenPassed": [5,0,2,0],   "shouldGet" : [3,0] },
    { "whenPassed": [-5,0,2,0],  "shouldGet" : [-7,0] },
    { "whenPassed": [-5,0,-2,0], "shouldGet" : [-3,0] },
    { "whenPassed": [5,3,0,0],   "shouldGet" : [5,3] },
    { "whenPassed": [5,3,2,0],   "shouldGet" : [3,3] },
    { "whenPassed": [5,3,2,2],   "shouldGet" : [3,1] },
    { "whenPassed": [5,3,-2,0],  "shouldGet" : [7,3] },
    { "whenPassed": [5,3,2,-2],  "shouldGet" : [3,5] },
    { "whenPassed": [5,3,-2,-2], "shouldGet" : [7,5] }
  ]
})

complexTestMap.set("mul", {
  "description": "Multiply two complex numbers",
  "function": { "name": "mul", "arity": FOUR_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed" : [0,0,0,0],   "shouldGet" : [0,0] },
    { "whenPassed" : [5,0,2,0],   "shouldGet" : [10,0] },
    { "whenPassed" : [-5,0,2,0],  "shouldGet" : [-10,0] },
    { "whenPassed" : [-5,0,-2,0], "shouldGet" : [10,0] },
    { "whenPassed" : [5,3,0,0],   "shouldGet" : [0,0] },
    { "whenPassed" : [5,3,2,0],   "shouldGet" : [10,6] },
    { "whenPassed" : [5,3,2,2],   "shouldGet" : [4,16] },
    { "whenPassed" : [5,3,-2,0],  "shouldGet" : [-10,-6] },
    { "whenPassed" : [5,3,2,-2],  "shouldGet" : [16,-4] },
    { "whenPassed" : [5,3,-2,-2], "shouldGet" : [-4,-16] }
  ]
})

complexTestMap.set("div", {
  "description": "Divide two complex numbers",
  "function": { "name": "div", "arity": FOUR_F64_IN_TWO_F64_OUT },
  "testList": [
 // { "whenPassed": [0,0,0,0],   "shouldGet" : [0,0] },
    { "whenPassed": [5,0,2,0],   "shouldGet" : [2.5,0] },
    { "whenPassed": [-5,0,2,0],  "shouldGet" : [-2.5,0], },
    { "whenPassed": [-5,0,-2,0], "shouldGet" : [2.5,0], },
 // { "whenPassed": [5,3,0,0],   "shouldGet" : [0,0], },
    { "whenPassed": [5,3,2,0],   "shouldGet" : [2.5,1.5], },
    { "whenPassed": [5,3,2,2],   "shouldGet" : [2,-0.5], },
    { "whenPassed": [5,3,-2,0],  "shouldGet" : [-2.5,-1.5], },
    { "whenPassed": [5,3,2,-2],  "shouldGet" : [0.5,2], },
    { "whenPassed": [5,3,-2,-2], "shouldGet" : [-2,0.5] },
  ]
})

complexTestMap.set("sin", {
  "description": "Complex sine",
  "function": { "name": "sin", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [-3.6076607742131563,1.0288031496599335] }
  ]
})

complexTestMap.set("asin", {
  "description": "Complex arcsine",
  "function": { "name": "asin", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [1.1842316842750185,2.3705485373179185] }
  ]
})

complexTestMap.set("sinh", {
  "description": "Complex hyperbolic sine",
  "function": { "name": "sinh", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [-30.879431343588244,67.47891523845588] }
  ]
})

complexTestMap.set("asinh", {
  "description": "Complex hyperbolic arcsine",
  "function": { "name": "asinh", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [-30.879431343588244,67.47891523845588], "shouldGet": [-5.000000000001505,1.141592653589953] }
  ]
})

complexTestMap.set("cos", {
  "description": "Complex cosine",
  "function": { "name": "cos", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [1.0671926518731156,3.4778844858991573] }
  ]
})

complexTestMap.set("acos", {
  "description": "Complex arccosine",
  "function": { "name": "acos", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [0.38656464251987477,-2.37054853731792] }
  ]
})

complexTestMap.set("cosh", {
  "description": "Complex hyperbolic cosine",
  "function": { "name": "cosh", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [-30.88223531891674,67.47278844058752] }
  ]
})

complexTestMap.set("acosh", {
  "description": "Complex hyperbolic arccosine",
  "function": { "name": "acosh", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [-30.88223531891674,67.47278844058752], "shouldGet": [5,2] }
  ]
})

complexTestMap.set("tan", {
  "description": "Complex targent",
  "function": { "name": "tan", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [-0.020553016568255644,1.0310080051524912] }
  ]
})

complexTestMap.set("atan", {
  "description": "Complex arctargent",
  "function": { "name": "atan", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [1.399284356584545,0.06706599664866997] }
  ]
})

complexTestMap.set("tanh", {
  "description": "Complex hyperbolic targent",
  "function": { "name": "tanh", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [5,2], "shouldGet": [1.000059350149,-0.00006872163880119275] }
  ]
})

complexTestMap.set("atanh", {
  "description": "Complex hyperbolic arctargent",
  "function": { "name": "atanh", "arity": TWO_F64_IN_TWO_F64_OUT },
  "testList": [
    { "whenPassed": [1.000059350149,-0.00006872163880119275], "shouldGet": [4.999999999999926,-1.1415926535898788] }
  ]
})


export {
  complexTestMap
}
