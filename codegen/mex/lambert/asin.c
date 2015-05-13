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
#include "eml_error.h"
#include "lambert_data.h"

/* Function Definitions */
void b_asin(const emlrtStack *sp, real_T x[2])
{
  int32_T k;
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  for (k = 0; k < 2; k++) {
    if ((x[k] < -1.0) || (1.0 < x[k])) {
      st.site = &kb_emlrtRSI;
      d_eml_error(&st);
    }
  }

  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarAsin(x[k]);
  }
}

/* End of code generation (asin.c) */
