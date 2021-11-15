(module
  ;; Colour palette
  (import "js" "shared_mem" (memory 48 48 shared))

  (global $palette_offset (import "js" "palette_offset") i32)

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Translate iteration value to colour
  (func $colour
        (export "colour")
        (param $iter i32)
        (result i32)
    (local $iter4 i32)
    (local $temp_col1 i32)
    (local $temp_col2 i32)

    (local.set $iter4 (i32.shl (local.get $iter) (i32.const 2)))

    (block $Red
      (br_if $Red
        (i32.lt_u (local.tee $temp_col1 (i32.and (local.get $iter4) (i32.const 1023))) (i32.const 256))
      )

      (if (i32.lt_u (local.get $temp_col1) (i32.const 512))
        (then
          (local.set $temp_col1 (i32.sub (i32.const 510) (local.get $temp_col1)))
          (br $Red)
        )
      )

      (local.set $temp_col1 (i32.const 0))
    )

    (local.set $temp_col2 (local.get $temp_col1))

    (block $Green
      (br_if $Green
        (i32.lt_u
          (local.tee $temp_col1 (i32.and (i32.add (local.get $iter4) (i32.const 128)) (i32.const 1023)))
          (i32.const 256)
        )
      )

      (if (i32.lt_u (local.get $temp_col1) (i32.const 512))
        (then
          (local.set $temp_col1 (i32.sub (i32.const 510) (local.get $temp_col1)))
          (br $Green)
        )
      )

      (local.set $temp_col1 (i32.const 0))
    )

    ;; Merge green and red components
    (local.set $temp_col1 (i32.or (i32.shl (local.get $temp_col1) (i32.const 8)) (local.get $temp_col2)))

    (block $Blue
      (br_if $Blue
        (i32.lt_u
          (local.tee $iter (i32.and (i32.add (local.get $iter4) (i32.const 356)) (i32.const 1023)))
          (i32.const 256)
        )
      )

      (if (i32.lt_u (local.get $iter) (i32.const 512))
        (then
          (local.set $iter (i32.sub (i32.const 510) (local.get $iter)))
          (br $Blue)
        )
      )

      (local.set $iter (i32.const 0))
    )

    ;; Merge blue component and fixed opacity into final colour
    (i32.or
      (i32.or
        (i32.shl (local.get $iter) (i32.const 16))
        (local.get $temp_col1)
      )
      (i32.const 0xFF000000)
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Generate simplified colour palette
  (func $gen_palette
        (export "gen_palette")
        (param $max_iters i32)

    (local $idx i32)

    (loop $next_pixel
      (if (i32.gt_u (local.get $max_iters) (local.get $idx))
        (then
          (i32.store
            (i32.add (global.get $palette_offset) (i32.shl (local.get $idx) (i32.const 2)))
            (call $colour (local.get $idx))
          )
          (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
          (br $next_pixel)
        )
      )
    )
  )
)
