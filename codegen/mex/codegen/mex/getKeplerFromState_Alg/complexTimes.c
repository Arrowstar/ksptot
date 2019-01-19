/*
 * complexTimes.c
 *
 * Code generation for function 'complexTimes'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "complexTimes.h"

/* Function Definitions */
real_T rescale(real_T *re, real_T *im)
{
  real_T scale;
  real_T absim;
  scale = muDoubleScalarAbs(*re);
  absim = muDoubleScalarAbs(*im);
  if (scale > absim) {
    if (*re < 0.0) {
      *re = -1.0;
    } else {
      *re = 1.0;
    }

    *im /= scale;
  } else if (absim > scale) {
    *re /= absim;
    if (*im < 0.0) {
      *im = -1.0;
    } else {
      *im = 1.0;
    }

    scale = absim;
  } else {
    if (*re < 0.0) {
      *re = -1.0;
    } else {
      *re = 1.0;
    }

    if (*im < 0.0) {
      *im = -1.0;
    } else {
      *im = 1.0;
    }
  }

  return scale;
}

/* End of code generation (complexTimes.c) */
