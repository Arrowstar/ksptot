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
#include "eml_error.h"
#include "lambert_data.h"

/* Function Definitions */
void b_log(const emlrtStack *sp, real_T *x)
{
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  if (*x < 0.0) {
    st.site = &jb_emlrtRSI;
    c_eml_error(&st);
  }

  *x = muDoubleScalarLog(*x);
}

/* End of code generation (log.c) */
