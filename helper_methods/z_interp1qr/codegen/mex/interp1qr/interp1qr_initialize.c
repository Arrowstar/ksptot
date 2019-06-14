/*
 * interp1qr_initialize.c
 *
 * Code generation for function 'interp1qr_initialize'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "interp1qr.h"
#include "interp1qr_initialize.h"
#include "_coder_interp1qr_mex.h"
#include "interp1qr_data.h"

/* Function Definitions */
void interp1qr_initialize(void)
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  mexFunctionCreateRootTLS();
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  st.tls = emlrtRootTLSGlobal;
  emlrtClearAllocCountR2012b(&st, false, 0U, 0);
  emlrtEnterRtStackR2012b(&st);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (interp1qr_initialize.c) */
