/*
 * getStatefromKepler_Alg_terminate.c
 *
 * Code generation for function 'getStatefromKepler_Alg_terminate'
 *
 * C source code generated on: Sun Feb 02 17:16:06 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getStatefromKepler_Alg.h"
#include "getStatefromKepler_Alg_terminate.h"

/* Function Definitions */
void getStatefromKepler_Alg_atexit(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

void getStatefromKepler_Alg_terminate(void)
{
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (getStatefromKepler_Alg_terminate.c) */
