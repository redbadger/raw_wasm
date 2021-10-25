(module
  ;; Canvas image memory from host environment
  (import "canvas" "img" (memory 22))

  (import "mandel" "gen_pixel_val" (func $gen_pixel_val (param f64 f64 i32) (result i32)))

  ;; For now, each pixel's alpha value is hard-coded to fully opaque
  (global $ALPHA i32 (i32.const 255))
  (global $BLACK i32 (i32.const 0xFF000000))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Translate an X or Y canvas position to the corresponding X or Y coordinate on the complex plane
  (func $pos_to_coord
        (export "pos_to_coord")
        (param $mouse_pos i32)     ;; Mouse X or Y location on canvas
        (param $canvas_dim i32)    ;; Canvas width or height
        (param $origin f32)        ;; Origin along dimension in complex plane coordinate
        (param $ppu i32)           ;; Pixels per unit (zoom level)
        (result f32)
    (f32.add
      (local.get $origin)
      (f32.div
        (f32.sub
          (f32.convert_i32_u (local.get $mouse_pos))
          (f32.div (f32.convert_i32_u (local.get $canvas_dim)) (f32.const 2))
        )
        (f32.convert_i32_u (local.get $ppu))
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val scaled linearly between $max and $min
  (func $linear_scale
        (param $min f32)     ;; Lower bound
        (param $val f32)     ;; Value being scaled
        (param $max f32)     ;; Upper bound
        (result f32)
    (f32.div
      (f32.sub (local.get $val) (local.get $min))
      (f32.sub (local.get $max) (local.get $min))
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val scaled between 0 and 255 according to position between $max and $min
  (func $scale_up
        (param $min f32)     ;; Lower bound
        (param $val f32)     ;; Value being scaled
        (param $max f32)     ;; Upper bound
        (result i32)
    (i32.trunc_f32_u
      (f32.nearest
        (f32.mul
          (call $linear_scale (local.get $min) (local.get $val) (local.get $max))
          (f32.const 255)
        )
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val scaled between 255 and 0 according to position between $max and $min
  (func $scale_down
        (param $min f32)     ;; Value being scaled
        (param $val f32)     ;; Value being scaled
        (param $max f32)     ;; Upper bound
        (result i32)
    (i32.trunc_f32_u
      (f32.nearest
        (f32.mul
          (f32.sub
            (f32.const 1)
            (call $linear_scale (local.get $min) (local.get $val) (local.get $max))
          )
          (f32.const 255)
        )
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Plot the Mandelbrot set
  (func $mandel_plot
        (export "mandel_plot")
        (param $width i32)          ;; Canvas width
        (param $height i32)         ;; Canvas height
        (param $origin_x f32)       ;; X origin location
        (param $origin_y f32)       ;; Y origin location
        (param $ppu i32)            ;; Pixels per unit (zoom level)
        (param $max_iters i32)      ;; Maximum iteration count
    (local $x_pos i32)
    (local $y_pos i32)
    (local $x_coord f32)
    (local $y_coord f32)
    (local $mem_offset i32)
    (local $pixel_val i32)
    (local $pixel_colour i32)

    (local.set $x_pos (i32.const 0))
    (local.set $y_pos (i32.const 0))
    (local.set $mem_offset (i32.const 0))

    (loop $rows
      (block $exit_rows
        ;; Have all the rows been plotted?
        (br_if $exit_rows (i32.ge_u (local.get $y_pos) (local.get $height)))

        ;; Translate y position to y coordinate
        (local.set $y_coord
          (call $pos_to_coord (local.get $y_pos) (local.get $height) (local.get $origin_y) (local.get $ppu))
        )

        (loop $cols
          (block $exit_cols
            ;; Have all the columns been plotted?
            (br_if $exit_cols (i32.ge_u (local.get $x_pos) (local.get $width)))

            ;; Translate x position to x coordinate
            (local.set $x_coord
              (call $pos_to_coord (local.get $x_pos) (local.get $width) (local.get $origin_x) (local.get $ppu))
            )

            ;; Calculate the current pixel's iteration value
            (local.set $pixel_val
              (call $gen_pixel_val
                (f64.promote_f32 (local.get $x_coord))
                (f64.promote_f32 (local.get $y_coord))
                (local.get $max_iters)
              )
            )

            ;; Transform pixel iteration value to RGBA colour
            (if (i32.eq (local.get $pixel_val) (local.get $max_iters))
              (then
                (local.set $pixel_colour (global.get $BLACK))
              )
              (else
                (local.set $pixel_colour
                  (call $value_to_rgb
                    (local.get $pixel_val)       ;; Iteration value
                    (local.get $max_iters)       ;; Range maximum
                  )
                  ;; (call $pixel_colour
                  ;;   (i32.const 1)                ;; Range minimum
                  ;;   (local.get $pixel_val)       ;; Iteration value
                  ;;   (local.get $max_iters)       ;; Range maximum
                  ;; )
                )
              )
            )

            ;; Write pixel colour to shared memory
            (i32.store (local.get $mem_offset) (local.get $pixel_colour))

            ;; Increment column and memory offset counters
            (local.set $x_pos (i32.add (local.get $x_pos) (i32.const 1)))
            (local.set $mem_offset (i32.add (local.get $mem_offset) (i32.const 4)))

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

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Calculate an RGBA pixel colour based on the value's position within the HSL colourspace.
  ;;
  ;; (param $val i32)  Unsigned integer value to be translated into a colour. Must be ≤ $max
  ;; (param $max i32)  Unsigned integer. Upper range limit
  (func $value_to_rgb
        (export "value_to_rgb")
        (param $val i32)  ;; Value to be translated into a colour
        (param $max i32)  ;; Upper limit
        (result i32)
    (local $val_f32 f32)
    (local $max_f32 f32)
    (local $bandwidth f32)  ;; Width of a colour band relative to $max

    (local $band1 f32)      ;; Colour band 1 : Red = 100%,        Green = Scales up,   Blue = 0%
    (local $band2 f32)      ;; Colour band 2 : Red = Scales down, Green = 100%,        Blue = 0%
    (local $band3 f32)      ;; Colour band 3 : Red = 0%,          Green = 100%,        Blue = Scales up
    (local $band4 f32)      ;; Colour band 4 : Red = 0%,          Green = Scales down, Blue = 100%
    (local $band5 f32)      ;; Colour band 5 : Red = Scales up,   Green = 0%,          Blue = 100%
    (local $band6 f32)      ;; Colour band 6 : Red = 100%,        Green = 0%,          Blue = Scales down

    (local $red   i32)
    (local $green i32)
    (local $blue  i32)

    (local.set $val_f32 (f32.convert_i32_u (local.get $val)))
    (local.set $max_f32 (f32.convert_i32_u (local.get $max)))

    ;; The colourspace is divided into 6, equal-width bands
    (local.set $bandwidth (f32.div (local.get $max_f32) (f32.const 6)))

    (local.set $band1 (local.get $bandwidth))
    (local.set $band2 (f32.mul (local.get $bandwidth) (f32.const 2)))
    (local.set $band3 (f32.mul (local.get $bandwidth) (f32.const 3)))
    (local.set $band4 (f32.mul (local.get $bandwidth) (f32.const 4)))
    (local.set $band5 (f32.mul (local.get $bandwidth) (f32.const 5)))
    (local.set $band6 (local.get $max_f32))

    (block $done
      ;; Within band 1
      (if (f32.le (local.get $val_f32) (local.get $band1))
        (then
          (local.set $red (i32.const 255))
          (local.set $green (call $scale_up (f32.const 0) (local.get $val_f32) (local.get $band1)))
          (local.set $blue (i32.const 0))
          (br $done)
        )
      )

      ;; Within band 2
      (if (f32.le (local.get $val_f32) (local.get $band2))
        (then
          (local.set $red (call $scale_down (local.get $band1) (local.get $val_f32) (local.get $band2)))
          (local.set $green (i32.const 255))
          (local.set $blue (i32.const 0))
          (br $done)
        )
      )

      ;; Within band 3
      (if (f32.le (local.get $val_f32) (local.get $band3))
        (then
          (local.set $red (i32.const 0))
          (local.set $green (i32.const 255))
          (local.set $blue (call $scale_up (local.get $band2) (local.get $val_f32) (local.get $band3)))
          (br $done)
        )
      )

      ;; Within band 4
      (if (f32.le (local.get $val_f32) (local.get $band4))
        (then
          (local.set $red (i32.const 0))
          (local.set $green (call $scale_down (local.get $band3) (local.get $val_f32) (local.get $band4)))
          (local.set $blue (i32.const 255))
          (br $done)
        )
      )

      ;; Within band 5
      (if (f32.le (local.get $val_f32) (local.get $band5))
        (then
          (local.set $red (call $scale_up (local.get $band4) (local.get $val_f32) (local.get $band5)))
          (local.set $green (i32.const 0))
          (local.set $blue (i32.const 255))
          (br $done)
        )
      )

      ;; Within band 6
      (if (f32.le (local.get $val_f32) (local.get $band6))
        (then
          (local.set $red (i32.const 255))
          (local.set $green (i32.const 0))
          (local.set $blue (call $scale_down (local.get $band5) (local.get $val_f32) (local.get $band6)))
        )
      )
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
