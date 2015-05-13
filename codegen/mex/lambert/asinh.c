/*
 * asinh.c
 *
 * Code generation for function 'asinh'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "asinh.h"

/* Function Definitions */
void b_asinh(real_T *x)
{
  boolean_T xneg;
  real_T t;
  xneg = (*x < 0.0);
  if (xneg) {
    *x = -*x;
  }

  if (*x >= 2.68435456E+8) {
    *x = muDoubleScalarLog(*x) + 0.69314718055994529;
  } else if (*x > 2.0) {
    *x = muDoubleScalarLog(2.0 * *x + 1.0 / (muDoubleScalarSqrt(*x * *x + 1.0) +
      *x));
  } else {
    t = *x * *x;
    *x += t / (1.0 + muDoubleScalarSqrt(1.0 + t));
    t = muDoubleScalarAbs(*x);
    if ((t > 4.503599627370496E+15) || (!((!muDoubleScalarIsInf(*x)) &&
          (!muDoubleScalarIsNaN(*x))))) {
      *x = muDoubleScalarLog(1.0 + *x);
    } else if (t < 2.2204460492503131E-16) {
    } else {
      *x = muDoubleScalarLog(1.0 + *x) * (*x / ((1.0 + *x) - 1.0));
    }
  }

  if (xneg) {
    *x = -*x;
  }
}

/* End of code generation (asinh.c) */
