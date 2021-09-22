const typeOf     = x => Object.prototype.toString.apply(x).slice(8).slice(0, -1)
const isOfType   = t => x => typeOf(x) === t
const isArray    = isOfType("Array")
const isFunction = isOfType("Function")

// These tolerance values are somewhat arbitrary...
const F64 = { "label": "f64", "tolerance" : 0.0000000000000005 }
const F32 = { "label": "f32", "tolerance" : 0.0000000000000005 }

// -----------------------------------------------------------------------------
const TWO_F64_IN_ONE_F64_OUT  = { "input" : [F64, F64],           "output" : [F64] }
const TWO_F64_IN_TWO_F64_OUT  = { "input" : [F64, F64],           "output" : [F64, F64] }
const FOUR_F64_IN_TWO_F64_OUT = { "input" : [F64, F64, F64, F64], "output" : [F64, F64] }

// Yeah, whatever...
const closeEnough = (tol, val, req) => req + tol >= val && req - tol <= val

// -----------------------------------------------------------------------------
const isWithinTolerance =
  (datatype, actual, expected) =>
    datatype.label === F64.label
    ? closeEnough(F64.tolerance, actual, expected)
    : datatype.label === F32.label
      ? closeEnough(F32.tolerance, actual, expected)
      : actual === expected

// -----------------------------------------------------------------------------
const checkArrayEquality =
  (outTypes, a1, a2) => {
    let comparison = {
      "comparable" : true,
      "elementEquality" : []
    }

    // Are the arrays comparable?
    if (isArray(a1) && isArray(a2) && a1.length === a2.length) {
      // Yup, so determine equality of each array element
      comparison.elementEquality = a1.reduce(
        (acc, val, idx) => {
          acc.push(
            val === a2[idx]
            ? { "equal" : true, "withinTolerance" : false }
            : isWithinTolerance(outTypes[idx], val, a2[idx])
              ? { "equal" : false, "withinTolerance" : true }
              : { "equal" : false, "withinTolerance" : false }
          )

          return acc
        },
        [])
    } else
      comparison.comparable = false

    return comparison
  }

// -----------------------------------------------------------------------------
const fnTester =
  (fnName, fnInstance, fnOutputArity, testData) => {
    let passed  = 0
    let failed  = 0
    let outcome = ""
    let got     = fnInstance(...testData.whenPassed)

    if (fnOutputArity.length === 1) got = [got]

    let comparison = checkArrayEquality(fnOutputArity, got, testData.shouldGet)

    if (!comparison.comparable) {
      outcome = `FAIL: Arrays of differing length or type are not comparable`
    } else {
      let els = comparison.elementEquality

      if (els.every(el => el.equal || el.withinTolerance)) {
        ++passed
        outcome = `PASS${els.some(el => el.withinTolerance) ? " (within tolerance)" : ""}`
      } else {
        ++failed
        outcome = "FAIL"
      }
    }

    return {
      "msg"    : `${outcome}: ${fnName}(${testData.whenPassed}) => [${got}], expected [${testData.shouldGet}]`,
      "passed" : passed,
      "failed" : failed
    }
  }

// -----------------------------------------------------------------------------
const testWasm =
  (runTests, wasmInstance, wasmTestMap, showDetail) => {
    if (runTests) {
      // Test everything exported from the WASM module
      // At the moment, the useful information within the WASM instance (such as
      // "what kind of thing is this export") is not available to JS as it is
      // currently carried within the internal property [[Module]]
      let testReport = Object
        .keys(wasmInstance.exports)
        .reduce((acc, exp) => {
          let fnTest = wasmTestMap.get(exp)
          let test = {
            "description" : "",
            "outcomes" : {}
          }

          if (!fnTest) {
            ++acc.missing
            test.description = `WARNING: No test found for exported WASM function '${exp}'`
          }
          else {
            let fnName = fnTest.function.name

            test.description = `Test name: '${fnTest.description}'`
            test.outcomes    = fnTest.testList.map(testData =>
              fnTester(
                fnName,
                wasmInstance.exports[fnName],
                fnTest.function.arity.output,
                testData
              )
            )

            test.outcomes.map(outcome => {
              acc.passed += outcome.passed
              acc.failed += outcome.failed
            })
          }

          acc.testList.push(test)

          return acc
        }, {
          "passed"   : 0,
          "failed"   : 0,
          "missing"  : 0,
          "testList" : []
        })

      showTestReport(testReport, showDetail)
    }
  }

// -----------------------------------------------------------------------------
const showTestReport =
  (testReport, showDetail) => {
    // Write test summary
    let total = testReport.passed + testReport.failed

    if (testReport.missing)
      console.warn(
        `${testReport.missing} WASM export test${testReport.missing === 1 ? "" : "s"} missing`
      )
    else
      console.log(`All WASM exports tested`)

    console.log(
      `Performed ${total} tests: ${testReport.passed} passed, ${testReport.failed} failed`
    )

    // Optionally, write test details
    showTestDetail(testReport, showDetail)
  }

// -----------------------------------------------------------------------------
const showTestDetail =
  (testReport, showDetail) =>
    showDetail
    ? testReport
        .testList
        .map(test => {
          console.log(test.description)

          if (test.outcomes.length > 0)
            test.outcomes.map(
              o => console[o.msg.slice(0,4) === "PASS" ? "log" : "error"](`  ${o.msg}`)
            )
        })
    : null

// -----------------------------------------------------------------------------
const showHostFns =
  wasmMod =>
    Object
      .keys(wasmMod.hostFns)
      .map(libName =>
        Object
          .keys(wasmMod.hostFns[libName])
          .map(fn => console.log(`${libName}.${fn} : ${wasmMod.hostFns[libName][fn]}`))
        )

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------
export {
  isArray,
  isFunction,

  F64,
  F32,
  TWO_F64_IN_ONE_F64_OUT,
  TWO_F64_IN_TWO_F64_OUT,
  FOUR_F64_IN_TWO_F64_OUT,

  checkArrayEquality,

  testWasm,
  showTestReport,
  showHostFns,
}
