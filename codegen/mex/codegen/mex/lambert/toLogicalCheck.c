/*
 * toLogicalCheck.c
 *
 * Code generation for function 'toLogicalCheck'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "toLogicalCheck.h"
#include "error.h"

/* Variable Definitions */
static emlrtRSInfo ae_emlrtRSI = { 12, /* lineNo */
  "toLogicalCheck",                    /* fcnName */
  "/usr/local/MATLAB/R2017b/toolbox/eml/eml/+coder/+internal/toLogicalCheck.m"/* pathName */
};

/* Function Definitions */
void toLogicalCheck(const emlrtStack *sp, real_T x)
{
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  if (muDoubleScalarIsNaN(x)) {
    st.site = &ae_emlrtRSI;
    b_st.site = &ae_emlrtRSI;
    g_error(&b_st);
  }
}

/* End of code generation (toLogicalCheck.c) */
