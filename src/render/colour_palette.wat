(module
  ;; Colour palette
  (import "js" "shared_mem" (memory 30))

  (global $palette_offset (import "js" "palette_offset") i32)

  ;; For now, each pixel's alpha value is hard-coded to fully opaque
  (global $ALPHA i32 (i32.const 255))
  (global $BLACK i32 (i32.const 0xFF000000))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Return $val ramped linearly between $max and $min then mapped either upwards or downwards onto a scale of 0 to 255
  (func $ramp
        (param $min f32)
        (param $val f32)
        (param $max f32)
        (param $dir i32)  ;; 0 = up, 1 = down
        (result i32)
    (local $ratio f32)

    f32.const 1                ;; [1]

    (local.tee $ratio          ;; [1, $ratio]
      (f32.div
        (f32.sub (local.get $val) (local.get $min))
        (f32.sub (local.get $max) (local.get $min))
      )
    )

    f32.sub                    ;; [1 - $ratio]
    local.get $ratio           ;; [1 - $ratio, $ratio]

    ;; Ramping up or down?
    local.get $dir             ;; [1 - $ratio, $ratio, $dir]
    i32.const 1                ;; [1 - $ratio, $ratio, $dir, 1]
    i32.eq                     ;; [1 - $ratio, $ratio, $dir == 1?]

    select                     ;; Pick stack value -2 or -1 based value whether top of stack == 0

    f32.const 255
    f32.mul
    f32.nearest
    i32.trunc_f32_u
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Generate a linear colour palette where the HSL angle maps to the palette index
  ;; The global value $palette_offset indicates where the palette data starts
  (func $hsl_to_rgb
        (export "hsl_to_rgb")
        (param $palette_size i32)
    (local $palette_size_f32 f32)
    (local $pixel_colour i32)
    (local $idx f32)
    (local $bandwidth f32)  ;; Width of a colour band relative to $palette_size

    ;; The colourspace is divided into 6, equal-width bands having the following colour proportions
    (local $band1 f32)      ;; Colour band 1 : Red = 100%,        Green = Scales up,   Blue = 0%
    (local $band2 f32)      ;; Colour band 2 : Red = Scales down, Green = 100%,        Blue = 0%
    (local $band3 f32)      ;; Colour band 3 : Red = 0%,          Green = 100%,        Blue = Scales up
    (local $band4 f32)      ;; Colour band 4 : Red = 0%,          Green = Scales down, Blue = 100%
    (local $band5 f32)      ;; Colour band 5 : Red = Scales up,   Green = 0%,          Blue = 100%
    (local $band6 f32)      ;; Colour band 6 : Red = 100%,        Green = 0%,          Blue = Scales down

    (local $red   i32)
    (local $green i32)
    (local $blue  i32)

    (local.set $palette_size_f32 (f32.convert_i32_u (local.get $palette_size)))
    (local.set $bandwidth (f32.div (local.get $palette_size_f32) (f32.const 6)))

    ;; Set band upper limits
    (local.set $band1 (local.get $bandwidth))
    (local.set $band2 (f32.mul (local.get $bandwidth) (f32.const 2)))
    (local.set $band3 (f32.mul (local.get $bandwidth) (f32.const 3)))
    (local.set $band4 (f32.mul (local.get $bandwidth) (f32.const 4)))
    (local.set $band5 (f32.mul (local.get $bandwidth) (f32.const 5)))
    (local.set $band6 (local.get $palette_size_f32))

    (loop $palette
      (block $exit_loop
        (br_if $exit_loop (f32.ge (local.get $idx) (local.get $palette_size_f32)))

        (block $done
          ;; Within band 1
          (if (f32.le (local.get $idx) (local.get $band1))
            (then
              (local.set $red (i32.const 255))
              (local.set $green (call $ramp (f32.const 0) (local.get $idx) (local.get $band1) (i32.const 0)))
              (local.set $blue (i32.const 0))
              (br $done)
            )
          )

          ;; Within band 2
          (if (f32.le (local.get $idx) (local.get $band2))
            (then
              (local.set $red (call $ramp (local.get $band1) (local.get $idx) (local.get $band2) (i32.const 1)))
              (local.set $green (i32.const 255))
              (local.set $blue (i32.const 0))
              (br $done)
            )
          )

          ;; Within band 3
          (if (f32.le (local.get $idx) (local.get $band3))
            (then
              (local.set $red (i32.const 0))
              (local.set $green (i32.const 255))
              (local.set $blue (call $ramp (local.get $band2) (local.get $idx) (local.get $band3) (i32.const 0)))
              (br $done)
            )
          )

          ;; Within band 4
          (if (f32.le (local.get $idx) (local.get $band4))
            (then
              (local.set $red (i32.const 0))
              (local.set $green (call $ramp (local.get $band3) (local.get $idx) (local.get $band4) (i32.const 1)))
              (local.set $blue (i32.const 255))
              (br $done)
            )
          )

          ;; Within band 5
          (if (f32.le (local.get $idx) (local.get $band5))
            (then
              (local.set $red (call $ramp (local.get $band4) (local.get $idx) (local.get $band5) (i32.const 0)))
              (local.set $green (i32.const 0))
              (local.set $blue (i32.const 255))
              (br $done)
            )
          )

          ;; Within band 6
          (if (f32.le (local.get $idx) (local.get $band6))
            (then
              (local.set $red (i32.const 255))
              (local.set $green (i32.const 0))
              (local.set $blue (call $ramp (local.get $band5) (local.get $idx) (local.get $band6) (i32.const 1)))
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
            (i32.mul (i32.trunc_f32_u (local.get $idx)) (i32.const 4))
          )
          (local.get $pixel_colour)
        )

        (local.set $idx (f32.add (local.get $idx) (f32.const 1)))
        (br $palette)
      )
    )
  )
)
