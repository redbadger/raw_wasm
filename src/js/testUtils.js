import { F32, F64 } from './wasmUtils.js'

/***********************************************************************************************************************
 * Test whether the difference between two values is smaller than a given tolerance
 *
 * @param {number} tol - Tolerance value
 * @param {number} val - The value received from the test output
 * @param {number} req - The expected test output value
 *
 * @returns {boolean}
 */
const closeEnough = (tol, val, req) => req + tol >= val && req - tol <= val

/***********************************************************************************************************************
 * Test whether the receievd value and the expected value are within the acceptable tolerance for their datatype
 *
 * @param {WasmDatatype} datatype - WASM interface datatype
 * @param {number}       actual   - Actual test output value
 * @param {number}       expected - Expected test output value
 *
 * @returns {boolean}
 */
const isWithinTolerance =
  (datatype, actual, expected) =>
    datatype.label === F64.label
    ? closeEnough(F64.tolerance, actual, expected)
    : datatype.label === F32.label
      ? closeEnough(F32.tolerance, actual, expected)
      : actual === expected

/***********************************************************************************************************************
 * Check whether two arrays are equal. This test first requires that:
 * a) Both arguments are arrays
 * b) Both array arguments have identical length
 *
 * If this condition is satisfied, then a pointwise comparison of the corresponding array elements is performed
 *
 * @param {WasmDatatype[]} outTypes - An array holding the datatype of each element in the comparison arrays
 * @param {number[]}       a1       - Array 1
 * @param {number[]}       a2       - Array 2
 *
 * @returns {Object} A comparison object containing first, a boolean to indicate whether or not the two arrays are even
 *                   comparable, and second, an array of objects where each object holds a pair of booleans.
 *                   Each pair of booleans correspond to the comparison of the array elements at a given index.
 *                   The following return values are possible:
 *                   Strict equality                          = { "equal" : true,  "withinTolerance" : true }
 *                   Not strictly equal, but within tolerance = { "equal" : false, "withinTolerance" : true }
 *                   Not strictly equal and outside tolerance = { "equal" : false, "withinTolerance" : false }
 */
const checkArrayEquality =
  (outTypes, a1, a2) => {
    let comparison = {
      "comparable" : true,
      "elementEquality" : []
    }

    // Are the arrays comparable?
    if (Array.isArray(a1) && Array.isArray(a2) && a1.length === a2.length) {
      // Yup, so determine equality of each array element
      comparison.elementEquality = a1.reduce(
        (acc, val, idx) => {
          acc.push(
            val === a2[idx]
            ? { "equal" : true, "withinTolerance" : true }
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

/***********************************************************************************************************************
 * Perform a single test of a function exported from a WASM module
 *
 * @param {string} fnName        - The name of the function being tested
 * @param {string} fnInstance    - The WASM module instance containing function {fnName}
 * @param {string} fnOutputArity - The datatype(s) returned from the function being tested
 * @param {string} testData      - The data to run this and the expected result(s)
 *
 * @returns {Object} An object containing a description of the test run and its outcome together with a count of the
 *                   number of successful and failed tests
 */
const fnTester =
  (fnName, fnInstance, fnOutputArity, testData) => {
    let passed  = 0
    let failed  = 0
    let outcome = ""
    let got     = fnInstance(...testData.whenPassed)   // Test the function

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

/***********************************************************************************************************************
 * Test all functions exported by a WASM module
 *
 * @param {boolean} runTests     - If set to false, all tests are bypassed
 * @param {object}  wasmInstance - An executable WASM module instance
 * @param {object}  wasmTestMap  - A Map object containing one or more tests for each exported function
 * @param {boolean} showDetail   - Should detailed test results be displayed?
 */
const testWasm =
  (runTests, wasmInstance, wasmTestMap, showDetail) => {
    if (runTests) {
      // Test everything exported from the WASM module
      // At the moment, the useful information within the WASM instance (such as "what kind of thing is this export") is
      // not available to JS as it is currently carried within the internal property [[Module]]
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
            test.description = `WARNING: No tests found for exported WASM function '${exp}'`
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

/***********************************************************************************************************************
 * Write a WASM module test report to the browser console
 *
 * @param {Object}  testReport - An object containing the results of a WASM module's test run
 * @param {boolean} showDetail - Should a detailed test report be produced?
 */
const showTestReport =
  (testReport, showDetail) => {
    // Write test summary
    let action  = 'log'
    let msg     = 'All WASM exports tested'
    let summary = `Performed ${testReport.passed + testReport.failed} tests: ${testReport.passed} passed, ${testReport.failed} failed`

    if (testReport.missing) {
      action = 'warn'
      msg = `${testReport.missing} WASM export test${testReport.missing === 1 ? "" : "s"} missing`
    }

    console[action](msg)
    console.log(summary)

    // Optionally, write test details
    if (showDetail) showTestDetail(testReport)
  }

/***********************************************************************************************************************
 * Write a detailed WASM module test report to the browser console
 *
 * @param {Object}  An object containing the results of a WASM module's test run
 */
 const showTestDetail =
  testReport =>
    testReport
      .testList
      .map(test => {
        console.log(test.description)

        if (test.outcomes.length > 0)
          test.outcomes.map(
            o => console[o.msg.slice(0,4) === "PASS" ? "log" : "error"](`  ${o.msg}`)
          )
      })

/***********************************************************************************************************************
 * Utility function to display the contents of the "host functions" object
 *
 * @params {Object} hostFns - The object containing all the host functions
 */
const showHostFns =
  hostFns =>
    Object
      .keys(hostFns)
      .map(libName =>
        Object
          .keys(hostFns[libName])
          .map(fn => console.log(`${libName}.${fn} : ${hostFns[libName][fn]}`))
      )

// ---------------------------------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------------------------------
export {
  testWasm,
  showTestReport,
  showHostFns,
}
