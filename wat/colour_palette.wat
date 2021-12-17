(module
  (import "js" "shared_mem" (memory 46 46 shared))
  (global $palette_offset (import "js" "palette_offset") i32)

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Derive a colour component from supplied iteration and threshold values
  (func $8_bit_clamp
        (param $n i32)
        (param $threshold i32)
        (result i32)
    (local $temp i32)

    ;; Add colour-specific threshold, then mask out all but the junior 10 bits
    ;; $temp = ($n + $threshold) & 1023
    (local.set $temp (i32.and (i32.add (local.get $n) (local.get $threshold)) (i32.const 1023)))

    ;; How many bits does $temp use?
    (if (result i32)
      ;; At least 9 bits
      (i32.ge_u (local.get $temp) (i32.const 256))
      (then
        ;; If bit 10 is switched off invert value, else return zero
        (if (result i32)
          (i32.lt_u (local.get $temp) (i32.const 512))
          (then (i32.sub (i32.const 510) (local.get $temp)))
          (else (i32.const 0))
        )
      )
      (else (local.get $temp))
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Generate colour components
  (func $red   (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 0)))
  (func $green (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 128)))
  (func $blue  (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 356)))

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Transform an iteration value to an ABGR colour
  (func $colour
        (param $iter i32)
        (result i32)
    (local $iter4 i32)

    ;; Little-endian processor requires the colour component values in ABGR order, not RGBA
    (i32.or
      (i32.or
        (i32.const 0xFF000000)   ;; Fully opaque
        (i32.shl (call $blue (local.tee $iter4 (i32.shl (local.get $iter) (i32.const 2)))) (i32.const 16))
      )
      (i32.or
        (i32.shl (call $green (local.get $iter4)) (i32.const 8))
        (call $red (local.get $iter4))
      )
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Generate entire colour palette
  (func (export "gen_palette")
        (param $max_iters i32)

    (local $idx i32)

    (loop $next
      (if (i32.gt_u (local.get $max_iters) (local.get $idx))
        (then
          (i32.store
            (i32.add (global.get $palette_offset) (i32.shl (local.get $idx) (i32.const 2)))
            (call $colour (local.get $idx))
          )
          (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
          (br $next)
        )
      )
    )
  )
)
