/*
 * crossARH_initialize.c
 *
 * Code generation for function 'crossARH_initialize'
 *
 * C source code generated on: Sun Feb 02 16:50:08 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "crossARH.h"
#include "crossARH_initialize.h"

/* Variable Definitions */
static const volatile char_T *emlrtBreakCheckR2012bFlagVar;

/* Function Definitions */
void crossARH_initialize(emlrtContext *aContext)
{
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, aContext, NULL, 1);
  emlrtClearAllocCountR2012b(emlrtRootTLSGlobal, FALSE, 0U, 0);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (crossARH_initialize.c) */
