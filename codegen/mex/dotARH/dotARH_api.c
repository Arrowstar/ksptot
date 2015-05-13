/*
 * dotARH_api.c
 *
 * Code generation for function 'dotARH_api'
 *
 * C source code generated on: Sun Feb 02 16:40:17 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "dotARH.h"
#include "dotARH_api.h"

/* Function Declarations */
static real_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[3];
static real_T (*c_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier *
  msgId))[3];
static real_T (*emlrt_marshallIn(const mxArray *v1, const char_T *identifier))[3];
static const mxArray *emlrt_marshallOut(real_T u);
static void info_helper(ResolvedFunctionInfo info[20]);

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
  int32_T iv1[1];
  iv1[0] = 3;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", FALSE, 1U,
    iv1);
  ret = (real_T (*)[3])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static real_T (*emlrt_marshallIn(const mxArray *v1, const char_T *identifier))[3]
{
  real_T (*y)[3];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = b_emlrt_marshallIn(emlrtAlias(v1), &thisId);
  emlrtDestroyArray(&v1);
  return y;
}
  static const mxArray *emlrt_marshallOut(real_T u)
{
  const mxArray *y;
  const mxArray *m1;
  y = NULL;
  m1 = mxCreateDoubleScalar(u);
  emlrtAssign(&y, m1);
  return y;
}

static void info_helper(ResolvedFunctionInfo info[20])
{
  info[0].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/math/dotARH.m";
  info[0].name = "mtimes";
  info[0].dominantType = "double";
  info[0].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[0].fileTimeLo = 1289552092U;
  info[0].fileTimeHi = 0U;
  info[0].mFileTimeLo = 0U;
  info[0].mFileTimeHi = 0U;
  info[1].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[1].name = "eml_index_class";
  info[1].dominantType = "";
  info[1].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[1].fileTimeLo = 1323202978U;
  info[1].fileTimeHi = 0U;
  info[1].mFileTimeLo = 0U;
  info[1].mFileTimeHi = 0U;
  info[2].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[2].name = "eml_scalar_eg";
  info[2].dominantType = "double";
  info[2].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalar_eg.m";
  info[2].fileTimeLo = 1286851196U;
  info[2].fileTimeHi = 0U;
  info[2].mFileTimeLo = 0U;
  info[2].mFileTimeHi = 0U;
  info[3].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[3].name = "eml_xdotu";
  info[3].dominantType = "double";
  info[3].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xdotu.m";
  info[3].fileTimeLo = 1299109172U;
  info[3].fileTimeHi = 0U;
  info[3].mFileTimeLo = 0U;
  info[3].mFileTimeHi = 0U;
  info[4].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xdotu.m";
  info[4].name = "eml_blas_inline";
  info[4].dominantType = "";
  info[4].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_blas_inline.m";
  info[4].fileTimeLo = 1299109168U;
  info[4].fileTimeHi = 0U;
  info[4].mFileTimeLo = 0U;
  info[4].mFileTimeHi = 0U;
  info[5].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xdotu.m";
  info[5].name = "eml_xdot";
  info[5].dominantType = "double";
  info[5].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xdot.m";
  info[5].fileTimeLo = 1299109172U;
  info[5].fileTimeHi = 0U;
  info[5].mFileTimeLo = 0U;
  info[5].mFileTimeHi = 0U;
  info[6].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xdot.m";
  info[6].name = "eml_blas_inline";
  info[6].dominantType = "";
  info[6].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_blas_inline.m";
  info[6].fileTimeLo = 1299109168U;
  info[6].fileTimeHi = 0U;
  info[6].mFileTimeLo = 0U;
  info[6].mFileTimeHi = 0U;
  info[7].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/external/eml_blas_xdot.m";
  info[7].name = "eml_index_class";
  info[7].dominantType = "";
  info[7].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[7].fileTimeLo = 1323202978U;
  info[7].fileTimeHi = 0U;
  info[7].mFileTimeLo = 0U;
  info[7].mFileTimeHi = 0U;
  info[8].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/external/eml_blas_xdot.m";
  info[8].name = "eml_refblas_xdot";
  info[8].dominantType = "double";
  info[8].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdot.m";
  info[8].fileTimeLo = 1299109172U;
  info[8].fileTimeHi = 0U;
  info[8].mFileTimeLo = 0U;
  info[8].mFileTimeHi = 0U;
  info[9].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdot.m";
  info[9].name = "eml_refblas_xdotx";
  info[9].dominantType = "char";
  info[9].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[9].fileTimeLo = 1299109174U;
  info[9].fileTimeHi = 0U;
  info[9].mFileTimeLo = 0U;
  info[9].mFileTimeHi = 0U;
  info[10].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[10].name = "eml_scalar_eg";
  info[10].dominantType = "double";
  info[10].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalar_eg.m";
  info[10].fileTimeLo = 1286851196U;
  info[10].fileTimeHi = 0U;
  info[10].mFileTimeLo = 0U;
  info[10].mFileTimeHi = 0U;
  info[11].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[11].name = "eml_index_class";
  info[11].dominantType = "";
  info[11].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[11].fileTimeLo = 1323202978U;
  info[11].fileTimeHi = 0U;
  info[11].mFileTimeLo = 0U;
  info[11].mFileTimeHi = 0U;
  info[12].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[12].name = "eml_index_minus";
  info[12].dominantType = "double";
  info[12].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_minus.m";
  info[12].fileTimeLo = 1286851178U;
  info[12].fileTimeHi = 0U;
  info[12].mFileTimeLo = 0U;
  info[12].mFileTimeHi = 0U;
  info[13].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_minus.m";
  info[13].name = "eml_index_class";
  info[13].dominantType = "";
  info[13].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[13].fileTimeLo = 1323202978U;
  info[13].fileTimeHi = 0U;
  info[13].mFileTimeLo = 0U;
  info[13].mFileTimeHi = 0U;
  info[14].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[14].name = "eml_index_times";
  info[14].dominantType = "coder.internal.indexInt";
  info[14].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_times.m";
  info[14].fileTimeLo = 1286851180U;
  info[14].fileTimeHi = 0U;
  info[14].mFileTimeLo = 0U;
  info[14].mFileTimeHi = 0U;
  info[15].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_times.m";
  info[15].name = "eml_index_class";
  info[15].dominantType = "";
  info[15].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[15].fileTimeLo = 1323202978U;
  info[15].fileTimeHi = 0U;
  info[15].mFileTimeLo = 0U;
  info[15].mFileTimeHi = 0U;
  info[16].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[16].name = "eml_index_plus";
  info[16].dominantType = "coder.internal.indexInt";
  info[16].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_plus.m";
  info[16].fileTimeLo = 1286851178U;
  info[16].fileTimeHi = 0U;
  info[16].mFileTimeLo = 0U;
  info[16].mFileTimeHi = 0U;
  info[17].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_plus.m";
  info[17].name = "eml_index_class";
  info[17].dominantType = "";
  info[17].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[17].fileTimeLo = 1323202978U;
  info[17].fileTimeHi = 0U;
  info[17].mFileTimeLo = 0U;
  info[17].mFileTimeHi = 0U;
  info[18].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xdotx.m";
  info[18].name = "eml_int_forloop_overflow_check";
  info[18].dominantType = "";
  info[18].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_int_forloop_overflow_check.m";
  info[18].fileTimeLo = 1346542740U;
  info[18].fileTimeHi = 0U;
  info[18].mFileTimeLo = 0U;
  info[18].mFileTimeHi = 0U;
  info[19].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_int_forloop_overflow_check.m!eml_int_forloop_overflow_check_helper";
  info[19].name = "intmax";
  info[19].dominantType = "char";
  info[19].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elmat/intmax.m";
  info[19].fileTimeLo = 1311287716U;
  info[19].fileTimeHi = 0U;
  info[19].mFileTimeLo = 0U;
  info[19].mFileTimeHi = 0U;
}

