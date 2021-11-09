(module
  (import "js" "shared_mem" (memory 30))

  (import "mandel" "gen_mandel_pixel" (func $gen_mandel_pixel (param f64 f64 i32) (result i32)))
  (import "mandel" "escape_time_mj"   (func $escape_time_mj   (param f64 f64 f64 f64 i32) (result i32)))

  (global $mandel_img_offset (import "js" "mandel_img_offset") i32)
  (global $julia_img_offset  (import "js" "julia_img_offset")  i32)
  (global $palette_offset    (import "js" "palette_offset")    i32)

  ;; For now, each pixel's alpha value is hard-coded to fully opaque
  (global $ALPHA i32 (i32.const 255))
  (global $BLACK i32 (i32.const 0xFF000000))

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
    (local $ppu_f64 f64)

    (local $half_width f64)
    (local $half_height f64)

    (local.set $half_width  (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))))
    (local.set $half_height (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))))

    (local.set $x_pos (i32.const 0))
    (local.set $y_pos (i32.const 0))
    (local.set $pixel_offset (global.get $mandel_img_offset))
    (local.set $ppu_f64 (f64.convert_i32_u (local.get $ppu)))

    ;; Intermediate X and Y coords based on static values
    ;; $origin - ($half_dimension / $ppu)
    (local.set $temp_x_coord (f64.sub (local.get $origin_x) (f64.div (local.get $half_width) (local.get $ppu_f64))))
    (local.set $temp_y_coord (f64.sub (local.get $origin_y) (f64.div (local.get $half_height) (local.get $ppu_f64))))

    (loop $rows
      (block $exit_rows
        ;; Have all the rows been plotted?
        (br_if $exit_rows (i32.ge_u (local.get $y_pos) (local.get $height)))

        ;; Translate y position to y coordinate
        (local.set $y_coord
          (f64.add
            (local.get $temp_y_coord)
            (f64.div (f64.convert_i32_u (local.get $y_pos)) (local.get $ppu_f64))
          )
        )

        (loop $cols
          (block $exit_cols
            ;; Have all the columns been plotted?
            (br_if $exit_cols (i32.ge_u (local.get $x_pos) (local.get $width)))

            ;; Translate x position to x coordinate
            (local.set $x_coord
              (f64.add
                (local.get $temp_x_coord)
                (f64.div (f64.convert_i32_u (local.get $x_pos)) (local.get $ppu_f64))
              )
            )

            ;; Calculate the current pixel's iteration value
            (local.set $pixel_val
              (call $gen_mandel_pixel
                (local.get $x_coord)
                (local.get $y_coord)
                (local.get $max_iters)
              )
            )

            ;; (call $write_pixel_colour (local.get $pixel_val) (local.get $pixel_offset) (local.get $max_iters))
            (if (i32.eq (local.get $pixel_val) (local.get $max_iters))
              (then
                ;; Any pixel that hits $max_iters is arbitrarily set to black
                (i32.store (local.get $pixel_offset) (global.get $BLACK))
              )
              (else
                ;; Store the colour fetched from the palette
                (i32.store
                  (local.get $pixel_offset)
                  ;; (call $load_from_palette (local.get $pixel_val))
                  (i32.load
                    (i32.add
                      (global.get $palette_offset)
                      (i32.mul (local.get $pixel_val) (i32.const 4))
                    )
                  )
                )
              )
            )

            ;; Increment column and memory offset counters
            (local.set $x_pos (i32.add (local.get $x_pos) (i32.const 1)))
            (local.set $pixel_offset (i32.add (local.get $pixel_offset) (i32.const 4)))

            br $cols
          )
        )

        ;; Reset column counter and increment row counter
        (local.set $x_pos (i32.const 0))
        (local.set $y_pos (i32.add (local.get $y_pos) (i32.const 1)))

        br $rows
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
    (local $j_ppu f64)         ;; Zoom level of Julia set image

    (local.set $half_width  (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))))
    (local.set $half_height (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))))

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
    (loop $rows
      (block $exit_rows
        ;; Have all the rows been plotted?
        (br_if $exit_rows (i32.ge_u (local.get $y_pos) (local.get $height)))

        ;; Translate Y pixel to Y coordinate
        (local.set $y_coord
          (f64.neg
            (f64.div
              (f64.sub (f64.convert_i32_u (local.get $y_pos)) (local.get $half_height))
              (local.get $j_ppu)
            )
          )
        )

        (loop $cols
          (block $exit_cols
            ;; Have all the columns been plotted?
            (br_if $exit_cols (i32.ge_u (local.get $x_pos) (local.get $width)))

            ;; Translate X pixel to X coordinate
            (local.set $x_coord
              (f64.div
                (f64.sub (f64.convert_i32_u (local.get $x_pos)) (local.get $half_width))
                (local.get $j_ppu)
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

            ;; (call $write_pixel_colour (local.get $pixel_val) (local.get $pixel_offset) (local.get $max_iters))
            (if (i32.eq (local.get $pixel_val) (local.get $max_iters))
              (then
                ;; Any pixel that hits $max_iters is arbitrarily set to black
                (i32.store (local.get $pixel_offset) (global.get $BLACK))
              )
              (else
                ;; Store the colour fetched from the palette
                (i32.store
                  (local.get $pixel_offset)
                  ;; (call $load_from_palette (local.get $pixel_val))
                  (i32.load
                    (i32.add
                      (global.get $palette_offset)
                      (i32.mul (local.get $pixel_val) (i32.const 4))
                    )
                  )
                )
              )
            )

            ;; Increment column and memory offset counters
            (local.set $x_pos (i32.add (local.get $x_pos) (i32.const 1)))
            (local.set $pixel_offset (i32.add (local.get $pixel_offset) (i32.const 4)))

            br $cols
          )
        )

        ;; Reset column counter and increment row counter
        (local.set $x_pos (i32.const 0))
        (local.set $y_pos (i32.add (local.get $y_pos) (i32.const 1)))

        br $rows
      )
    )
  )
)
