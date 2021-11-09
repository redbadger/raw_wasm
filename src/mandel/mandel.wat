(module
  (global $BAILOUT f64 (f64.const 4.0))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Escape time algorithm for calculating either the Mandelbrot or Julia sets
  (func $escape_time_mj
        (export "escape_time_mj")
        (param $mandel_x  f64)
        (param $mandel_y  f64)
        (param $x         f64)
        (param $y         f64)
        (param $max_iters i32)
        (result i32)

    (local $iters i32)
    (local $new_x f64)
    (local $new_y f64)

    (loop $repeat
      (block $quit
        ;; Quit the loop if we have either exceeded the bailout value or hit the iteration limit
        (br_if $quit
          (i32.or
              (f64.gt
                ;; ($x^2 + $y^2) > $BAILOUT?
                (f64.add
                  (f64.mul (local.get $x) (local.get $x))
                  (f64.mul (local.get $y) (local.get $y))
                )
                (global.get $BAILOUT)
              )
              ;; $iters >= max_iters?
              (i32.ge_u (local.get $iters) (local.get $max_iters))
          )
        )

        ;; $new_x = $mandel_x + ($x^2 - $y^2)
        (local.set
          $new_x
          (f64.add
            (local.get $mandel_x)
            (f64.sub
              (f64.mul (local.get $x) (local.get $x))
              (f64.mul (local.get $y) (local.get $y))
            )
          )
        )
        ;; $new_y = $mandel_y + ($y * 2 * $x)
        (local.set
          $new_y
          (f64.add (local.get $mandel_y)
                   (f64.mul (local.get $y) (f64.add (local.get $x) (local.get $x)))
          )
        )
        (local.set $x     (local.get $new_x))
        (local.set $y     (local.get $new_y))
        (local.set $iters (i32.add (local.get $iters) (i32.const 1)))

        br $repeat
      )
    )

    (local.get $iters)
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Calculate one pixel of the Mandelbrot set
  (func $gen_mandel_pixel
        (export "gen_mandel_pixel")
        (param $x f64)
        (param $y f64)
        (param $max_iters i32)
        (result i32)

    (local $return_val i32)

    (local $x_plus_1    f64)
    (local $x_minus_qtr f64)
    (local $y_sqrd      f64)
    (local $q           f64)
    (local $temp        f64)

    (local.set $x_plus_1    (f64.add (local.get $x) (f64.const 1.0)))
    (local.set $x_minus_qtr (f64.sub (local.get $x) (f64.const 0.25)))
    (local.set $y_sqrd      (f64.mul (local.get $y) (local.get $y)))
    (local.set $q           (f64.add (f64.mul (local.get $x_minus_qtr) (local.get $x_minus_qtr)) (local.get $y_sqrd)))

    (local.set $return_val (local.get $max_iters))

    (block $bail_out_early
      ;; Can we avoid running the escape time calculation?
      (br_if $bail_out_early
        (i32.or
          ;; Is point in main cardioid?
          (f64.le
            (f64.mul
              (local.get $q)
              (f64.add (local.get $q) (local.get $x_minus_qtr))
            )
            (f64.mul
              (f64.const 0.25)
              (local.get $y_sqrd)
            )
          )
          ;; Is point in period-2 bulb?
          (f64.le
            (f64.add
              (f64.mul (local.get $x_plus_1) (local.get $x_plus_1))
              (f64.mul (local.get $y) (local.get $y))
            )
            (f64.const 0.0625)
          )
        )
      )

      (local.set
        $return_val
        (call $escape_time_mj
          (local.get $x)
          (local.get $y)
          (f64.const 0)
          (f64.const 0)
          (local.get $max_iters)
        )
      )
    )

    (local.get $return_val)
  )
)
