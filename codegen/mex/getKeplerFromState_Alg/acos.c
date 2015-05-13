/*
 * acos.c
 *
 * Code generation for function 'acos'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "acos.h"

/* Function Declarations */
static void eml_scalar_sqrt(creal_T *x);

/* Function Definitions */
static void eml_scalar_sqrt(creal_T *x)
{
  real_T absxi;
  real_T absxr;
  if (x->im == 0.0) {
    if (x->re < 0.0) {
      absxi = 0.0;
      absxr = muDoubleScalarSqrt(muDoubleScalarAbs(x->re));
    } else {
      absxi = muDoubleScalarSqrt(x->re);
      absxr = 0.0;
    }
  } else if (x->re == 0.0) {
    if (x->im < 0.0) {
      absxi = muDoubleScalarSqrt(-x->im / 2.0);
      absxr = -absxi;
    } else {
      absxi = muDoubleScalarSqrt(x->im / 2.0);
      absxr = absxi;
    }
  } else if (muDoubleScalarIsNaN(x->re) || muDoubleScalarIsNaN(x->im)) {
    absxi = rtNaN;
    absxr = rtNaN;
  } else if (muDoubleScalarIsInf(x->im)) {
    absxi = rtInf;
    absxr = x->im;
  } else if (muDoubleScalarIsInf(x->re)) {
    if (x->re < 0.0) {
      absxi = 0.0;
      absxr = rtInf;
    } else {
      absxi = rtInf;
      absxr = 0.0;
    }
  } else {
    absxr = muDoubleScalarAbs(x->re);
    absxi = muDoubleScalarAbs(x->im);
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

    if (x->re > 0.0) {
      absxr = 0.5 * (x->im / absxi);
    } else {
      if (x->im < 0.0) {
        absxr = -absxi;
      } else {
        absxr = absxi;
      }

      absxi = 0.5 * (x->im / absxr);
    }
  }

  x->re = absxi;
  x->im = absxr;
}

void b_acos(creal_T *x)
{
  creal_T v;
  creal_T u;
  real_T yi;
  boolean_T xneg;
  real_T t;
  if ((x->im == 0.0) && (!(muDoubleScalarAbs(x->re) > 1.0))) {
    x->re = muDoubleScalarAcos(x->re);
    x->im = 0.0;
  } else {
    v.re = 1.0 + x->re;
    v.im = x->im;
    eml_scalar_sqrt(&v);
    if (x->im != 0.0) {
      u.re = 1.0 - x->re;
      u.im = -x->im;
      eml_scalar_sqrt(&u);
    } else {
      u.re = 1.0 - x->re;
      u.im = x->im;
      eml_scalar_sqrt(&u);
    }

    yi = u.im * v.re - u.re * v.im;
    xneg = (yi < 0.0);
    if (xneg) {
      yi = -yi;
    }

    if (yi >= 2.68435456E+8) {
      yi = muDoubleScalarLog(yi) + 0.69314718055994529;
    } else if (yi > 2.0) {
      yi = muDoubleScalarLog(2.0 * yi + 1.0 / (muDoubleScalarSqrt(yi * yi + 1.0)
        + yi));
    } else {
      t = yi * yi;
      yi += t / (1.0 + muDoubleScalarSqrt(1.0 + t));
      t = muDoubleScalarAbs(yi);
      if ((t > 4.503599627370496E+15) || (!((!muDoubleScalarIsInf(yi)) &&
            (!muDoubleScalarIsNaN(yi))))) {
        yi = muDoubleScalarLog(1.0 + yi);
      } else if (t < 2.2204460492503131E-16) {
      } else {
        yi = muDoubleScalarLog(1.0 + yi) * (yi / ((1.0 + yi) - 1.0));
      }
    }

    if (xneg) {
      yi = -yi;
    }

    if (x->re == 0.0) {
      t = 1.5707963267948966;
    } else {
      t = 2.0 * muDoubleScalarAtan2(muDoubleScalarAbs(u.re), muDoubleScalarAbs
        (v.re));
      if ((u.re < 0.0) != (v.re < 0.0)) {
        t = -t;
      }
    }

    x->re = t;
    x->im = yi;
  }
}

/* End of code generation (acos.c) */
