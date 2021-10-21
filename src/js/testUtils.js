import { F32, F64 } from './wasmUtils.js'

/* ---------------------------------------------------------------------------------------------------------------------
 * Class for formatting an i32 in various ways
 */
class FormatI32 {
  static #hexChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']

  /* -------------------------------------------------------------------------------------------------------------------
   * Format an i32 as a hex string.
   * Use a 4-byte ArrayBuffer as the foundation on which to overlay two masks. This allows a single, 32-bit integer to
   * be written using `mask32`, then using `mask8`, read back again as an array of 4 unsigned bytes
   *
   * @param {number} i32 - A 32-bit integer to be represented as a "0x" prefixed hex string
   * @returns {String}
   */
  static asHexStr = i32 =>
    (byteArray =>
      ((mask32, mask8) => {
        mask32[0] = i32

        // reduceRight is needed to preserve little-endian byte order!
        return mask8.reduceRight(
          (hexStr, n) => `${hexStr}${this.#hexChars[n >> 4]}${this.#hexChars[n & 0x0F]}`,
          "0x")
      })(new Uint32Array(byteArray), new Uint8ClampedArray(byteArray))
    )(new ArrayBuffer(4))

  static asBoolean = i32 => i32 === 0 ? "false" : "true"
  static none = i32 => i32
}


/* ---------------------------------------------------------------------------------------------------------------------
 * Class for performing one or more tests against an exported WASM function
 *
 * @class
 */
class WasmFunctionTestValues {
  #setFormatFn = fmtStr =>
    fmtStr === "boolean"
    ? FormatI32.asBoolean
    : fmtStr === "hex"
      ? FormatI32.asHexStr
      : FormatI32.none

  constructor(whenPassed, shouldGet, formatter) {
    this.whenPassed = whenPassed
    this.shouldGet = shouldGet
    this.formatter = this.#setFormatFn(formatter)
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Class for performing one or more tests against an exported WASM function
 *
 * @class
 */
class WasmFunctionTest {
  constructor(fnName, fnArity, fnDescription) {
    this.function = {}
    this.testList = []
    this.function.name = fnName
    this.function.arity = fnArity
    this.description = fnDescription
  }

  setTestList = testList => this.testList = testList
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Test result value comparison class
 *
 * @class
 *
 * { "equal" : true,  "withinTolerance" : false } = Strict equality
 * { "equal" : false, "withinTolerance" : true }  = Not strictly equal, but within tolerance
 * { "equal" : false, "withinTolerance" : false } = Not equal and outside tolerance
 */
class TestResultComparison {
  constructor(equal, withinTolerance) {
    this.equal = equal
    this.withinTolerance = withinTolerance
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Class that compares whether two arrays are equal.
 *
 * @class
 * @constructor As long as the first two arguments are arrays of equal length, a pointwise comparison of the
 *              corresponding array elements is performed.  If two floating point values are compared, then these can be
 *              considered equal if they fall within the specified tolerance
 *
 * @param {number[]}       array1
 * @param {number[]}       array2
 * @param {WasmDatatype[]} outTypes - An array holding the datatype of each element in the comparison arrays
 *
 * @returns {Object} A comparison object containing first, a boolean to indicate whether or not the two arrays are even
 *                   comparable, and second, an array of objects where each object holds a {TestResultComparison} object
 *                   Each pair of booleans correspond to the comparison of the array elements at a given index.
 */
class ResultsComparison {
  #closeEnough = (tol, val, req) => req + tol >= val && req - tol <= val

  #isWithinTolerance = (actual, expected, datatype) =>
    datatype.label === F64.label
      ? this.#closeEnough(F64.tolerance, actual, expected)
      : datatype.label === F32.label
        ? this.#closeEnough(F32.tolerance, actual, expected)
        : actual === expected

  constructor(array1, array2, outputTypes) {
    this.comparable = true
    this.elementEquality = []
    this.a1 = array1
    this.a2 = array2
    this.outputTypes = outputTypes

    // Are the arrays comparable?
    if (Array.isArray(this.a1) && Array.isArray(this.a2) &&
        this.a1.length === this.a2.length) {
      // Yup, so determine equality of each array element
      this.elementEquality = this.a1.reduce(
        (acc, a1Val, idx) => {
          acc.push(
            // Are these values stricly equal?
            a1Val === this.a2[idx]
            // Yup, then "withinTolerance" is not relevant and should be switched off
            ? new TestResultComparison(true, false)
            // Nope, so test whether values are within floating point tolerance
            : this.#isWithinTolerance(a1Val, this.a2[idx], outputTypes[idx])
              ? new TestResultComparison(false, true)
              : new TestResultComparison(false, false)
          )

          return acc
        },
        [])
    } else {
      // Nope - either they're not both arrays or they're arrays of differing lengths
      this.comparable = false
    }
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Write test result to console
 *
 * @param {String} o     - Object containing test results
 * @param {String} o.msg - Description of test result
 */
const writeTestResultToConsole = o => console[o.msg.slice(0,4) === "PASS" ? "log" : "error"](`  ${o.msg}`)

/* ---------------------------------------------------------------------------------------------------------------------
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

    if (fnOutputArity.length === 1) {
      // If the output arity is a single i32, then pass the actual and expected results to the formatter function
      if (fnOutputArity[0].label === 'i32') {
        got = [testData.formatter(got)]
        testData.shouldGet[0] = testData.formatter(testData.shouldGet[0])
      } else {
        got = [got]
      }
    }

    let comparison = new ResultsComparison(got, testData.shouldGet, fnOutputArity)

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

/* ---------------------------------------------------------------------------------------------------------------------
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

/* ---------------------------------------------------------------------------------------------------------------------
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

/* ---------------------------------------------------------------------------------------------------------------------
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
          test.outcomes.map(writeTestResultToConsole)
      })

/* ---------------------------------------------------------------------------------------------------------------------
 * Utility function to display the contents of the "host functions" object
 *
 * @params {Object} hostFns - The object containing all the host functions
 */
const showHostFns =
  hostFns =>
    Object
      .keys(hostFns)
      .sort()
      .map(libName =>
        Object
          .keys(hostFns[libName])
          .map(fn => console.log(`${libName}.${fn} : ${hostFns[libName][fn]}`))
      )

/* ---------------------------------------------------------------------------------------------------------------------
 * Public API
*/
export {
  testWasm,
  showTestReport,
  showHostFns,

  WasmFunctionTest,
  WasmFunctionTestValues,
}
