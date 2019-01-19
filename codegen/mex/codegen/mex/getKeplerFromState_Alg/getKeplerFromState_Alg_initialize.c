/*
 * getKeplerFromState_Alg_initialize.c
 *
 * Code generation for function 'getKeplerFromState_Alg_initialize'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "getKeplerFromState_Alg_initialize.h"
#include "_coder_getKeplerFromState_Alg_mex.h"
#include "getKeplerFromState_Alg_data.h"

/* Function Definitions */
void getKeplerFromState_Alg_initialize(void)
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

/* End of code generation (getKeplerFromState_Alg_initialize.c) */
