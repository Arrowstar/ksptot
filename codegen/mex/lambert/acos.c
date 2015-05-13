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
#include "eml_error.h"

/* Variable Definitions */
static emlrtRSInfo ib_emlrtRSI = { 15, "acos",
  "C:\\Program Files\\MATLAB\\R2014b\\toolbox\\eml\\lib\\matlab\\elfun\\acos.m"
};

/* Function Definitions */
void b_acos(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  if ((*x < -1.0) || (1.0 < *x)) {
    st.site = &ib_emlrtRSI;
    b_eml_error(&st);
  }

  *x = muDoubleScalarAcos(*x);
}

void c_acos(const emlrtStack *sp, real_T x[2])
{
  int32_T k;
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  for (k = 0; k < 2; k++) {
    if ((x[k] < -1.0) || (1.0 < x[k])) {
      st.site = &ib_emlrtRSI;
      b_eml_error(&st);
    }
  }

  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarAcos(x[k]);
  }
}

/* End of code generation (acos.c) */
