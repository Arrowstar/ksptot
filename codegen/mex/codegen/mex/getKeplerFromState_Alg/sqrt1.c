/*
 * sqrt1.c
 *
 * Code generation for function 'sqrt1'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "sqrt1.h"

/* Function Definitions */
void b_sqrt(creal_T *x)
{
  real_T xr;
  real_T xi;
  real_T absxi;
  real_T absxr;
  xr = x->re;
  xi = x->im;
  if (xi == 0.0) {
    if (xr < 0.0) {
      absxi = 0.0;
      xr = muDoubleScalarSqrt(-xr);
    } else {
      absxi = muDoubleScalarSqrt(xr);
      xr = 0.0;
    }
  } else if (xr == 0.0) {
    if (xi < 0.0) {
      absxi = muDoubleScalarSqrt(-xi / 2.0);
      xr = -absxi;
    } else {
      absxi = muDoubleScalarSqrt(xi / 2.0);
      xr = absxi;
    }
  } else if (muDoubleScalarIsNaN(xr)) {
    absxi = xr;
  } else if (muDoubleScalarIsNaN(xi)) {
    absxi = xi;
    xr = xi;
  } else if (muDoubleScalarIsInf(xi)) {
    absxi = muDoubleScalarAbs(xi);
    xr = xi;
  } else if (muDoubleScalarIsInf(xr)) {
    if (xr < 0.0) {
      absxi = 0.0;
      xr = xi * -xr;
    } else {
      absxi = xr;
      xr = 0.0;
    }
  } else {
    absxr = muDoubleScalarAbs(xr);
    absxi = muDoubleScalarAbs(xi);
    if ((absxr > 4.4942328371557893E+307) || (absxi > 4.4942328371557893E+307))
    {
      absxr *= 0.5;
      absxi *= 0.5;
      absxi = muDoubleScalarHypot(absxr, absxi);
      if (absxi > absxr) {
        absxi = muDoubleScalarSqrt(absxi) * muDoubleScalarSqrt(1.0 + absxr /
          absxi);
      } else {
        absxi = muDoubleScalarSqrt(absxi) * 1.4142135623730951;
      }
    } else {
      absxi = muDoubleScalarSqrt((muDoubleScalarHypot(absxr, absxi) + absxr) *
        0.5);
    }

    if (xr > 0.0) {
      xr = 0.5 * (xi / absxi);
    } else {
      if (xi < 0.0) {
        xr = -absxi;
      } else {
        xr = absxi;
      }

      absxi = 0.5 * (xi / xr);
    }
  }

  x->re = absxi;
  x->im = xr;
}

/* End of code generation (sqrt1.c) */
