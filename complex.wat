(module
  ;; ---------------------------------------------------------------------------
  ;; Trig and log functions must be imported from the host environment
  (import "math" "sin"   (func $host_sin   (param f64) (result f64)))
  (import "math" "cos"   (func $host_cos   (param f64) (result f64)))
  (import "math" "sinh"  (func $host_sinh  (param f64) (result f64)))
  (import "math" "cosh"  (func $host_cosh  (param f64) (result f64)))
  (import "math" "ln"    (func $host_ln    (param f64) (result f64)))
  (import "math" "atan2" (func $host_atan2 (param f64)
                                           (param f64) (result f64)))

  (global $PI       f64 (f64.const  3.141592653589793))
  (global $MINUS_PI f64 (f64.const -3.141592653589793))

  ;; ---------------------------------------------------------------------------
  ;; Return real part
  ;; real(a+bi) => a
  (func $real
        (export "real")
        (param $a f64)
        (param $b f64)
        (result f64)
    local.get $a
  )

  ;; ---------------------------------------------------------------------------
  ;; Return imaginary part
  ;; imag(a+bi) => b
  (func $imag
        (export "imag")
        (param $a f64)
        (param $b f64)
        (result f64)
    local.get $b
  )

  ;; ---------------------------------------------------------------------------
  ;; Multiply two imaginary numbers
  ;; imag_mul(i1, i2) => -(i1 * i2)
  (func $imag_mul
        (param $b1 f64)
        (param $b2 f64)
        (result f64)
    (f64.mul
      (f64.mul (local.get $b1) (local.get $b2))
      (f64.const -1)
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Conjugate of a complex number
  ;; conj(a+bi) => (a-bi)
  (func $conj
        (export "conj")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (local.get $a)
    (f64.mul (local.get $b) (f64.const -1))
  )

  ;; ---------------------------------------------------------------------------
  ;; Square of the normal (the result is always real)
  ;; norm_sqr(a+bi) => a^2 + b^2
  (func $norm_sqr
        (export "norm_sqr")
        (param $a f64)
        (param $b f64)
        (result f64)
    (f64.add
      (f64.mul (local.get $a) (local.get $a))
      (f64.mul (local.get $b) (local.get $b))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Inverse
  ;; inv(a+bi) => (a/norm_sqr(a+bi), -b/norm_sqr(a+bi))
  (func $inv
        (export "inv")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (local $nsqr f64)

    (local.set $nsqr (call $norm_sqr (local.get $a) (local.get $b)))
    (f64.div (local.get $a) (local.get $nsqr))
    (f64.div (local.get $b) (f64.mul (local.get $nsqr) (f64.const -1)))
  )

  ;; ---------------------------------------------------------------------------
  ;; Multiply a complex number by its own conjugate - synonym for norm_sqr
  ;; conj(a+bi) => norm_sqr(a+bi)
  ;;            => a^2 + b^2
  (func $mul_by_conj
        (export "mul_by_conj")
        (param $a f64)
        (param $b f64)
        (result f64)
    (call $norm_sqr (local.get $a) (local.get $b))
  )

  ;; ---------------------------------------------------------------------------
  ;; Taxicab distance from the origin (the result is always real)
  ;; taxi(a+bi) => |a| + |b|
  (func $taxi
        (export "taxi")
        (param $a f64)
        (param $b f64)
        (result f64)
    (f64.add (f64.abs (local.get $a))
             (f64.abs (local.get $b))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Straight line distance from the origin
  ;; hypot(a+bi) => sqrt(a^2 + b^2)
  (func $hypot
        (export "hypot")
        (param $a f64)
        (param $b f64)
        (result f64)
    (f64.sqrt (call $norm_sqr (local.get $a) (local.get $b)))
  )

  ;; ---------------------------------------------------------------------------
  ;; Argument (I.E. the vector angle of complex point in radians)
  ;; arg(a+b1) => tan2(b,a)
  (func $arg
        (export "arg")
        (param $a f64)
        (param $b f64)
        (result f64)
    (call $host_atan2 (local.get $b) (local.get $a))
  )

  ;; ---------------------------------------------------------------------------
  ;; Convert complex number from rectangular to polar coordinates
  ;; to_polar(z) => [hypot(z), arg(z)]
  (func $to_polar
        (export "to_polar")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $hypot (local.get $a) (local.get $b))
    (call $arg   (local.get $a) (local.get $b))
  )

  ;; ---------------------------------------------------------------------------
  ;; Convert complex number from polar to rectangular coordinates
  ;; to_rect(hypot, theta) => (hypot * cos(theta), hypot * sin(theta))
  (func $to_rect
        (export "to_rect")
        (param $hypot f64)
        (param $theta f64)
        (result f64 f64)
    (f64.mul (local.get $hypot) (call $host_cos (local.get $theta)))
    (f64.mul (local.get $hypot) (call $host_sin (local.get $theta)))
  )

  ;; ---------------------------------------------------------------------------
  ;; Principal value of the natural logarithm
  ;; ln(a+bi) => ln|a| + i*arg(a+bi)
  (func $ln
        (export "ln")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (local $real f64)
    (local $imag f64)

    ;; Check if the imaginary part is zero
    (if (f64.eq (local.get $b) (f64.const 0))
      (then
        ;; Yup, so check if the real part is also zero
        (if (f64.eq (local.get $a) (f64.const 0))
          ;; Arrgghh! Very danger, mathematics go explody-bang!
          ;; The call to `unreachable` needs to be replaced with a trap
          (then unreachable)
          (else
            ;; Real part is always ln(|a|)
            (local.set $real (call $host_ln (f64.abs (local.get $a))))

            ;; What's the sign of the real part?
            (if (f64.lt (local.get $a) (f64.const 0))
              (then
                ;; -ve, so imaginary part is -π
                (local.set $imag (global.get $MINUS_PI))
              )
              (else
                ;; +ve, so imaginary part is 0
                (local.set $imag (f64.const 0))
              )
            )
          )
        )
      )
      (else
        ;; Imaginary part is non-zero
        (call $to_polar (local.get $a) (local.get $b))
        local.set $imag
        local.set $real

        (local.set $real (call $host_ln (local.get $real)))
      )
    )

    (local.get $real)
    (local.get $imag)
  )

  ;; ---------------------------------------------------------------------------
  ;; Add two complex numbers
  ;; add(z1, z2) => z3
  (func $add
        (export "add")
        (param $a1 f64) (param $b1 f64)
        (param $a2 f64) (param $b2 f64)
        (result f64 f64)
    (f64.add (local.get $a1) (local.get $a2))
    (f64.add (local.get $b1) (local.get $b2))
  )

  ;; ---------------------------------------------------------------------------
  ;; Subtract two complex numbers
  ;; sub(z1, z2) => add(z1, -z2) => z3
  (func $sub
        (export "sub")
        (param $a1 f64) (param $b1 f64)
        (param $a2 f64) (param $b2 f64)
        (result f64 f64)
    (call $add
      (local.get $a1)
      (local.get $b1)
      (f64.mul (local.get $a2) (f64.const -1))
      (f64.mul (local.get $b2) (f64.const -1))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Multiply two complex numbers
  ;; mul(z1, z2) => z3
  (func $mul
        (export "mul")
        (param $a1 f64) (param $b1 f64)
        (param $a2 f64) (param $b2 f64)
        (result f64 f64)
    (f64.add
      (f64.mul        (local.get $a1) (local.get $a2))
      (call $imag_mul (local.get $b1) (local.get $b2))
    )
    (f64.add
      (f64.mul (local.get $a1) (local.get $b2))
      (f64.mul (local.get $a2) (local.get $b1))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Square a complex number
  ;; sqr(z) => z^2
  (func $sqr
        (export "sqr")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $mul (local.get $a) (local.get $b)
               (local.get $a) (local.get $b)
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Multiply a complex number by i
  ;; i * (a+bi) => (-b+ai)
  (func $mul_by_i
        (export "mul_by_i")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (f64.mul (local.get $b) (f64.const -1))
    local.get $a
  )

  ;; ---------------------------------------------------------------------------
  ;; Divide two complex numbers
  ;; z1 / z2 => z1 * conj(z2) / z2 * conj(z2)
  ;;         => z1 * conj(z2) / norm_sqr(z2)
  (func $div
        (export "div")
        (param $a1 f64) (param $b1 f64)
        (param $a2 f64) (param $b2 f64)
        (result f64 f64)

    (local $conjA f64)
    (local $conjB f64)
    (local $realDenom f64)
    (local $realNumer f64)
    (local $imagNumer f64)

    ;; If both parts of the divisor are zero, then mathematics go explody-bang
    ;; The call to `unreachable` needs to be replaced with a trap
    (if (f64.eq (local.get $a2) (f64.const 0))
      (then
        (if (f64.eq (local.get $b2) (f64.const 0))
          (then unreachable)
        )
      )
    )

    ;; Derive the real denominator
    (local.set $realDenom (call $norm_sqr (local.get $a2) (local.get $b2)))

    ;; Derive the conjugate of denominator
    (call $conj (local.get $a2) (local.get $b2))
    local.set $conjB
    local.set $conjA

    ;; Store real and imaginary parts of complex numerator
    (call $mul
      (local.get $a1)    (local.get $b1)
      (local.get $conjA) (local.get $conjB)
    )
    local.set $imagNumer
    local.set $realNumer

    (f64.div (local.get $realNumer) (local.get $realDenom))
    (f64.div (local.get $imagNumer) (local.get $realDenom))
  )

  ;; ---------------------------------------------------------------------------
  ;; Principal value of the square root
  ;; sqrt(z) => √(a+bi)
  ;;   if (b == 0)
  ;;     if (a >= 0) return √a
  ;;     else        return i√|a|
  ;;   else
  ;;     if (a == 0)
  ;;       if (b >= 0) return √(b/2) + i√(b/2)
  ;;       else        return √(|b|/2) - i√(|b|/2)
  ;;     else
  ;;       (mag,theta) = to_polar(a+bi)
  ;;       return to_rect(√mag, theta/2)
  (func $sqrt
        (export "sqrt")
        (param $real f64)
        (param $imag f64)
        (result f64 f64)

    (local $root_real f64)
    (local $root_half_imag f64)
    (local $mag f64)
    (local $theta f64)
    (local $return_real f64)
    (local $return_imag f64)

    ;; Is imaginary part zero?
    (if (f64.eq (local.get $imag) (f64.const 0))
      (then
        ;; Yup, so find the root of the real part and return it as either the
        ;; real or imaginary part depending on its sign
        (if (f64.lt (local.get $real) (f64.const 0))
          (then
            (local.set $return_real (f64.const 0))
            (local.set $return_imag (f64.sqrt (f64.abs (local.get $real))))
          )
          (else
            (local.set $return_real (f64.sqrt (local.get $real)))
            (local.set $return_imag (f64.const 0))
          )
        )
      )
      (else
        ;; Nope, the imaginary part is non-zero
        ;; Is the real part zero?
        (if (f64.eq (local.get $real) (f64.const 0))
          (then
            ;; Find the root of half of the imaginary part.
            ;; This value is always returned as the real part
            (local.set $root_half_imag
                       (f64.sqrt (f64.div (f64.abs (local.get $imag))
                                          (f64.const 2))))
            (local.set $return_real (local.get $root_half_imag))

            ;; Inherit the sign of the imaginary part
            (if (f64.ge (local.get $imag) (f64.const 0))
              (then
                (local.set $return_imag (local.get $root_half_imag))
              )
              (else
                (local.set $return_imag (f64.mul (local.get $root_half_imag)
                                                 (f64.const -1)))
              )
            )
          )
          (else
            ;; Both parts are non-zero, so convert to polar coordinates,
            ;; find the √mag, halve the angle, then convert back to
            ;; rectangular coordinates
            (call $to_polar (local.get $real) (local.get $imag))
            (local.set $theta)
            (local.set $mag)

            (call $to_rect (f64.sqrt (local.get $mag))
                           (f64.div  (local.get $theta) (f64.const 2)))

            local.set $return_imag
            local.set $return_real
          )
        )
      )
    )

    (local.get $return_real)
    (local.get $return_imag)
  )

  ;; ---------------------------------------------------------------------------
  ;; The square root of one minus the complex number squared
  ;; sqrt_1mz2(z) => √(1 - z^2)
  (func $sqrt_1mz2
        (export "sqrt_1mz2")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $sqrt
      (call $sub
        (f64.const 1) (f64.const 0)
        (call $sqr (local.get $a) (local.get $b))
      )
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; The square root of one plus the complex number squared
  ;; sqrt_1pz2(z) => √(1 + z^2)
  (func $sqrt_1pz2
        (export "sqrt_1pz2")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $sqrt
      (call $add
        (f64.const 1) (f64.const 0)
        (call $sqr (local.get $a) (local.get $b))
      )
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Trigonometric functions
  ;; ---------------------------------------------------------------------------
  ;; Complex sine
  ;; sin(a+bi) = sin(a)cosh(b) + i*cos(a)sinh(b)
  (func $sin
        (export "sin")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (f64.mul
      (call $host_sin  (local.get $a))
      (call $host_cosh (local.get $b))
    )
    (f64.mul
      (call $host_cos  (local.get $a))
      (call $host_sinh (local.get $b))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex arcsine
  ;; asin(z) = -i * ln((sqrt(1 - z^2) + iz))
  (func $asin
        (export "asin")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $mul
      (call $ln
        (call $add
          (call $sqrt_1mz2 (local.get $a) (local.get $b))
          (call $mul_by_i  (local.get $a) (local.get $b))
        )
      )
      (f64.const 0) (f64.const -1)
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex hyperbolic sine
  ;; sinh(a+bi) = sinh(a)cos(b) + i*cosh(a)sin(b)
  (func $sinh
        (export "sinh")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (f64.mul
      (call $host_sinh (local.get $a))
      (call $host_cos  (local.get $b))
    )
    (f64.mul
      (call $host_cosh (local.get $a))
      (call $host_sin  (local.get $b))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex hyperbolic arcsine
  ;; asinh(z) = ln(z + sqrt(1+z^2))
  (func $asinh
        (export "asinh")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $ln
          (call $add
            (local.get $a) (local.get $b)
            (call $sqrt_1pz2 (local.get $a) (local.get $b))
          )
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex cosine
  ;; cos(a+bi) = cos(a)cosh(b) - i*sin(a)sinh(b)
  (func $cos
        (export "cos")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (f64.mul
      (call $host_cos  (local.get $a))
      (call $host_cosh (local.get $b))
    )
    (f64.mul
      (f64.mul
        (call $host_sin  (local.get $a))
        (call $host_sinh (local.get $b))
      )
      (f64.const -1)
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex arccosine
  ;; acos(z) = -i * ln(i * (sqrt(1-z^2) + z))
  (func $acos
        (export "acos")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $mul
      (call $ln
        (call $add
          (call $mul_by_i (call $sqrt_1mz2 (local.get $a) (local.get $b)))
          (local.get $a) (local.get $b)
        )
      )
      (f64.const 0) (f64.const -1)
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex hyperbolic cosine
  ;; cosh(a+bi) = cosh(a)cos(b) + i*sinh(a)sin(b)
  (func $cosh
        (export "cosh")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (f64.mul
      (call $host_cosh (local.get $a))
      (call $host_cos  (local.get $b))
    )
    (f64.mul
      (call $host_sinh (local.get $a))
      (call $host_sin  (local.get $b))
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex hyperbolic arccosine
  ;; acosh(z) = 2 * ln(sqrt((z+1)/2) + sqrt((z-1)/2))
  (func $acosh
        (export "acosh")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $mul
      (f64.const 2) (f64.const 0)
      (call $ln
        (call $add
          (call $sqrt
            (call $div
              (call $add (local.get $a) (local.get $b)
                         (f64.const 1) (f64.const 0))
              (f64.const 2) (f64.const 0)
            )
          )
          (call $sqrt
            (call $div
              (call $sub (local.get $a) (local.get $b)
                         (f64.const 1) (f64.const 0))
              (f64.const 2) (f64.const 0)
            )
          )
        )
      )
    )
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex tangent
  ;; tan(a+bi) = (sin(2a) + i*sinh(2b)) / (cos(2a) + cosh(2b))
  (func $tan
        (export "tan")
        (param $a f64)
        (param $b f64)
        (result f64 f64)

    (local $two_a f64)
    (local $two_b f64)
    (local $divisor f64)

    (local.set $two_a (f64.mul (local.get $a) (f64.const 2)))
    (local.set $two_b (f64.mul (local.get $b) (f64.const 2)))
    (local.set $divisor
      (f64.add
        (call $host_cos  (local.get $two_a))
        (call $host_cosh (local.get $two_b))
      )
    )

    (f64.div (call $host_sin  (local.get $two_a)) (local.get $divisor))
    (f64.div (call $host_sinh (local.get $two_b)) (local.get $divisor))
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex arctangent
  ;; arctan(z) = (ln(1+iz) - ln(1-iz))/(2i)
  (func $atan
        (export "atan")
        (param $a f64)
        (param $b f64)
        (result f64 f64)

    (local $i_z_real f64)
    (local $i_z_imag f64)
    (local $return_real f64)
    (local $return_imag f64)

    (call $mul_by_i (local.get $a) (local.get $b))
    local.set $i_z_imag
    local.set $i_z_real

    (call $div
      (call $sub
        (call $ln (call $add (f64.const 1) (f64.const 0)
                             (local.get $i_z_real) (local.get $i_z_imag)
                  )
        )
        (call $ln (call $sub (f64.const 1) (f64.const 0)
                             (local.get $i_z_real) (local.get $i_z_imag)
                  )
        )
      )
      (f64.const 0) (f64.const 2)
    )
    local.set $return_imag
    local.set $return_real

    (local.get $return_real)
    (local.get $return_imag)
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex hyperbolic tangent
  ;; tanh(a+bi) = (sinh(2a) + i*sin(2b))/(cosh(2a) + cos(2b))
  (func $tanh
        (export "tanh")
        (param $a f64)
        (param $b f64)
        (result f64 f64)

    (local $two_a f64)
    (local $two_b f64)
    (local $divisor f64)

    (local.set $two_a (f64.mul (local.get $a) (f64.const 2)))
    (local.set $two_b (f64.mul (local.get $b) (f64.const 2)))
    (local.set $divisor
      (f64.add
        (call $host_cosh (local.get $two_a))
        (call $host_cos  (local.get $two_b))
      )
    )

    (f64.div (call $host_sinh (local.get $two_a)) (local.get $divisor))
    (f64.div (call $host_sin  (local.get $two_b)) (local.get $divisor))
  )

  ;; ---------------------------------------------------------------------------
  ;; Complex hyperbolic arctangent
  ;; atanh(z) = (ln(1+z) - ln(1-z))/2
  (func $atanh
        (export "atanh")
        (param $a f64)
        (param $b f64)
        (result f64 f64)
    (call $div
      (call $sub
        (call $ln
          (call $add (f64.const 1) (f64.const 0)
                     (local.get $a) (local.get $b))
        )
        (call $ln
          (call $sub (f64.const 1) (f64.const 0)
                     (local.get $a) (local.get $b))
        )
      )
      (f64.const 2) (f64.const 0)
    )
  )
)
