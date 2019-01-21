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
#include "complexTimes.h"
#include "sqrt1.h"

/* Function Definitions */
void b_acos(creal_T *x)
{
  creal_T v;
  creal_T u;
  real_T ci;
  real_T t3;
  boolean_T xneg;
  real_T t4;
  real_T scaleA;
  real_T sbr;
  real_T sbi;
  real_T scaleB;
  if ((x->im == 0.0) && (!(muDoubleScalarAbs(x->re) > 1.0))) {
    x->re = muDoubleScalarAcos(x->re);
    x->im = 0.0;
  } else {
    v.re = 1.0 + x->re;
    v.im = x->im;
    b_sqrt(&v);
    u.re = 1.0 - x->re;
    u.im = 0.0 - x->im;
    b_sqrt(&u);
    if ((-v.im == 0.0) && (u.im == 0.0)) {
      ci = 0.0;
    } else {
      ci = v.re * u.im + -v.im * u.re;
      if ((!((!muDoubleScalarIsInf(ci)) && (!muDoubleScalarIsNaN(ci)))) &&
          (!muDoubleScalarIsNaN(v.re)) && (!muDoubleScalarIsNaN(-v.im)) &&
          (!muDoubleScalarIsNaN(u.re)) && (!muDoubleScalarIsNaN(u.im))) {
        t3 = v.re;
        t4 = -v.im;
        scaleA = rescale(&t3, &t4);
        sbr = u.re;
        sbi = u.im;
        scaleB = rescale(&sbr, &sbi);
        if ((!muDoubleScalarIsInf(scaleA)) && (!muDoubleScalarIsNaN(scaleA)) &&
            ((!muDoubleScalarIsInf(scaleB)) && (!muDoubleScalarIsNaN(scaleB))))
        {
          xneg = true;
        } else {
          xneg = false;
        }

        if (muDoubleScalarIsNaN(ci) || (muDoubleScalarIsInf(ci) && xneg)) {
          ci = t3 * sbi + t4 * sbr;
          if (ci != 0.0) {
            ci = ci * scaleA * scaleB;
          } else {
            if ((muDoubleScalarIsInf(scaleA) && ((u.re == 0.0) || (u.im == 0.0)))
                || (muDoubleScalarIsInf(scaleB) && ((v.re == 0.0) || (-v.im ==
                   0.0)))) {
              t3 = v.re * u.im;
              t4 = -v.im * u.re;
              if (muDoubleScalarIsNaN(t3)) {
                t3 = 0.0;
              }

              if (muDoubleScalarIsNaN(t4)) {
                t4 = 0.0;
              }

              ci = t3 + t4;
            }
          }
        }
      }
    }

    xneg = (ci < 0.0);
    if (xneg) {
      ci = -ci;
    }

    if (ci >= 2.68435456E+8) {
      ci = muDoubleScalarLog(ci) + 0.69314718055994529;
    } else if (ci > 2.0) {
      ci = muDoubleScalarLog(2.0 * ci + 1.0 / (muDoubleScalarSqrt(ci * ci + 1.0)
        + ci));
    } else {
      t3 = ci * ci;
      ci += t3 / (1.0 + muDoubleScalarSqrt(1.0 + t3));
      t3 = muDoubleScalarAbs(ci);
      if ((t3 > 4.503599627370496E+15) || (!((!muDoubleScalarIsInf(ci)) &&
            (!muDoubleScalarIsNaN(ci))))) {
        ci = muDoubleScalarLog(1.0 + ci);
      } else {
        if (!(t3 < 2.2204460492503131E-16)) {
          ci = muDoubleScalarLog(1.0 + ci) * (ci / ((1.0 + ci) - 1.0));
        }
      }
    }

    if (xneg) {
      ci = -ci;
    }

    x->re = 2.0 * muDoubleScalarAtan2(u.re, v.re);
    x->im = ci;
  }
}

/* End of code generation (acos.c) */
