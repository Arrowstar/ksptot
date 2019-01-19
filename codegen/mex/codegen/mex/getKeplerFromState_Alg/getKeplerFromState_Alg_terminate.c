/*
 * getKeplerFromState_Alg_terminate.c
 *
 * Code generation for function 'getKeplerFromState_Alg_terminate'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "getKeplerFromState_Alg_terminate.h"
#include "_coder_getKeplerFromState_Alg_mex.h"
#include "getKeplerFromState_Alg_data.h"

/* Function Definitions */
void getKeplerFromState_Alg_atexit(void)
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

void getKeplerFromState_Alg_terminate(void)
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  st.tls = emlrtRootTLSGlobal;
  emlrtLeaveRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (getKeplerFromState_Alg_terminate.c) */
