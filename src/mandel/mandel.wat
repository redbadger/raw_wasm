(module
  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Complex functions
  (import "cplx" "add"         (func $add         (param f64 f64 f64 f64) (result f64 f64)))
  (import "cplx" "sum_of_sqrs" (func $sum_of_sqrs (param f64 f64) (result f64)))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Does the point lie within the period 2 bulb?
  (func $is_in_period_2_bulb
        (param $x f64)
        (param $y f64)
        (result i32)

    (local $return_val i32)

    (if (f64.le
          (call $sum_of_sqrs (f64.add (local.get $x) (f64.const 1.0)) (local.get $y))
          (f64.const 0.0625))
      (then (local.set $return_val (i32.const 1)))
      (else (local.set $return_val (i32.const 0)))
    )

    (local.get $return_val)
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Test we can add two complex numbers together using imported function
  (func $test_add
        (export "test_add")
        (param $z1_real f64)
        (param $z1_cplx f64)
        (param $z2_real f64)
        (param $z2_cplx f64)
        (result f64 f64)
    (call $add (local.get $z1_real) (local.get $z1_cplx)
               (local.get $z2_real) (local.get $z2_cplx)
    )
  )
)
