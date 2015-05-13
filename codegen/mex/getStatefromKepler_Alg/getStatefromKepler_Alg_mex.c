/*
 * getStatefromKepler_Alg_mex.c
 *
 * Code generation for function 'getStatefromKepler_Alg'
 *
 * C source code generated on: Sun Feb 02 17:16:06 2014
 *
 */

/* Include files */
#include "mex.h"
#include "getStatefromKepler_Alg_api.h"
#include "getStatefromKepler_Alg_initialize.h"
#include "getStatefromKepler_Alg_terminate.h"

/* Function Declarations */
static void getStatefromKepler_Alg_mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
MEXFUNCTION_LINKAGE mxArray *emlrtMexFcnProperties(void);

/* Variable Definitions */
emlrtContext emlrtContextGlobal = { true, false, EMLRT_VERSION_INFO, NULL, "getStatefromKepler_Alg", NULL, false, {2045744189U,2170104910U,2743257031U,4284093946U}, NULL };
emlrtCTX emlrtRootTLSGlobal = NULL;

/* Function Definitions */
static void getStatefromKepler_Alg_mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  mxArray *outputs[2];
  mxArray *inputs[7];
  int n = 0;
  int nOutputs = (nlhs < 1 ? 1 : nlhs);
  int nInputs = nrhs;
  /* Module initialization. */
  getStatefromKepler_Alg_initialize(&emlrtContextGlobal);
  /* Check for proper number of arguments. */
  if (nrhs != 7) {
    emlrtErrMsgIdAndTxt(emlrtRootTLSGlobal, "EMLRT:runTime:WrongNumberOfInputs", 5, mxINT32_CLASS, 7, mxCHAR_CLASS, 22, "getStatefromKepler_Alg");
  } else if (nlhs > 2) {
    emlrtErrMsgIdAndTxt(emlrtRootTLSGlobal, "EMLRT:runTime:TooManyOutputArguments", 3, mxCHAR_CLASS, 22, "getStatefromKepler_Alg");
  }
  /* Temporary copy for mex inputs. */
  for (n = 0; n < nInputs; ++n) {
    inputs[n] = (mxArray *)prhs[n];
  }
  /* Call the function. */
  getStatefromKepler_Alg_api((const mxArray**)inputs, (const mxArray**)outputs);
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

mxArray *emlrtMexFcnProperties(void)
{
  const char *mexProperties[] = {
    "Version",
    "ResolvedFunctions",
    "EntryPoints"};
  const char *epProperties[] = {
    "Name",
    "NumberOfInputs",
    "NumberOfOutputs",
    "ConstantInputs"};
  mxArray *xResult = mxCreateStructMatrix(1,1,3,mexProperties);
  mxArray *xEntryPoints = mxCreateStructMatrix(1,1,4,epProperties);
  mxArray *xInputs = NULL;
  xInputs = mxCreateLogicalMatrix(1, 7);
  mxSetFieldByNumber(xEntryPoints, 0, 0, mxCreateString("getStatefromKepler_Alg"));
  mxSetFieldByNumber(xEntryPoints, 0, 1, mxCreateDoubleScalar(7));
  mxSetFieldByNumber(xEntryPoints, 0, 2, mxCreateDoubleScalar(2));
  mxSetFieldByNumber(xEntryPoints, 0, 3, xInputs);
  mxSetFieldByNumber(xResult, 0, 0, mxCreateString("8.1.0.604 (R2013a)"));
  mxSetFieldByNumber(xResult, 0, 1, (mxArray*)emlrtMexFcnResolvedFunctionsInfo());
  mxSetFieldByNumber(xResult, 0, 2, xEntryPoints);

  return xResult;
}
/* End of code generation (getStatefromKepler_Alg_mex.c) */
