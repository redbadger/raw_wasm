(module
  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Import complex functions
  (import "cplx" "sum_of_sqrs"  (func $sum_of_sqrs  (param f64 f64) (result f64)))
  (import "cplx" "diff_of_sqrs" (func $diff_of_sqrs (param f64 f64) (result f64)))

  (global $TRUE  i32 (i32.const 1))
  (global $FALSE i32 (i32.const 0))

  (global $BAILOUT f64 (f64.const 4.0))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Utility functions
  (func $incr_i64 (param $val i32) (result i32) (i32.add (local.get $val) (i32.const 1)))

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
  ;; Can we bail out from the Mandelbrot escape time algorithm early?
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

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Escape time algorithm for calculating both the Mandelbrot set and Julia sets
  (func $escape_time_mj
        (export "escape_time_mj")
        (param $x         f64)
        (param $y         f64)
        (param $start_x   f64)
        (param $start_y   f64)
        (param $max_iters i32)
        (result i32)

    (local $iter_count i32)

    (local $new_x f64)
    (local $new_y f64)

    (local.set $iter_count (i32.const 0))

    (loop $repeat
      (block $quit
        ;; Quit the loop if we have either exceeded the bailout value or hit the iteration limit
        (br_if $quit
          (i32.or
              (f64.gt   (call $sum_of_sqrs (local.get $start_x) (local.get $start_y)) (global.get $BAILOUT))
              (i32.ge_u (local.get $iter_count) (local.get $max_iters))
          )
        )

        (local.set $new_x (f64.add (local.get $x) (call $diff_of_sqrs (local.get $start_x) (local.get $start_y))))
        (local.set $new_y (f64.add (local.get $y)
                                   (f64.mul (f64.const 2.0) (f64.mul (local.get $start_x) (local.get $start_y)))))
        (local.set $start_x (local.get $new_x))
        (local.set $start_y (local.get $new_y))
        (local.set $iter_count (call $incr_i64 (local.get $iter_count)))

        br $repeat
      )
    )

    (local.get $iter_count)
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return the iteration count of one pixel on the Mandelbrot set
  (func $mandel_iter
        (export "mandel_iter")
        (param $x f64)
        (param $y f64)
        (param $max_iters i32)
        (result i32)

    (local $return_val i32)

    (if (call $mandel_early_bailout (local.get $x) (local.get $y))
      (then (local.set $return_val (local.get $max_iters)))
      (else (local.set $return_val
              (call $escape_time_mj (local.get $x) (local.get $y) (f64.const 0) (f64.const 0) (local.get $max_iters))
            )
      )
    )

    (local.get $return_val)
  )

)
