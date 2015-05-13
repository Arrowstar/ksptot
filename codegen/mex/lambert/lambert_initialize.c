/*
 * lambert_initialize.c
 *
 * Code generation for function 'lambert_initialize'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "lambert_initialize.h"
#include "lambert_data.h"

/* Function Definitions */
void lambert_initialize(emlrtContext *aContext)
{
  emlrtStack st = { NULL, NULL, NULL };

  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, aContext, NULL, 1);
  st.tls = emlrtRootTLSGlobal;
  emlrtClearAllocCountR2012b(&st, false, 0U, 0);
  emlrtEnterRtStackR2012b(&st);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (lambert_initialize.c) */
