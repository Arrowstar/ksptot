/*
 * lambert_initialize.c
 *
 * Code generation for function 'lambert_initialize'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "lambert_initialize.h"
#include "_coder_lambert_mex.h"
#include "lambert_data.h"

/* Function Declarations */
static void lambert_once(void);

/* Function Definitions */
static void lambert_once(void)
{
  an_not_empty_init();
  sigmax_init();
}

void lambert_initialize(void)
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
  if (emlrtFirstTimeR2012b(emlrtRootTLSGlobal)) {
    lambert_once();
  }
}

/* End of code generation (lambert_initialize.c) */
