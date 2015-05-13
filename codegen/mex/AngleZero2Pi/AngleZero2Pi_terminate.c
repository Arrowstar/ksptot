/*
 * AngleZero2Pi_terminate.c
 *
 * Code generation for function 'AngleZero2Pi_terminate'
 *
 * C source code generated on: Sun Feb 02 17:27:56 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "AngleZero2Pi.h"
#include "AngleZero2Pi_terminate.h"

/* Function Definitions */
void AngleZero2Pi_atexit(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

void AngleZero2Pi_terminate(void)
{
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (AngleZero2Pi_terminate.c) */
