/*
 * dotARH_terminate.c
 *
 * Code generation for function 'dotARH_terminate'
 *
 * C source code generated on: Sun Feb 02 16:40:17 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "dotARH.h"
#include "dotARH_terminate.h"

/* Function Definitions */
void dotARH_atexit(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

void dotARH_terminate(void)
{
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (dotARH_terminate.c) */
