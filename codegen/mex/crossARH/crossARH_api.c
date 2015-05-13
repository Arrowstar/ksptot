/*
 * crossARH_api.c
 *
 * Code generation for function 'crossARH_api'
 *
 * C source code generated on: Sun Feb 02 16:50:08 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "crossARH.h"
#include "crossARH_api.h"

/* Type Definitions */
#ifndef typedef_ResolvedFunctionInfo
#define typedef_ResolvedFunctionInfo

typedef struct {
  const char * context;
  const char * name;
  const char * dominantType;
  const char * resolved;
  uint32_T fileTimeLo;
  uint32_T fileTimeHi;
  uint32_T mFileTimeLo;
  uint32_T mFileTimeHi;
} ResolvedFunctionInfo;

#endif                                 /*typedef_ResolvedFunctionInfo*/

/* Function Declarations */
static real_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[3];
static real_T (*c_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier *
  msgId))[3];
static real_T (*emlrt_marshallIn(const mxArray *u, const char_T *identifier))[3];
static const mxArray *emlrt_marshallOut(real_T u[3]);

/* Function Definitions */
static real_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[3]
{
  real_T (*y)[3];
  y = c_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}
  static real_T (*c_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[3]
{
  real_T (*ret)[3];
  int32_T iv3[1];
  iv3[0] = 3;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", FALSE, 1U,
    iv3);
  ret = (real_T (*)[3])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static real_T (*emlrt_marshallIn(const mxArray *u, const char_T *identifier))[3]
{
  real_T (*y)[3];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = b_emlrt_marshallIn(emlrtAlias(u), &thisId);
  emlrtDestroyArray(&u);
  return y;
}
  static const mxArray *emlrt_marshallOut(real_T u[3])
{
  const mxArray *y;
  static const int32_T iv1[1] = { 0 };

  const mxArray *m1;
  static const int32_T iv2[1] = { 3 };

  y = NULL;
  m1 = mxCreateNumericArray(1, (int32_T *)&iv1, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m1, (void *)u);
  mxSetDimensions((mxArray *)m1, iv2, 1);
  emlrtAssign(&y, m1);
  return y;
}

void crossARH_api(const mxArray * const prhs[2], const mxArray *plhs[1])
{
  real_T (*w)[3];
  real_T (*u)[3];
  real_T (*v)[3];
  w = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));

  /* Marshall function inputs */
  u = emlrt_marshallIn(emlrtAlias(prhs[0]), "u");
  v = emlrt_marshallIn(emlrtAlias(prhs[1]), "v");

  /* Invoke the target function */
  crossARH(*u, *v, *w);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(*w);
}

const mxArray *emlrtMexFcnResolvedFunctionsInfo(void)
{
  const mxArray *nameCaptureInfo;
  ResolvedFunctionInfo info[1];
  ResolvedFunctionInfo (*b_info)[1];
  ResolvedFunctionInfo u[1];
  const mxArray *y;
  int32_T iv0[1];
  ResolvedFunctionInfo *r0;
  const char * b_u;
  const mxArray *b_y;
  const mxArray *m0;
  const mxArray *c_y;
  const mxArray *d_y;
  const mxArray *e_y;
  uint32_T c_u;
  const mxArray *f_y;
  const mxArray *g_y;
  const mxArray *h_y;
  const mxArray *i_y;
  nameCaptureInfo = NULL;
  b_info = (ResolvedFunctionInfo (*)[1])info;
  (*b_info)[0].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/math/crossARH.m";
  (*b_info)[0].name = "mtimes";
  (*b_info)[0].dominantType = "double";
  (*b_info)[0].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  (*b_info)[0].fileTimeLo = 1289552092U;
  (*b_info)[0].fileTimeHi = 0U;
  (*b_info)[0].mFileTimeLo = 0U;
  (*b_info)[0].mFileTimeHi = 0U;
  u[0] = info[0];
  y = NULL;
  iv0[0] = 1;
  emlrtAssign(&y, mxCreateStructArray(1, iv0, 0, NULL));
  r0 = &u[0];
  b_u = r0->context;
  b_y = NULL;
  m0 = mxCreateString(b_u);
  emlrtAssign(&b_y, m0);
  emlrtAddField(y, b_y, "context", 0);
  b_u = r0->name;
  c_y = NULL;
  m0 = mxCreateString(b_u);
  emlrtAssign(&c_y, m0);
  emlrtAddField(y, c_y, "name", 0);
  b_u = r0->dominantType;
  d_y = NULL;
  m0 = mxCreateString(b_u);
  emlrtAssign(&d_y, m0);
  emlrtAddField(y, d_y, "dominantType", 0);
  b_u = r0->resolved;
  e_y = NULL;
  m0 = mxCreateString(b_u);
  emlrtAssign(&e_y, m0);
  emlrtAddField(y, e_y, "resolved", 0);
  c_u = r0->fileTimeLo;
  f_y = NULL;
  m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
  *(uint32_T *)mxGetData(m0) = c_u;
  emlrtAssign(&f_y, m0);
  emlrtAddField(y, f_y, "fileTimeLo", 0);
  c_u = r0->fileTimeHi;
  g_y = NULL;
  m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
  *(uint32_T *)mxGetData(m0) = c_u;
  emlrtAssign(&g_y, m0);
  emlrtAddField(y, g_y, "fileTimeHi", 0);
  c_u = r0->mFileTimeLo;
  h_y = NULL;
  m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
  *(uint32_T *)mxGetData(m0) = c_u;
  emlrtAssign(&h_y, m0);
  emlrtAddField(y, h_y, "mFileTimeLo", 0);
  c_u = r0->mFileTimeHi;
  i_y = NULL;
  m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
  *(uint32_T *)mxGetData(m0) = c_u;
  emlrtAssign(&i_y, m0);
  emlrtAddField(y, i_y, "mFileTimeHi", 0);
  emlrtAssign(&nameCaptureInfo, y);
  emlrtNameCapturePostProcessR2012a(emlrtAlias(nameCaptureInfo));
  return nameCaptureInfo;
}

/* End of code generation (crossARH_api.c) */
