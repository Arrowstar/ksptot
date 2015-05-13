/*
 * dotARH_initialize.c
 *
 * Code generation for function 'dotARH_initialize'
 *
 * C source code generated on: Sun Feb 02 16:40:17 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "dotARH.h"
#include "dotARH_initialize.h"

/* Variable Definitions */
static const volatile char_T *emlrtBreakCheckR2012bFlagVar;

/* Function Definitions */
void dotARH_initialize(emlrtContext *aContext)
{
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, aContext, NULL, 1);
  emlrtClearAllocCountR2012b(emlrtRootTLSGlobal, FALSE, 0U, 0);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (dotARH_initialize.c) */
