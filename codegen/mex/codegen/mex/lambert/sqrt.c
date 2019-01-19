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
#include "error.h"
#include "lambert_data.h"

/* Function Definitions */
void b_sqrt(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  if (*x < 0.0) {
    st.site = &lb_emlrtRSI;
    b_st.site = &lb_emlrtRSI;
    error(&b_st);
  }

  *x = muDoubleScalarSqrt(*x);
}

void c_sqrt(const emlrtStack *sp, real_T x[2])
{
  boolean_T p;
  int32_T k;
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  p = false;
  for (k = 0; k < 2; k++) {
    if (p || (x[k] < 0.0)) {
      p = true;
    } else {
      p = false;
    }
  }

  if (p) {
    st.site = &lb_emlrtRSI;
    b_st.site = &lb_emlrtRSI;
    error(&b_st);
  }

  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarSqrt(x[k]);
  }
}

/* End of code generation (sqrt.c) */
