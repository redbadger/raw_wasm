(module
  ;; Canvas image memory from host environment
  (import "canvas" "img" (memory 22))

  (import "mandel" "gen_pixel_val" (func $gen_pixel_val (param f64 f64) (result i32)))

  ;; Width and height of the canvas
  (global $CANVAS_WIDTH    (import "canvas" "width") i32)
  (global $CANVAS_HEIGHT   (import "canvas" "height") i32)
  (global $PIXELS_PER_UNIT (import "canvas" "ppu") i32)

  ;; The location of the centre pixel of the canvas in the complex plane
  (global $MANDEL_ORIGIN_X (import "canvas" "centre_x") f32)
  (global $MANDEL_ORIGIN_Y (import "canvas" "centre_y") f32)

  (global $MAX_ITERS (import "plot" "max_iters") i32)

  ;; For now, each pixel's alpha value is hard-coded to fully opaque
  (global $ALPHA i32 (i32.const 255))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Translate an x or y mouse position over the canvas to the corresponding x or y coordinate on the complex plane
  (func $pos_to_coord
        (param $mouse_pos i32)
        (param $canvas_dim i32)
        (param $origin f32)
        (result f32)
    (f32.add
      (local.get $origin)
      (f32.div
        (f32.sub
          (f32.convert_i32_u (local.get $mouse_pos))
          (f32.div (f32.convert_i32_u (local.get $canvas_dim)) (f32.const 2))
        )
        (f32.convert_i32_u (global.get $PIXELS_PER_UNIT))
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Plot the Mandelbrot set
  (func $mandel_plot
        (export "mandel_plot")
        (param $width i32)
        (param $height i32)
        (param $origin_x f32)
        (param $origin_y f32)
    (local $x_pos i32)
    (local $y_pos i32)
    (local $x_coord f32)
    (local $y_coord f32)
    (local $mem_offset i32)
    (local $pixel_val i32)

    (local.set $x_pos (i32.const 0))
    (local.set $y_pos (i32.const 0))
    (local.set $mem_offset (i32.const 0))

    (loop $rows
      (block $exit_rows
        ;; Have all the rows been plotted?
        (br_if $exit_rows (i32.ge_u (local.get $y_pos) (local.get $height)))

        ;; Translate y position to y coordinate
        (local.set $y_coord (call $pos_to_coord (local.get $y_pos) (global.get $CANVAS_HEIGHT) (local.get $origin_y)))

        (loop $cols
          (block $exit_cols
            ;; Have all the columns been plotted?
            (br_if $exit_cols (i32.ge_u (local.get $x_pos) (local.get $width)))

            ;; Translate x position to x coordinate
            (local.set $x_coord (call $pos_to_coord (local.get $x_pos) (global.get $CANVAS_WIDTH) (local.get $origin_x)))

            ;; Calculate the current pixel's iteration value
            (local.set $pixel_val
              (call $gen_pixel_val (f64.promote_f32 (local.get $x_coord)) (f64.promote_f32 (local.get $y_coord)))
            )

            ;; Transform pixel iteration value to RGBA colour and write it to shared memory
            (i32.store
              (local.get $mem_offset)
              (call $pixel_colour
                (i32.const 1)                ;; Range minimum
                (local.get $pixel_val)       ;; Iteration value
                (global.get $MAX_ITERS)      ;; Range maximum
              )
            )

            ;; Increment column and memory offset counters
            (local.set $x_pos (i32.add (local.get $x_pos) (i32.const 1)))
            (local.set $mem_offset (i32.add (local.get $mem_offset) (i32.const 1)))

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
  ;; Calculate an RGBA pixel colour based on the value's position within the supplied range.
  ;; The colour will be mapped as a linear gradient from blue, through green to red
  (func $pixel_colour
        (export "pixel_colour")
        (param $min i32)  ;; Lower range limit
        (param $val i32)  ;; Value to be translated into a colour
        (param $max i32)  ;; Upper range limit
        (result i32)
    (local $ratio f32)
    (local $red   i32)
    (local $green i32)
    (local $blue  i32)

    ;; $ratio = 2 * (($val - $min) / ($max - $min))
    (local.set $ratio
      (f32.mul
        (f32.const 2)
        (f32.div
          (f32.convert_i32_u (i32.sub (local.get $val) (local.get $min)))
          (f32.convert_i32_u (i32.sub (local.get $max) (local.get $min)))
        )
      )
    )

    ;; $blue = int(max(0, 255 * (1 - ratio)))
    (local.set $blue
      (i32.trunc_f32_u
        (f32.max
          (f32.const 0)
          (f32.mul (f32.const 255) (f32.sub (f32.const 1) (local.get $ratio)))
        )
      )
    )

    ;; $red = int(max(0, 255 * (ratio - 1)))
    (local.set $red
      (i32.trunc_f32_u
        (f32.max
          (f32.const 0)
          (f32.mul (f32.const 255) (f32.sub (local.get $ratio) (f32.const 1)))
        )
      )
    )

    ;; $green = 255 - $blue - $red
    (local.set $green
      (i32.sub (i32.const 255) (i32.sub (local.get $blue) (local.get $red)))
    )

    ;; Combine RGBA component values in little-endian order into a single i32
    (i32.or
      (i32.or
        (i32.shl (global.get $ALPHA) (i32.const 24))
        (i32.shl (local.get $blue)   (i32.const 16))
      )
      (i32.or
        (i32.shl (local.get $green) (i32.const 8))
        (local.get $red)
      )
    )
  )
)
