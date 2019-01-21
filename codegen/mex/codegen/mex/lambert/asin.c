/*
 * asin.c
 *
 * Code generation for function 'asin'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "asin.h"
#include "error.h"

/* Variable Definitions */
static emlrtRSInfo rb_emlrtRSI = { 13, /* lineNo */
  "asin",                              /* fcnName */
  "/usr/local/MATLAB/R2017b/toolbox/eml/lib/matlab/elfun/asin.m"/* pathName */
};

/* Function Definitions */
void b_asin(const emlrtStack *sp, real_T x[2])
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
    if (p || ((x[k] < -1.0) || (x[k] > 1.0))) {
      p = true;
    } else {
      p = false;
    }
  }

  if (p) {
    st.site = &rb_emlrtRSI;
    b_st.site = &rb_emlrtRSI;
    e_error(&b_st);
  }

  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarAsin(x[k]);
  }
}

void c_asin(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  if ((*x < -1.0) || (*x > 1.0)) {
    st.site = &rb_emlrtRSI;
    b_st.site = &rb_emlrtRSI;
    e_error(&b_st);
  }

  *x = muDoubleScalarAsin(*x);
}

/* End of code generation (asin.c) */
