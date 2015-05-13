/*
 * AngleZero2Pi_initialize.c
 *
 * Code generation for function 'AngleZero2Pi_initialize'
 *
 * C source code generated on: Sun Feb 02 17:27:56 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "AngleZero2Pi.h"
#include "AngleZero2Pi_initialize.h"
#include "AngleZero2Pi_data.h"

/* Function Definitions */
void AngleZero2Pi_initialize(emlrtContext *aContext)
{
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, aContext, NULL, 1);
  emlrtClearAllocCountR2012b(emlrtRootTLSGlobal, FALSE, 0U, 0);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (AngleZero2Pi_initialize.c) */
