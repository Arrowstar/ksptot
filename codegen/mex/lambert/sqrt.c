/*
 * sqrt.c
 *
 * Code generation for function 'sqrt'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "sqrt.h"
#include "eml_error.h"
#include "lambert_data.h"

/* Function Definitions */
void b_sqrt(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  if (*x < 0.0) {
    st.site = &hb_emlrtRSI;
    eml_error(&st);
  }

  *x = muDoubleScalarSqrt(*x);
}

void c_sqrt(const emlrtStack *sp, real_T x[2])
{
  int32_T k;
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  for (k = 0; k < 2; k++) {
    if (x[k] < 0.0) {
      st.site = &hb_emlrtRSI;
      eml_error(&st);
    }
  }

  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarSqrt(x[k]);
  }
}

/* End of code generation (sqrt.c) */
