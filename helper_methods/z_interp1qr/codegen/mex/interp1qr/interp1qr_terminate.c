/*
 * interp1qr_terminate.c
 *
 * Code generation for function 'interp1qr_terminate'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "interp1qr.h"
#include "interp1qr_terminate.h"
#include "_coder_interp1qr_mex.h"
#include "interp1qr_data.h"

/* Function Definitions */
void interp1qr_atexit(void)
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtEnterRtStackR2012b(&st);
  emlrtLeaveRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

void interp1qr_terminate(void)
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  st.tls = emlrtRootTLSGlobal;
  emlrtLeaveRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (interp1qr_terminate.c) */
