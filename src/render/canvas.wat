(module
  (import "js" "shared_mem" (memory 26))

  (import "mandel" "gen_pixel_val" (func $gen_pixel_val (param f64 f64 i32) (result i32)))

  (global $img_offset     (import "js" "img_offset") i32)
  (global $palette_offset (import "js" "palette_offset") i32)

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
    (local $pixel_offset i32)
    (local $pixel_val i32)
    (local $pixel_colour i32)

    (local.set $x_pos (i32.const 0))
    (local.set $y_pos (i32.const 0))
    (local.set $pixel_offset (global.get $img_offset))

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
                ;; Any pixel that hits $max_iters is arbitrarily set to black
                (i32.store (local.get $pixel_offset) (global.get $BLACK))
              )
              (else
                ;; Store the colour fetched from the palette
                (i32.store
                  (local.get $pixel_offset)
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
