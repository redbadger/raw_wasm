(module
  (import "js" "shared_mem" (memory 46 46 shared))
  (global $palette_offset (import "js" "palette_offset") i32)
  (global $BAILOUT f64 (f64.const 4.0))
  (global $BLACK   i32 (i32.const 0xFF000000))

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Escape time algorithm for calculating either the Mandelbrot or Julia sets
  ;; Iterates z[n]^2 + c => z[n+1]
  (func $escape_time_mj
        (param $zx f64)
        (param $zy f64)
        (param $cx f64)
        (param $cy f64)
        (param $max_iters i32)
        (result i32)

    (local $iters i32)
    (local $zx_sqr f64)
    (local $zy_sqr f64)

    (loop $next_iter
      ;; Only continue the loop if we're still within both the bailout value and the iteration limit
      (if
        (i32.and
          ;; $BAILOUT > ($zx_sqr + $zy_sqr)?
          (f64.gt
            (global.get $BAILOUT)
            (f64.add
              ;; Remember the squares of the current $zx and $zy values
              (local.tee $zx_sqr (f64.mul (local.get $zx) (local.get $zx)))
              (local.tee $zy_sqr (f64.mul (local.get $zy) (local.get $zy)))
            )
          )

          ;; $max_iters > iters?
          (i32.gt_u (local.get $max_iters) (local.get $iters))
        )
        (then
          ;; $zy = $cy + (2 * $zy * $zx)
          (local.set $zy (f64.add (local.get $cy) (f64.mul (local.get $zy) (f64.add (local.get $zx) (local.get $zx)))))
          ;; $zx = $cx + ($zx_sqr - $zy_sqr)
          (local.set $zx (f64.add (local.get $cx) (f64.sub (local.get $zx_sqr) (local.get $zy_sqr))))

          (local.set $iters (i32.add (local.get $iters) (i32.const 1)))

          br $next_iter
        )
      )
    )

    (local.get $iters)
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Main cardioid check
  (func $is_in_main_cardioid
        (param $x f64)
        (param $y f64)
        (result i32)
    (local $x_minus_qtr f64)
    (local $y_sqrd      f64)
    (local $q           f64)

    ;; Main cardioid check: $q * ($q + ($x - 0.25)) <= $y^2 / 4
    (f64.le
      (f64.mul
        ;; Intermediate value $q = ($x - 0.25)^2 + $y^2
        (local.tee $q
          (f64.add
            (f64.mul
              (local.tee $x_minus_qtr (f64.sub (local.get $x) (f64.const 0.25)))
              (local.get $x_minus_qtr)
            )
            (local.tee $y_sqrd (f64.mul (local.get $y) (local.get $y)))
          )
        )
        (f64.add (local.get $q) (local.get $x_minus_qtr)))
      (f64.mul (f64.const 0.25) (local.get $y_sqrd))
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Period 2 bulb check: ($x + 1)^2 + $y^2 <= 0.0625
  (func $is_in_period_two_bulb
        (param $x f64)
        (param $y f64)
        (result i32)
    (local $x_plus_1 f64)

    (f64.le
      (f64.add
        (f64.mul
          (local.tee $x_plus_1 (f64.add (local.get $x) (f64.const 1.0)))
          (local.get $x_plus_1)
        )
        (f64.mul (local.get $y) (local.get $y))
      )
      (f64.const 0.0625)
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Check for early bailout
  (func $early_bailout
        (param $x f64)
        (param $y f64)
        (result i32)

    (i32.or
      (call $is_in_main_cardioid   (local.get $x) (local.get $y))
      (call $is_in_period_two_bulb (local.get $x) (local.get $y))
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Plot Mandelbrot or Julia set
  (func (export "mj_plot")
        (param $width i32)          ;; Canvas width
        (param $height i32)         ;; Canvas height
        (param $origin_x f64)       ;; X origin coordinate
        (param $origin_y f64)       ;; Y origin coordinate
        (param $zx f64)             ;; Mouse X coordinate in Mandelbrot Set
        (param $zy f64)             ;; Mouse Y coordinate in Mandelbrot Set
        (param $ppu f64)            ;; Pixels per unit (zoom level)
        (param $max_iters i32)      ;; Maximum iteration count
        (param $is_mandelbrot i32)  ;; Are we plotting the Mandelbrot Set?
        (param $image_offset i32)   ;; Shared memory offset of image data
    (local $cx f64)
    (local $cy f64)
    (local $cx_int f64)
    (local $cy_int f64)
    (local $pixel_val i32)
    (local $pixel_count i32)
    (local $this_pixel i32)
    (local $next_pixel_offset i32)

    ;; How many pixels in total need to be calculated?
    (local.set $pixel_count (i32.mul (local.get $width) (local.get $height)))

    ;; Pick up the shared memory location of the next pixel to render
    ;; Next Mandelbrot Set pixel - offset 0
    ;; Next Julia Set pixel      - offset 4
    (local.set $next_pixel_offset
      (if (result i32)
        (local.get $is_mandelbrot)
        (then (i32.const 0))
        (else (i32.const 4))
      )
    )

    ;; Calculate intermediate X and Y coords from static values
    ;; $origin - ($half_dimension / $ppu)
    (local.set $cx_int
      (f64.sub
        (local.get $origin_x)
        (f64.div (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))) (local.get $ppu))
      )
    )
    (local.set $cy_int
      (f64.sub
        (local.get $origin_y)
        (f64.div (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))) (local.get $ppu))
      )
    )

    (loop $pixels
      ;; Continue plotting pixels?
      (if (i32.gt_u
            (local.get $pixel_count)
            (local.tee $this_pixel
              (i32.atomic.rmw.add (local.get $next_pixel_offset) (i32.const 1))
            )
          )
        (then
          ;; Convert x position to x coordinate
          (local.set $cx
            (f64.add
              (local.get $cx_int)
              (f64.div
                ;; Derive x position from $this_pixel
                (f64.convert_i32_u (i32.rem_u (local.get $this_pixel) (local.get $width)))
                (local.get $ppu)
              )
            )
          )
          ;; Convert y position to y coordinate
          (local.set $cy
            (f64.add
              (local.get $cy_int)
              (f64.div
                ;; Derive y position from $this_pixel
                (f64.convert_i32_u (i32.div_u (local.get $this_pixel) (local.get $width)))
                (local.get $ppu)
              )
            )
          )

          ;; Store the current pixel's colour using the value returned from the following if expression
          (i32.store
            ;; Memory offset of current pixel = $image_offset + ($this_pixel * 4)
            (i32.add (local.get $image_offset) (i32.shl (local.get $this_pixel) (i32.const 2)))
            (if (result i32)
              ;; If we're plotting the Mandelbrot Set, can we avoid running the escape-time algorithm?
              (i32.and
                (local.get $is_mandelbrot)
                (call $early_bailout (local.get $cx) (local.get $cy))
              )
              ;; Yup, so we know this pixel will be black
              (then (global.get $BLACK))
              ;; Nope, we can't bail out early
              (else
                (if (result i32)
                  ;; Does the current pixel hit max_iters?
                  (i32.eq
                    (local.get $max_iters)
                    ;; Calculate the current pixel's iteration value and store in $pixel_val
                    (local.tee $pixel_val
                      ;; When plotting the Julia Set, reverse the argument order for call to function $escape_time_mj
                      (call $escape_time_mj
                        (if (result f64 f64 f64 f64 i32)
                          (local.get $is_mandelbrot)
                          (then (local.get $zx) (local.get $zy) (local.get $cx) (local.get $cy) (local.get $max_iters))
                          (else (local.get $cx) (local.get $cy) (local.get $zx) (local.get $zy) (local.get $max_iters))
                        )
                      )
                    )
                  )
                  ;; Yup, so return black
                  (then (global.get $BLACK))
                  ;; Nope, so return whatever colour corresponds to this iteration value
                  (else
                    ;; Push the relevant colour from the palette onto the stack
                    (i32.load (i32.add (global.get $palette_offset) (i32.shl (local.get $pixel_val) (i32.const 2))))
                  )
                )
              )
            )
          )

          br $pixels
        )
      )
    ) ;; end of $pixels loop
  )
)
