(module
  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Complex functions
  (import "cplx" "sum_of_sqrs" (func $sum_of_sqrs (param f64 f64) (result f64)))

  (global $TRUE  i32 (i32.const 1))
  (global $FALSE i32 (i32.const 0))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Does the point lie within the main cardioid?
  (func $is_in_main_cardioid
        (export "is_in_main_cardioid")
        (param $x f64)
        (param $y f64)
        (result i32)

    (local $x_minus_qtr f64)
    (local $y_sqrd      f64)
    (local $q           f64)
    (local $temp        f64)
    (local $return_val  i32)

    (local.set $x_minus_qtr (f64.sub (local.get $x) (f64.const 0.25)))
    (local.set $y_sqrd      (f64.mul (local.get $y) (local.get $y)))
    (local.set $q           (f64.add (f64.mul (local.get $x_minus_qtr) (local.get $x_minus_qtr)) (local.get $y_sqrd)))

    (if (f64.le
          (f64.mul (local.get $q)
                   (f64.add (local.get $q) (local.get $x_minus_qtr)))
          (f64.mul (f64.const 0.25) (local.get $y_sqrd)))
      (then (local.set $return_val (global.get $TRUE)))
      (else (local.set $return_val (global.get $FALSE)))
    )

    (local.get $return_val)
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Does the point lie within the period 2 bulb?
  (func $is_in_period_2_bulb
        (export "is_in_period_2_bulb")
        (param $x f64)
        (param $y f64)
        (result i32)

    (local $return_val i32)

    (if (f64.le
          (call $sum_of_sqrs (f64.add (local.get $x) (f64.const 1.0)) (local.get $y))
          (f64.const 0.0625))
      (then (local.set $return_val (global.get $TRUE)))
      (else (local.set $return_val (global.get $FALSE)))
    )

    (local.get $return_val)
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Can we bail out of the Mandelbrot escape time algorithm early?
  (func $mandel_early_bailout
        (export "mandel_early_bailout")
        (param $x f64)
        (param $y f64)
        (result i32)

    (local $return_val i32)

    (if (i32.or
          (call $is_in_main_cardioid (local.get $x) (local.get $y))
          (call $is_in_period_2_bulb (local.get $x) (local.get $y))
        )
      (then (local.set $return_val (global.get $TRUE)))
      (else (local.set $return_val (global.get $FALSE)))
    )

    (local.get $return_val)
  )

)
