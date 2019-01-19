/*
 * _coder_getStatefromKepler_Alg_mex.c
 *
 * Code generation for function '_coder_getStatefromKepler_Alg_mex'
 *
 */

/* Include files */
#include "getStatefromKepler_Alg.h"
#include "_coder_getStatefromKepler_Alg_mex.h"
#include "getStatefromKepler_Alg_terminate.h"
#include "_coder_getStatefromKepler_Alg_api.h"
#include "getStatefromKepler_Alg_initialize.h"
#include "getStatefromKepler_Alg_data.h"

/* Function Declarations */
static void c_getStatefromKepler_Alg_mexFun(int32_T nlhs, mxArray *plhs[2],
  int32_T nrhs, const mxArray *prhs[7]);

/* Function Definitions */
static void c_getStatefromKepler_Alg_mexFun(int32_T nlhs, mxArray *plhs[2],
  int32_T nrhs, const mxArray *prhs[7])
{
  int32_T n;
  const mxArray *inputs[7];
  const mxArray *outputs[2];
  int32_T b_nlhs;
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  st.tls = emlrtRootTLSGlobal;

  /* Check for proper number of arguments. */
  if (nrhs != 7) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 7, 4,
                        22, "getStatefromKepler_Alg");
  }

  if (nlhs > 2) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 22,
                        "getStatefromKepler_Alg");
  }

  /* Temporary copy for mex inputs. */
  for (n = 0; n < nrhs; n++) {
    inputs[n] = prhs[n];
    if (*emlrtBreakCheckR2012bFlagVar != 0) {
      emlrtBreakCheckR2012b(&st);
    }
  }

  /* Call the function. */
  getStatefromKepler_Alg_api(inputs, outputs);

  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    b_nlhs = 1;
  } else {
    b_nlhs = nlhs;
  }

  emlrtReturnArrays(b_nlhs, plhs, outputs);

  /* Module termination. */
  getStatefromKepler_Alg_terminate();
}

void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs, const mxArray
                 *prhs[])
{
  mexAtExit(getStatefromKepler_Alg_atexit);

  /* Initialize the memory manager. */
  /* Module initialization. */
  getStatefromKepler_Alg_initialize();

  /* Dispatch the entry-point. */
  c_getStatefromKepler_Alg_mexFun(nlhs, plhs, nrhs, prhs);
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  return emlrtRootTLSGlobal;
}

/* End of code generation (_coder_getStatefromKepler_Alg_mex.c) */
