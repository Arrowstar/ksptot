/*
 * mod.c
 *
 * Code generation for function 'mod'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "mod.h"

/* Function Definitions */
real_T b_mod(real_T x)
{
  real_T r;
  boolean_T rEQ0;
  real_T q;
  if ((!muDoubleScalarIsInf(x)) && (!muDoubleScalarIsNaN(x))) {
    if (x == 0.0) {
      r = 0.0;
    } else {
      r = muDoubleScalarRem(x, 6.2831853071795862);
      rEQ0 = (r == 0.0);
      if (!rEQ0) {
        q = muDoubleScalarAbs(x / 6.2831853071795862);
        rEQ0 = (muDoubleScalarAbs(q - muDoubleScalarFloor(q + 0.5)) <=
                2.2204460492503131E-16 * q);
      }

      if (rEQ0) {
        r = 0.0;
      } else {
        if (x < 0.0) {
          r += 6.2831853071795862;
        }
      }
    }
  } else {
    r = rtNaN;
  }

  return r;
}

real_T c_mod(real_T x)
{
  real_T r;
  if ((!muDoubleScalarIsInf(x)) && (!muDoubleScalarIsNaN(x))) {
    if (x == 0.0) {
      r = 0.0;
    } else {
      r = muDoubleScalarRem(x, 7.0);
      if (r == 0.0) {
        r = 0.0;
      } else {
        if (x < 0.0) {
          r += 7.0;
        }
      }
    }
  } else {
    r = rtNaN;
  }

  return r;
}

/* End of code generation (mod.c) */
