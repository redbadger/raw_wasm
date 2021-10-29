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
  ;; Translate an X or Y canvas position to the corresponding X or Y coordinate on the complex plane on the assumption
  ;; that the coordinate origin is located at the midpoint of the canvas dimension
  ;; ($mouse_pos, $canvas_dim, $ppu) => ($mouse_pos - ($canvas_dim / 2)) / $ppu
  (func $pxl_to_coord
        (export "pxl_to_coord")
        (param $mouse_pos i32)     ;; Mouse X or Y location on canvas
        (param $canvas_dim i32)    ;; Canvas width or height
        (param $ppu i32)           ;; Pixels per unit (zoom level)
        (result f64)
    (f64.div
      (f64.sub
        (f64.convert_i32_u (local.get $mouse_pos))
        (f64.div (f64.convert_i32_u (local.get $canvas_dim)) (f64.const 2))
      )
      (f64.convert_i32_u (local.get $ppu))
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Translate an X or Y canvas position to the corresponding X or Y coordinate on the complex plane allowing for an
  ;; off-centre origin
  ;; ($mouse_pos, $canvas_dim, $origin, $ppu) => $origin + $pxl_to_coord($mouse_pos, $canvas_dim, $ppu)
  (func $pxl_to_coord_with_offset
        (export "pxl_to_coord_with_offset")
        (param $mouse_pos i32)     ;; Mouse X or Y location on canvas
        (param $canvas_dim i32)    ;; Canvas width or height
        (param $origin f64)        ;; Origin coordinate relative to the dimension midpoint
        (param $ppu i32)           ;; Pixels per unit (zoom level)
        (result f64)
    (f64.add
      (local.get $origin)
      (call $pxl_to_coord (local.get $mouse_pos) (local.get $canvas_dim) (local.get $ppu))
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Load the colour at offset $idx from the colour palette
  (func $load_from_palette
        (param $idx i32)
        (result i32)
    (i32.load
      (i32.add
        (global.get $palette_offset)
        (i32.mul (local.get $idx) (i32.const 4))
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Plot Mandelbrot set
  (func $mandel_plot
        (export "mandel_plot")
        (param $width i32)          ;; Canvas width
        (param $height i32)         ;; Canvas height
        (param $origin_x f32)       ;; X origin location
        (param $origin_y f32)       ;; Y origin location
        (param $j_ppu i32)            ;; Pixels per unit (zoom level)
        (param $max_iters i32)      ;; Maximum iteration count
    (local $x_pos i32)
    (local $y_pos i32)
    (local $x_coord f64)
    (local $y_coord f64)
    (local $origin_x_f64 f64)
    (local $origin_y_f64 f64)
    (local $pixel_offset i32)
    (local $pixel_val i32)
    (local $pixel_colour i32)

    (local.set $x_pos (i32.const 0))
    (local.set $y_pos (i32.const 0))
    (local.set $pixel_offset (global.get $mandel_img_offset))

    (local.set $origin_x_f64 (f64.promote_f32 (local.get $origin_x)))
    (local.set $origin_y_f64 (f64.promote_f32 (local.get $origin_y)))

    (loop $rows
      (block $exit_rows
        ;; Have all the rows been plotted?
        (br_if $exit_rows (i32.ge_u (local.get $y_pos) (local.get $height)))

        ;; Translate y position to y coordinate
        (local.set $y_coord
          (call $pxl_to_coord_with_offset (local.get $y_pos) (local.get $height) (local.get $origin_y_f64) (local.get $j_ppu))
        )

        (loop $cols
          (block $exit_cols
            ;; Have all the columns been plotted?
            (br_if $exit_cols (i32.ge_u (local.get $x_pos) (local.get $width)))

            ;; Translate x position to x coordinate
            (local.set $x_coord
              (call $pxl_to_coord_with_offset (local.get $x_pos) (local.get $width) (local.get $origin_x_f64) (local.get $j_ppu))
            )

            ;; Calculate the current pixel's iteration value
            (local.set $pixel_val
              (call $gen_mandel_pixel
                (local.get $x_coord)
                (local.get $y_coord)
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
                (i32.store (local.get $pixel_offset) (call $load_from_palette (local.get $pixel_val)))
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
        (param $origin_x f32)  ;; X origin coordinate
        (param $origin_y f32)  ;; Y origin coordinate
        (param $mandel_x i32)  ;; X mouse position in Mandelbrot Set
        (param $mandel_y i32)  ;; Y mouse position in Mandelbrot Set
        (param $m_ppu i32)     ;; Zoom level of Mandelbrot set image (pixels per unit)
        (param $max_iters i32)
    (local $x_pos i32)         ;; Iteration counter
    (local $y_pos i32)         ;; Iteration counter
    (local $x_coord f64)       ;; Iteration coordinate
    (local $y_coord f64)       ;; Iteration coordinate
    (local $mandel_x_f64 f64)
    (local $mandel_y_f64 f64)
    (local $pixel_offset i32)  ;; Memory offset of calculated pixel
    (local $pixel_val i32)     ;; Iteration value of calculated pixel
    (local $pixel_colour i32)  ;; Calculated pixel colour
    (local $j_ppu i32)         ;; Zoom level of Julia set image

    ;; Julia sets have a fixed zoom level
    (local.set $j_ppu (i32.const 200))

    ;; Point to the start of the Julia set memory space
    (local.set $pixel_offset (global.get $julia_img_offset))

    ;; Convert mouse position over Mandelbrot set to Julia set coordinates
    (local.set $mandel_x_f64
      (call $pxl_to_coord_with_offset
        (local.get $mandel_x)
        (local.get $width)
        (f64.promote_f32 (local.get $origin_x))
        (local.get $m_ppu)
      )
    )
    (local.set $mandel_y_f64
      ;; Flip the sign because positive Y axis goes downwards
      (f64.neg
        (call $pxl_to_coord_with_offset
          (local.get $mandel_y)
          (local.get $height)
          (f64.promote_f32 (local.get $origin_y))
          (local.get $m_ppu)
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
          (f64.neg (call $pxl_to_coord (local.get $y_pos) (local.get $height) (local.get $j_ppu)))
        )

        (loop $cols
          (block $exit_cols
            ;; Have all the columns been plotted?
            (br_if $exit_cols (i32.ge_u (local.get $x_pos) (local.get $width)))

            ;; Translate X pixel to X coordinate
            (local.set $x_coord
              (call $pxl_to_coord (local.get $x_pos) (local.get $width) (local.get $j_ppu))
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

            ;; Transform pixel iteration value to RGBA colour
            (if (i32.eq (local.get $pixel_val) (local.get $max_iters))
              (then
                ;; Any pixel that hits $max_iters is arbitrarily set to black
                (i32.store (local.get $pixel_offset) (global.get $BLACK))
              )
              (else
                ;; Look up pixel's palette colour
                (i32.store (local.get $pixel_offset) (call $load_from_palette (local.get $pixel_val)))
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
