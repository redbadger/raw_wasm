(module
  (import "js" "shared_mem" (memory 48 48 shared))
  (import "js" "log3" (func $log3 (param i32 i32 i32 i32)))

  (global $mandel_img_offset (import "js" "mandel_img_offset") i32)
  (global $julia_img_offset  (import "js" "julia_img_offset")  i32)
  (global $palette_offset    (import "js" "palette_offset")    i32)

  (global $BAILOUT f64 (f64.const 4.0))

  ;; For now, each pixel's alpha value is hard-coded to fully opaque
  (global $ALPHA i32 (i32.const 255))
  (global $BLACK i32 (i32.const 0xFF000000))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Escape time algorithm for calculating either the Mandelbrot or Julia sets
  (func $escape_time_mj
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
        (param $x f64)
        (param $y f64)
        (param $max_iters i32)
        (result i32)

    (local $x_plus_1    f64)
    (local $x_minus_qtr f64)
    (local $y_sqrd      f64)
    (local $q           f64)
    (local $temp        f64)

    (local.set $x_plus_1    (f64.add (local.get $x) (f64.const 1.0)))
    (local.set $x_minus_qtr (f64.sub (local.get $x) (f64.const 0.25)))
    (local.set $y_sqrd      (f64.mul (local.get $y) (local.get $y)))

    ;; Intermediate value $q = ($x - 0.25)^2 + $y^2
    (local.set $q (f64.add (f64.mul (local.get $x_minus_qtr) (local.get $x_minus_qtr)) (local.get $y_sqrd)))

    ;; Can we avoid running the escape time calculation?
    (i32.or
      ;; Is point in main cardioid?
      ;; $q * ($q + ($x - 0.25)) <= $y^2 / 4
      (f64.le
        (f64.mul (local.get $q) (f64.add (local.get $q) (local.get $x_minus_qtr)))
        (f64.mul (f64.const 0.25) (local.get $y_sqrd))
      )
      ;; Is point in period-2 bulb?
      ;; ($x + 1)^2 + $y^2 <= 0.0625
      (f64.le
        (f64.add
          (f64.mul (local.get $x_plus_1) (local.get $x_plus_1))
          (f64.mul (local.get $y) (local.get $y))
        )
        (f64.const 0.0625)
      )
    )

    i32.eqz

    if (result i32)
      (call $escape_time_mj (local.get $x) (local.get $y) (f64.const 0) (f64.const 0) (local.get $max_iters))
    else
      (local.get $max_iters)
    end
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Plot Mandelbrot set
  (func $mandel_plot
        (export "mandel_plot")
        (param $width i32)          ;; Canvas width
        (param $height i32)         ;; Canvas height
        (param $origin_x f64)       ;; X origin location
        (param $origin_y f64)       ;; Y origin location
        (param $ppu i32)            ;; Pixels per unit (zoom level)
        (param $max_iters i32)      ;; Maximum iteration count
    (local $x_pos i32)
    (local $y_pos i32)
    (local $x_coord f64)
    (local $y_coord f64)
    (local $temp_x_coord f64)
    (local $temp_y_coord f64)
    (local $pixel_offset i32)
    (local $pixel_val i32)
    (local $pixel_colour i32)
    (local $pixel_count i32)
    (local $this_pixel i32)
    (local $ppu_f64 f64)

    (local $half_width f64)
    (local $half_height f64)

    (local.set $pixel_count (i32.mul (local.get $width) (local.get $height)))
    (local.set $half_width  (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))))
    (local.set $half_height (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))))

    (local.set $pixel_offset (global.get $mandel_img_offset))
    (local.set $ppu_f64 (f64.convert_i32_u (local.get $ppu)))

    ;; Intermediate X and Y coords based on static values
    ;; $origin - ($half_dimension / $ppu)
    (local.set $temp_x_coord (f64.sub (local.get $origin_x) (f64.div (local.get $half_width) (local.get $ppu_f64))))
    (local.set $temp_y_coord (f64.sub (local.get $origin_y) (f64.div (local.get $half_height) (local.get $ppu_f64))))

    (loop $pixels
      (block $exit_pixels
        ;; Read current Mandelbrot pixel then increment and write it atomically
        (local.set $this_pixel (i32.atomic.rmw.add (i32.const 0) (i32.const 1)))

        ;; Have all the pixels been plotted?
        (br_if $exit_pixels (i32.ge_u (local.get $this_pixel) (local.get $pixel_count)))

        ;; Derive $x_pos and $y_pos from $this_pixel
        (local.set $x_pos (i32.rem_u (local.get $this_pixel) (local.get $width)))
        (local.set $y_pos (i32.div_u (local.get $this_pixel) (local.get $width)))

        ;; Translate X and Y positions to X and Y coordinates
        (local.set $x_coord
          (f64.add (local.get $temp_x_coord) (f64.div (f64.convert_i32_u (local.get $x_pos)) (local.get $ppu_f64)))
        )
        (local.set $y_coord
          ;; (f64.neg
            (f64.add (local.get $temp_y_coord) (f64.div (f64.convert_i32_u (local.get $y_pos)) (local.get $ppu_f64)))
          ;; )
        )

        ;; Memory offset of current pixel $pixel_offset = $mandel_img_offset + ($this_pixel * 4)
        (local.set $pixel_offset
          (i32.add (global.get $mandel_img_offset) (i32.shl (local.get $this_pixel) (i32.const 2)))
        )

        ;; Calculate the current pixel's iteration value
        (local.set $pixel_val
          (call $gen_mandel_pixel (local.get $x_coord) (local.get $y_coord) (local.get $max_iters))
        )

        ;; (call $log3 (i32.const 0) (local.get $x_pos) (local.get $y_pos) (local.get $pixel_val))

        ;; Write pixel colour
        (i32.store
          (local.get $pixel_offset)
          (if (result i32)
              (i32.ge_u (local.get $pixel_val) (local.get $max_iters))
            (then
              ;; Any pixel that hits $max_iters is arbitrarily set to black
              (global.get $BLACK)
            )
            (else
              ;; Fetch colour from palette
              (i32.load (i32.add (global.get $palette_offset) (i32.shl (local.get $pixel_val) (i32.const 2))))
            )
          )
        )

        br $pixels
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Plot Julia set
  (func $julia_plot
        (export "julia_plot")
        (param $width i32)
        (param $height i32)
        (param $origin_x f64)  ;; X origin coordinate
        (param $origin_y f64)  ;; Y origin coordinate
        (param $mandel_x i32)  ;; X mouse position in Mandelbrot Set
        (param $mandel_y i32)  ;; Y mouse position in Mandelbrot Set
        (param $ppu i32)       ;; Zoom level of Mandelbrot set image (pixels per unit)
        (param $max_iters i32)
    (local $x_pos i32)         ;; Iteration counter
    (local $y_pos i32)         ;; Iteration counter
    (local $x_coord f64)       ;; Iteration coordinate
    (local $y_coord f64)       ;; Iteration coordinate
    (local $half_width f64)
    (local $half_height f64)
    (local $mandel_x_f64 f64)
    (local $mandel_y_f64 f64)
    (local $pixel_offset i32)  ;; Memory offset of calculated pixel
    (local $pixel_val i32)     ;; Iteration value of calculated pixel
    (local $pixel_colour i32)  ;; Calculated pixel colour
    (local $pixel_count i32)
    (local $this_pixel i32)
    (local $row_offset i32)
    (local $j_ppu f64)         ;; Zoom level of Julia set image

    (local.set $half_width  (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))))
    (local.set $half_height (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))))
    (local.set $pixel_count (i32.mul (local.get $width) (local.get $height)))

    ;; Julia set images always have a fixed zoom level of 200 pixels per unit
    (local.set $j_ppu (f64.const 200))

    ;; Point to the start of the Julia set memory space
    (local.set $pixel_offset (global.get $julia_img_offset))

    ;; Convert mouse position over Mandelbrot set to complex plane coordinates
    (local.set $mandel_x_f64
      (f64.add
        (local.get $origin_x)
        (f64.div
          (f64.sub
            (f64.convert_i32_u (local.get $mandel_x))
            (f64.div (f64.convert_i32_u (local.get $width)) (f64.const 2))
          )
          (f64.convert_i32_u (local.get $ppu))
        )
      )
    )
    (local.set $mandel_y_f64
      ;; Flip the sign because positive Y axis goes downwards
      (f64.neg
        (f64.add
          (local.get $origin_y)
          (f64.div
            (f64.sub
              (f64.convert_i32_u (local.get $mandel_y))
              (f64.div (f64.convert_i32_u (local.get $height)) (f64.const 2))
            )
            (f64.convert_i32_u (local.get $ppu))
          )
        )
      )
    )

    ;; Iterate all pixels in the Julia set
    (loop $pixels
      (block $exit_pixels
        ;; Read current Julia Set pixel then increment and write it atomically
        (local.set $this_pixel (i32.atomic.rmw.add (i32.const 4) (i32.const 1)))

        ;; Have all the pixels been plotted?
        (br_if $exit_pixels (i32.ge_u (local.get $this_pixel) (local.get $pixel_count)))

        ;; Derive $x_pos and $y_pos from $this_pixel
        (local.set $x_pos (i32.rem_u (local.get $this_pixel) (local.get $width)))
        (local.set $y_pos (i32.div_u (local.get $this_pixel) (local.get $width)))

        ;; Translate X and Y pixels to X and Y coordinates
        (local.set $x_coord
          (f64.div
            (f64.sub (f64.convert_i32_u (local.get $x_pos)) (local.get $half_width))
            (local.get $j_ppu)
          )
        )
        (local.set $y_coord
          (f64.neg
            (f64.div
              (f64.sub (f64.convert_i32_u (local.get $y_pos)) (local.get $half_height))
              (local.get $j_ppu)
            )
          )
        )

        ;; Calculate the current pixel's iteration value
        (local.set $pixel_val
          (call $escape_time_mj
            (local.get $mandel_x_f64)
            (local.get $mandel_y_f64)
            (local.get $x_coord)
            (local.get $y_coord)
            (local.get $max_iters)
          )
        )

        ;; (call $log3 (i32.const 1) (local.get $x_pos) (local.get $y_pos) (local.get $pixel_val))

        ;; Memory offset of current row = $julia_img_offset + ($this_pixel + $width * 4)
        (local.set $pixel_offset
          (i32.add
            (global.get $julia_img_offset)
            (i32.shl (local.get $this_pixel) (i32.const 2))
          )
        )

        ;; Write pixel colour
        (i32.atomic.store
          (local.get $pixel_offset)
          (if (result i32)
              (i32.ge_u (local.get $pixel_val) (local.get $max_iters))
            (then
              ;; Any pixel that hits $max_iters is arbitrarily set to black
              (global.get $BLACK)
            )
            (else
              ;; Fetch colour from palette
              (i32.load (i32.add (global.get $palette_offset) (i32.shl (local.get $pixel_val) (i32.const 2))))
            )
          )
        )

        br $pixels
      )
    )
  )
)
