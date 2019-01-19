/*
 * acos.c
 *
 * Code generation for function 'acos'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "acos.h"
#include "error.h"

/* Variable Definitions */
static emlrtRSInfo mb_emlrtRSI = { 13, /* lineNo */
  "acos",                              /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\elfun\\acos.m"/* pathName */
};

/* Function Definitions */
void b_acos(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  if ((*x < -1.0) || (*x > 1.0)) {
    st.site = &mb_emlrtRSI;
    b_st.site = &mb_emlrtRSI;
    b_error(&b_st);
  }

  *x = muDoubleScalarAcos(*x);
}

void c_acos(const emlrtStack *sp, real_T x[2])
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
    st.site = &mb_emlrtRSI;
    b_st.site = &mb_emlrtRSI;
    b_error(&b_st);
  }

  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarAcos(x[k]);
  }
}

/* End of code generation (acos.c) */
