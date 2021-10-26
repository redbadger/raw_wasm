(module
  ;; Colour palette
  (import "js" "shared_mem" (memory 26))

  (global $palette_offset (import "js" "palette_offset") i32)

  ;; For now, each pixel's alpha value is hard-coded to fully opaque
  (global $ALPHA i32 (i32.const 255))
  (global $BLACK i32 (i32.const 0xFF000000))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val ramped linearly between $max and $min
  (func $linear_ramp
        (param $min i32)
        (param $val i32)
        (param $max i32)
        (result f32)
    (f32.div
      (f32.convert_i32_u (i32.sub (local.get $val) (local.get $min)))
      (f32.convert_i32_u (i32.sub (local.get $max) (local.get $min)))
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val ramped linearly between $min and $max then mapped onto a scale of 0 to 255
  (func $ramp_up
        (param $min i32)
        (param $val i32)
        (param $max i32)
        (result i32)
    (i32.trunc_f32_u
      (f32.nearest
        (f32.mul
          (call $linear_ramp (local.get $min) (local.get $val) (local.get $max))
          (f32.const 255)
        )
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val ramped linearly between $max and $min then mapped onto a scale of 255 to 0
  (func $ramp_down
        (param $min i32)
        (param $val i32)
        (param $max i32)
        (result i32)
    (i32.trunc_f32_u
      (f32.nearest
        (f32.mul
          (f32.sub
            (f32.const 1)
            (call $linear_ramp (local.get $min) (local.get $val) (local.get $max))
          )
          (f32.const 255)
        )
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Generate a linear colour palette where the HSL angle maps to the palette index
  ;; The palette data is written to memory with offset 0 holding the palette size and all subsequent entries are i32's
  ;; in little-endian format: ABGR
  (func $hsl_to_rgb
        (export "hsl_to_rgb")
        (param $palette_size i32)
    (local $palette_size_f32 f32)
    (local $pixel_colour i32)
    (local $idx i32)
    (local $bandwidth f32)  ;; Width of a colour band relative to $palette_size

    ;; The colourspace is divided into 6, equal-width bands having the following colour proportions
    (local $band1 i32)      ;; Colour band 1 : Red = 100%,        Green = Scales up,   Blue = 0%
    (local $band2 i32)      ;; Colour band 2 : Red = Scales down, Green = 100%,        Blue = 0%
    (local $band3 i32)      ;; Colour band 3 : Red = 0%,          Green = 100%,        Blue = Scales up
    (local $band4 i32)      ;; Colour band 4 : Red = 0%,          Green = Scales down, Blue = 100%
    (local $band5 i32)      ;; Colour band 5 : Red = Scales up,   Green = 0%,          Blue = 100%
    (local $band6 i32)      ;; Colour band 6 : Red = 100%,        Green = 0%,          Blue = Scales down

    (local $red   i32)
    (local $green i32)
    (local $blue  i32)

    (local.set $palette_size_f32 (f32.convert_i32_u (local.get $palette_size)))
    (local.set $bandwidth (f32.div (local.get $palette_size_f32) (f32.const 6)))

    ;; Set band upper limits
    (local.set $band1 (i32.trunc_f32_u (f32.nearest (local.get $bandwidth))))
    (local.set $band2 (i32.trunc_f32_u (f32.nearest (f32.mul (local.get $bandwidth) (f32.const 2)))))
    (local.set $band3 (i32.trunc_f32_u (f32.nearest (f32.mul (local.get $bandwidth) (f32.const 3)))))
    (local.set $band4 (i32.trunc_f32_u (f32.nearest (f32.mul (local.get $bandwidth) (f32.const 4)))))
    (local.set $band5 (i32.trunc_f32_u (f32.nearest (f32.mul (local.get $bandwidth) (f32.const 5)))))
    (local.set $band6 (i32.trunc_f32_u (f32.nearest (local.get $palette_size_f32))))

    ;; Store palette size
    (i32.store (i32.const 0) (local.get $palette_size))

    (loop $palette
      (block $exit_loop
        (br_if $exit_loop (i32.ge_u (local.get $idx) (local.get $palette_size)))

        (block $done
          ;; Within band 1
          (if (i32.le_u (local.get $idx) (local.get $band1))
            (then
              (local.set $red (i32.const 255))
              (local.set $green (call $ramp_up (i32.const 0) (local.get $idx) (local.get $band1)))
              (local.set $blue (i32.const 0))
              (br $done)
            )
          )

          ;; Within band 2
          (if (i32.le_u (local.get $idx) (local.get $band2))
            (then
              (local.set $red (call $ramp_down (local.get $band1) (local.get $idx) (local.get $band2)))
              (local.set $green (i32.const 255))
              (local.set $blue (i32.const 0))
              (br $done)
            )
          )

          ;; Within band 3
          (if (i32.le_u (local.get $idx) (local.get $band3))
            (then
              (local.set $red (i32.const 0))
              (local.set $green (i32.const 255))
              (local.set $blue (call $ramp_up (local.get $band2) (local.get $idx) (local.get $band3)))
              (br $done)
            )
          )

          ;; Within band 4
          (if (i32.le_u (local.get $idx) (local.get $band4))
            (then
              (local.set $red (i32.const 0))
              (local.set $green (call $ramp_down (local.get $band3) (local.get $idx) (local.get $band4)))
              (local.set $blue (i32.const 255))
              (br $done)
            )
          )

          ;; Within band 5
          (if (i32.le_u (local.get $idx) (local.get $band5))
            (then
              (local.set $red (call $ramp_up (local.get $band4) (local.get $idx) (local.get $band5)))
              (local.set $green (i32.const 0))
              (local.set $blue (i32.const 255))
              (br $done)
            )
          )

          ;; Within band 6
          (if (i32.le_u (local.get $idx) (local.get $band6))
            (then
              (local.set $red (i32.const 255))
              (local.set $green (i32.const 0))
              (local.set $blue (call $ramp_down (local.get $band5) (local.get $idx) (local.get $band6)))
            )
          )
        )

        ;; Combine RGBA component values into a single i32 in little-endian order
        (local.set $pixel_colour
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

        ;; Store colour palette value
        (i32.store
          (i32.add
            (global.get $palette_offset)
            (i32.mul (local.get $idx) (i32.const 4))
          )
          (local.get $pixel_colour)
        )

        (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
        (br $palette)
      )
    )
  )
)
