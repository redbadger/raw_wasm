import { checkArrayEquality } from "./utils.js"
import { wasmTestMap } from "./tests.js"

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
      outcome = `FAIL: Arrays are not comparable - type or length difference`
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
  wasmInstance =>
    // Test everything exported from the WASM module
    // At the moment, the useful information within the WASM instance (such as
    // "what kind of thing is this export") is not available to JS as it is
    // currently carried within the internal property [[Module]]
    Object
      .keys(wasmInstance.exports)
      .reduce((acc, exp) => {
        let fnTest = wasmTestMap.get(exp)
        let test = {
          "description" : "",
          "outcomes" : {}
        }

        if (!fnTest) {
          ++acc.missing
          test.description = `No test found for WASM export '${exp}'`
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
        }

        test.outcomes.map(outcome => {
          acc.passed += outcome.passed
          acc.failed += outcome.failed
        })
        acc.testList.push(test)

        return acc
      }, {
        "passed"   : 0,
        "failed"   : 0,
        "missing"  : 0,
        "testList" : []
      })

// -----------------------------------------------------------------------------
const showTestReport =
  (testReport, showDetail) => {
    // Write test summary
    if (testReport.missing) {
      console.warn(`${testReport.missing} WASM export test${testReport.missing === 1 ? "" : "s"} missing`)
    } else {
      console.log(`All WASM exports tested`)
    }

    console.log(`Performed ${testReport.passed + testReport.failed} tests: ${testReport.passed} passed, ${testReport.failed} failed`)

    // Optionally, write test details
    if (showDetail) showTestDetail(testReport)
  }

// -----------------------------------------------------------------------------
const showTestDetail =
  testReport =>
    testReport
      .testList
      .filter(test => test.outcomes.every(o => !(o.equal || o.withinTolerance)))
      .map(test => {
        console.log(test.description)
        test.outcomes.map(
          o => console[o.msg.slice(0,4) === "PASS" ? "log" : "error"](`  ${o.msg}`)
        )
      })

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------
export {
  testWasm,
  showTestReport
}
