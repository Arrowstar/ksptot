/*
 * _coder_getStatefromKepler_Alg_mex.c
 *
 * Code generation for function 'getStatefromKepler_Alg'
 *
 */

/* Include files */
#include "mex.h"
#include "_coder_getStatefromKepler_Alg_api.h"
#include "getStatefromKepler_Alg_initialize.h"
#include "getStatefromKepler_Alg_terminate.h"

/* Function Declarations */
static void getStatefromKepler_Alg_mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/* Variable Definitions */
emlrtContext emlrtContextGlobal = { true, false, EMLRT_VERSION_INFO, NULL, "getStatefromKepler_Alg", NULL, false, {2045744189U,2170104910U,2743257031U,4284093946U}, NULL };
void *emlrtRootTLSGlobal = NULL;

/* Function Definitions */
static void getStatefromKepler_Alg_mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const mxArray *outputs[2];
  const mxArray *inputs[7];
  int n = 0;
  int nOutputs = (nlhs < 1 ? 1 : nlhs);
  int nInputs = nrhs;
  emlrtStack st = { NULL, NULL, NULL };
  /* Module initialization. */
  getStatefromKepler_Alg_initialize(&emlrtContextGlobal);
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 7) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, mxINT32_CLASS, 7, mxCHAR_CLASS, 22, "getStatefromKepler_Alg");
  } else if (nlhs > 2) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, mxCHAR_CLASS, 22, "getStatefromKepler_Alg");
  }
  /* Temporary copy for mex inputs. */
  for (n = 0; n < nInputs; ++n) {
    inputs[n] = prhs[n];
  }
  /* Call the function. */
  getStatefromKepler_Alg_api(inputs, outputs);
  /* Copy over outputs to the caller. */
  for (n = 0; n < nOutputs; ++n) {
    plhs[n] = emlrtReturnArrayR2009a(outputs[n]);
  }
  /* Module finalization. */
  getStatefromKepler_Alg_terminate();
}

void getStatefromKepler_Alg_atexit_wrapper(void)
{
   getStatefromKepler_Alg_atexit();
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Initialize the memory manager. */
  mexAtExit(getStatefromKepler_Alg_atexit_wrapper);
  /* Dispatch the entry-point. */
  getStatefromKepler_Alg_mexFunction(nlhs, plhs, nrhs, prhs);
}
/* End of code generation (_coder_getStatefromKepler_Alg_mex.c) */
