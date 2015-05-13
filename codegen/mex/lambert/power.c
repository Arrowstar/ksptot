/*
 * power.c
 *
 * Code generation for function 'power'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "power.h"
#include "eml_error.h"
#include "lambert_data.h"

/* Function Definitions */
real_T b_power(const emlrtStack *sp, real_T a)
{
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  st.site = &xc_emlrtRSI;
  b_st.prev = &st;
  b_st.tls = st.tls;
  if (a < 0.0) {
    b_st.site = &yc_emlrtRSI;
    f_eml_error(&b_st);
  }

  return muDoubleScalarPower(a, 0.0625);
}

void power(const real_T a[2], real_T y[2])
{
  int32_T k;
  for (k = 0; k < 2; k++) {
    y[k] = a[k] * a[k];
  }
}

/* End of code generation (power.c) */
