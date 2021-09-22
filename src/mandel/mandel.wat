(module
  ;; ---------------------------------------------------------------------------
  ;; Complex functions
  (import "cplx" "add" (func $add (param f64 f64 f64 f64) (result f64 f64)))

  ;; ---------------------------------------------------------------------------
  ;; test we can add two complex numbers together using imported function
  (func $test_add
        (export "test_add")
        (param $z1_real f64)
        (param $z1_cplx f64)
        (param $z2_real f64)
        (param $z2_cplx f64)
        (result f64 f64)
    (call $add (local.get $z1_real) (local.get $z1_cplx)
               (local.get $z2_real) (local.get $z2_cplx)
    )
  )
)