void dotARH_api(const mxArray * const prhs[2], const mxArray *plhs[1])
{
  real_T (*v1)[3];
  real_T (*v2)[3];
  real_T dotP;

  /* Marshall function inputs */
  v1 = emlrt_marshallIn(emlrtAlias(prhs[0]), "v1");
  v2 = emlrt_marshallIn(emlrtAlias(prhs[1]), "v2");

  /* Invoke the target function */
  dotP = dotARH(*v1, *v2);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(dotP);
}

const mxArray *emlrtMexFcnResolvedFunctionsInfo(void)
{
  const mxArray *nameCaptureInfo;
  ResolvedFunctionInfo info[20];
  ResolvedFunctionInfo u[20];
  int32_T i;
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
  info_helper(info);
  for (i = 0; i < 20; i++) {
    u[i] = info[i];
  }

  y = NULL;
  iv0[0] = 20;
  emlrtAssign(&y, mxCreateStructArray(1, iv0, 0, NULL));
  for (i = 0; i < 20; i++) {
    r0 = &u[i];
    b_u = r0->context;
    b_y = NULL;
    m0 = mxCreateString(b_u);
    emlrtAssign(&b_y, m0);
    emlrtAddField(y, b_y, "context", i);
    b_u = r0->name;
    c_y = NULL;
    m0 = mxCreateString(b_u);
    emlrtAssign(&c_y, m0);
    emlrtAddField(y, c_y, "name", i);
    b_u = r0->dominantType;
    d_y = NULL;
    m0 = mxCreateString(b_u);
    emlrtAssign(&d_y, m0);
    emlrtAddField(y, d_y, "dominantType", i);
    b_u = r0->resolved;
    e_y = NULL;
    m0 = mxCreateString(b_u);
    emlrtAssign(&e_y, m0);
    emlrtAddField(y, e_y, "resolved", i);
    c_u = r0->fileTimeLo;
    f_y = NULL;
    m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
    *(uint32_T *)mxGetData(m0) = c_u;
    emlrtAssign(&f_y, m0);
    emlrtAddField(y, f_y, "fileTimeLo", i);
    c_u = r0->fileTimeHi;
    g_y = NULL;
    m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
    *(uint32_T *)mxGetData(m0) = c_u;
    emlrtAssign(&g_y, m0);
    emlrtAddField(y, g_y, "fileTimeHi", i);
    c_u = r0->mFileTimeLo;
    h_y = NULL;
    m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
    *(uint32_T *)mxGetData(m0) = c_u;
    emlrtAssign(&h_y, m0);
    emlrtAddField(y, h_y, "mFileTimeLo", i);
    c_u = r0->mFileTimeHi;
    i_y = NULL;
    m0 = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
    *(uint32_T *)mxGetData(m0) = c_u;
    emlrtAssign(&i_y, m0);
    emlrtAddField(y, i_y, "mFileTimeHi", i);
  }

  emlrtAssign(&nameCaptureInfo, y);
  emlrtNameCapturePostProcessR2012a(emlrtAlias(nameCaptureInfo));
  return nameCaptureInfo;
}

/* End of code generation (dotARH_api.c) */
