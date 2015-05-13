/*
 * crossARH_terminate.c
 *
 * Code generation for function 'crossARH_terminate'
 *
 * C source code generated on: Sun Feb 02 16:50:08 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "crossARH.h"
#include "crossARH_terminate.h"

/* Function Definitions */
void crossARH_atexit(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

void crossARH_terminate(void)
{
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (crossARH_terminate.c) */
