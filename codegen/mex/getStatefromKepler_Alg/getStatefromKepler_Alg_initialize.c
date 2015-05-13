/*
 * getStatefromKepler_Alg_initialize.c
 *
 * Code generation for function 'getStatefromKepler_Alg_initialize'
 *
 * C source code generated on: Sun Feb 02 17:16:06 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getStatefromKepler_Alg.h"
#include "getStatefromKepler_Alg_initialize.h"

/* Variable Definitions */
static const volatile char_T *emlrtBreakCheckR2012bFlagVar;

/* Function Definitions */
void getStatefromKepler_Alg_initialize(emlrtContext *aContext)
{
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, aContext, NULL, 1);
  emlrtClearAllocCountR2012b(emlrtRootTLSGlobal, FALSE, 0U, 0);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (getStatefromKepler_Alg_initialize.c) */
