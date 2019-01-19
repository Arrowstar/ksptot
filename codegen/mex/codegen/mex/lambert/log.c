/*
 * log.c
 *
 * Code generation for function 'log'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "log.h"
#include "error.h"

/* Variable Definitions */
static emlrtRSInfo qb_emlrtRSI = { 13, /* lineNo */
  "log",                               /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\elfun\\log.m"/* pathName */
};

/* Function Definitions */
void b_log(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  if (*x < 0.0) {
    st.site = &qb_emlrtRSI;
    b_st.site = &qb_emlrtRSI;
    d_error(&b_st);
  }

  *x = muDoubleScalarLog(*x);
}

/* End of code generation (log.c) */
