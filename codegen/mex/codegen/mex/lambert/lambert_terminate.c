/*
 * lambert_terminate.c
 *
 * Code generation for function 'lambert_terminate'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "lambert_terminate.h"
#include "_coder_lambert_mex.h"
#include "lambert_data.h"

/* Function Definitions */
void lambert_atexit(void)
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

void lambert_terminate(void)
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  st.tls = emlrtRootTLSGlobal;
  emlrtLeaveRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (lambert_terminate.c) */
