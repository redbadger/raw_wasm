(module
  ;; Sufficient memory must be allocated for a 800 * 450 pixel canvas where each pixel in an i32
  ;; This amounts to 22 pages
  (memory (export "canvas_image") 22)

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Combine RGBA component values into a singe i32
  (func $combine_components
        (param $red   i32)
        (param $green i32)
        (param $blue  i32)
        (param $alpha i32)
        (result i32)
    (i32.or
      (i32.or
        (i32.shl (local.get $alpha) (i32.const 24))
        (i32.shl (local.get $blue)  (i32.const 16))
      )
      (i32.or
        (i32.shl (local.get $green) (i32.const 8))
        (local.get $red)
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Calculate an RGBA pixel colour based on its position within the supplied range.
  ;; The colour will be mapped as a linear gradient from blue, through green to red
  (func $pixel_colour
        (export "pixel_colour")
        (param $max   i32)    ;; Upper range limit
        (param $min   i32)    ;; Lower range limit
        (param $val   i32)    ;; Value to be translated into a colour
        (param $alpha i32)    ;; Alpha value
        (result i32)
    (local $ratio f32)
    (local $red   i32)
    (local $green i32)
    (local $blue  i32)

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
          (f32.mul
            (f32.const 255)
            (f32.sub (f32.const 1) (local.get $ratio))
          )
        )
      )
    )

    ;; $red = int(max(0, 255 * (ratio - 1)))
    (local.set $red
      (i32.trunc_f32_u
        (f32.max
          (f32.const 0)
          (f32.mul
            (f32.const 255)
            (f32.sub (local.get $ratio) (f32.const 1))
          )
        )
      )
    )

    ;; $green = 255 - $blue - $red
    (local.set $green
      (i32.sub
        (i32.const 255)
        (i32.sub
          (local.get $blue)
          (local.get $red)
        )
      )
    )

    (call $combine_components (local.get $red) (local.get $green) (local.get $blue) (local.get $alpha))
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Calculate a colour component value
  ;; Result = i32 ranging from 0 to 255
  ;;        = trunc(($val / $scale) * 255)
  (func $colour_component
        (export "colour_component")
        (param $val i32)
        (param $scale i32)
        (result i32)
    ;; Truncate f32 and return as an i32
    (i32.trunc_f32_u
      ;; Multiply by 255
      (f32.mul
        ;; Calculate $val / $scale
        (f32.div (f32.convert_i32_u (local.get $val))
                 (f32.convert_i32_u (local.get $scale)))
        (f32.const 255)
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Write the RGBA colour component values as a pixel in little-endian order at location $offset
  (func $write_pixel
        (export "write_pixel")
        (param $offset i32)  ;; Pixel offset in memory
        (param $red    i32)
        (param $green  i32)
        (param $blue   i32)
        (param $alpha  i32)
        (result i32)         ;; Updated memory offset
    ;; Store the combined RGBA values at $offset
    (i32.store
      (local.get $offset)
      (call $combine_components (local.get $red) (local.get $green) (local.get $blue) (local.get $alpha))
    )

    ;; Add 4 to offset and leave on stack as the return value
    (local.tee $offset (i32.add (local.get $offset) (i32.const 4)))
  )

)
