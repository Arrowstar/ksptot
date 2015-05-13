/*
 * getStatefromKepler_Alg_api.c
 *
 * Code generation for function 'getStatefromKepler_Alg_api'
 *
 * C source code generated on: Sun Feb 02 17:16:06 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getStatefromKepler_Alg.h"
#include "getStatefromKepler_Alg_api.h"

/* Function Declarations */
static real_T b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId);
static real_T c_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId);
static real_T emlrt_marshallIn(const mxArray *sma, const char_T *identifier);
static const mxArray *emlrt_marshallOut(real_T u[3]);
static void info_helper(ResolvedFunctionInfo info[30]);

/* Function Definitions */
static real_T b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId)
{
  real_T y;
  y = c_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T c_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId)
{
  real_T ret;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", FALSE, 0U, 0);
  ret = *(real_T *)mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static real_T emlrt_marshallIn(const mxArray *sma, const char_T *identifier)
{
  real_T y;
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = b_emlrt_marshallIn(emlrtAlias(sma), &thisId);
  emlrtDestroyArray(&sma);
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

static void info_helper(ResolvedFunctionInfo info[30])
{
  info[0].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[0].name = "abs";
  info[0].dominantType = "double";
  info[0].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/abs.m";
  info[0].fileTimeLo = 1343862766U;
  info[0].fileTimeHi = 0U;
  info[0].mFileTimeLo = 0U;
  info[0].mFileTimeHi = 0U;
  info[1].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/abs.m";
  info[1].name = "eml_scalar_abs";
  info[1].dominantType = "double";
  info[1].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/eml_scalar_abs.m";
  info[1].fileTimeLo = 1286851112U;
  info[1].fileTimeHi = 0U;
  info[1].mFileTimeLo = 0U;
  info[1].mFileTimeHi = 0U;
  info[2].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[2].name = "mpower";
  info[2].dominantType = "double";
  info[2].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mpower.m";
  info[2].fileTimeLo = 1286851242U;
  info[2].fileTimeHi = 0U;
  info[2].mFileTimeLo = 0U;
  info[2].mFileTimeHi = 0U;
  info[3].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mpower.m";
  info[3].name = "power";
  info[3].dominantType = "double";
  info[3].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/power.m";
  info[3].fileTimeLo = 1348224330U;
  info[3].fileTimeHi = 0U;
  info[3].mFileTimeLo = 0U;
  info[3].mFileTimeHi = 0U;
  info[4].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/power.m!fltpower";
  info[4].name = "eml_scalar_eg";
  info[4].dominantType = "double";
  info[4].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalar_eg.m";
  info[4].fileTimeLo = 1286851196U;
  info[4].fileTimeHi = 0U;
  info[4].mFileTimeLo = 0U;
  info[4].mFileTimeHi = 0U;
  info[5].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/power.m!fltpower";
  info[5].name = "eml_scalexp_alloc";
  info[5].dominantType = "double";
  info[5].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalexp_alloc.m";
  info[5].fileTimeLo = 1352457260U;
  info[5].fileTimeHi = 0U;
  info[5].mFileTimeLo = 0U;
  info[5].mFileTimeHi = 0U;
  info[6].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/power.m!fltpower";
  info[6].name = "floor";
  info[6].dominantType = "double";
  info[6].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/floor.m";
  info[6].fileTimeLo = 1343862780U;
  info[6].fileTimeHi = 0U;
  info[6].mFileTimeLo = 0U;
  info[6].mFileTimeHi = 0U;
  info[7].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/floor.m";
  info[7].name = "eml_scalar_floor";
  info[7].dominantType = "double";
  info[7].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/eml_scalar_floor.m";
  info[7].fileTimeLo = 1286851126U;
  info[7].fileTimeHi = 0U;
  info[7].mFileTimeLo = 0U;
  info[7].mFileTimeHi = 0U;
  info[8].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/power.m!scalar_float_power";
  info[8].name = "eml_scalar_eg";
  info[8].dominantType = "double";
  info[8].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalar_eg.m";
  info[8].fileTimeLo = 1286851196U;
  info[8].fileTimeHi = 0U;
  info[8].mFileTimeLo = 0U;
  info[8].mFileTimeHi = 0U;
  info[9].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/power.m!scalar_float_power";
  info[9].name = "mtimes";
  info[9].dominantType = "double";
  info[9].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[9].fileTimeLo = 1289552092U;
  info[9].fileTimeHi = 0U;
  info[9].mFileTimeLo = 0U;
  info[9].mFileTimeHi = 0U;
  info[10].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[10].name = "mtimes";
  info[10].dominantType = "double";
  info[10].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[10].fileTimeLo = 1289552092U;
  info[10].fileTimeHi = 0U;
  info[10].mFileTimeLo = 0U;
  info[10].mFileTimeHi = 0U;
  info[11].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[11].name = "cos";
  info[11].dominantType = "double";
  info[11].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/cos.m";
  info[11].fileTimeLo = 1343862772U;
  info[11].fileTimeHi = 0U;
  info[11].mFileTimeLo = 0U;
  info[11].mFileTimeHi = 0U;
  info[12].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/cos.m";
  info[12].name = "eml_scalar_cos";
  info[12].dominantType = "double";
  info[12].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/eml_scalar_cos.m";
  info[12].fileTimeLo = 1286851122U;
  info[12].fileTimeHi = 0U;
  info[12].mFileTimeLo = 0U;
  info[12].mFileTimeHi = 0U;
  info[13].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[13].name = "mrdivide";
  info[13].dominantType = "double";
  info[13].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mrdivide.p";
  info[13].fileTimeLo = 1357983948U;
  info[13].fileTimeHi = 0U;
  info[13].mFileTimeLo = 1319762366U;
  info[13].mFileTimeHi = 0U;
  info[14].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mrdivide.p";
  info[14].name = "rdivide";
  info[14].dominantType = "double";
  info[14].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/rdivide.m";
  info[14].fileTimeLo = 1346542788U;
  info[14].fileTimeHi = 0U;
  info[14].mFileTimeLo = 0U;
  info[14].mFileTimeHi = 0U;
  info[15].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/rdivide.m";
  info[15].name = "eml_scalexp_compatible";
  info[15].dominantType = "double";
  info[15].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalexp_compatible.m";
  info[15].fileTimeLo = 1286851196U;
  info[15].fileTimeHi = 0U;
  info[15].mFileTimeLo = 0U;
  info[15].mFileTimeHi = 0U;
  info[16].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/rdivide.m";
  info[16].name = "eml_div";
  info[16].dominantType = "double";
  info[16].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_div.m";
  info[16].fileTimeLo = 1313380210U;
  info[16].fileTimeHi = 0U;
  info[16].mFileTimeLo = 0U;
  info[16].mFileTimeHi = 0U;
  info[17].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[17].name = "sin";
  info[17].dominantType = "double";
  info[17].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/sin.m";
  info[17].fileTimeLo = 1343862786U;
  info[17].fileTimeHi = 0U;
  info[17].mFileTimeLo = 0U;
  info[17].mFileTimeHi = 0U;
  info[18].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/sin.m";
  info[18].name = "eml_scalar_sin";
  info[18].dominantType = "double";
  info[18].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/eml_scalar_sin.m";
  info[18].fileTimeLo = 1286851136U;
  info[18].fileTimeHi = 0U;
  info[18].mFileTimeLo = 0U;
  info[18].mFileTimeHi = 0U;
  info[19].context =
    "[E]C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m";
  info[19].name = "sqrt";
  info[19].dominantType = "double";
  info[19].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/sqrt.m";
  info[19].fileTimeLo = 1343862786U;
  info[19].fileTimeHi = 0U;
  info[19].mFileTimeLo = 0U;
  info[19].mFileTimeHi = 0U;
  info[20].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/sqrt.m";
  info[20].name = "eml_error";
  info[20].dominantType = "char";
  info[20].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_error.m";
  info[20].fileTimeLo = 1343862758U;
  info[20].fileTimeHi = 0U;
  info[20].mFileTimeLo = 0U;
  info[20].mFileTimeHi = 0U;
  info[21].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/sqrt.m";
  info[21].name = "eml_scalar_sqrt";
  info[21].dominantType = "double";
  info[21].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/elfun/eml_scalar_sqrt.m";
  info[21].fileTimeLo = 1286851138U;
  info[21].fileTimeHi = 0U;
  info[21].mFileTimeLo = 0U;
  info[21].mFileTimeHi = 0U;
  info[22].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[22].name = "eml_index_class";
  info[22].dominantType = "";
  info[22].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[22].fileTimeLo = 1323202978U;
  info[22].fileTimeHi = 0U;
  info[22].mFileTimeLo = 0U;
  info[22].mFileTimeHi = 0U;
  info[23].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[23].name = "eml_scalar_eg";
  info[23].dominantType = "double";
  info[23].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalar_eg.m";
  info[23].fileTimeLo = 1286851196U;
  info[23].fileTimeHi = 0U;
  info[23].mFileTimeLo = 0U;
  info[23].mFileTimeHi = 0U;
  info[24].context = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[24].name = "eml_xgemm";
  info[24].dominantType = "char";
  info[24].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xgemm.m";
  info[24].fileTimeLo = 1299109172U;
  info[24].fileTimeHi = 0U;
  info[24].mFileTimeLo = 0U;
  info[24].mFileTimeHi = 0U;
  info[25].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_xgemm.m";
  info[25].name = "eml_blas_inline";
  info[25].dominantType = "";
  info[25].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/eml_blas_inline.m";
  info[25].fileTimeLo = 1299109168U;
  info[25].fileTimeHi = 0U;
  info[25].mFileTimeLo = 0U;
  info[25].mFileTimeHi = 0U;
  info[26].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/external/eml_blas_xgemm.m!below_threshold";
  info[26].name = "mtimes";
  info[26].dominantType = "double";
  info[26].resolved = "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/ops/mtimes.m";
  info[26].fileTimeLo = 1289552092U;
  info[26].fileTimeHi = 0U;
  info[26].mFileTimeLo = 0U;
  info[26].mFileTimeHi = 0U;
  info[27].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/external/eml_blas_xgemm.m";
  info[27].name = "eml_index_class";
  info[27].dominantType = "";
  info[27].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_index_class.m";
  info[27].fileTimeLo = 1323202978U;
  info[27].fileTimeHi = 0U;
  info[27].mFileTimeLo = 0U;
  info[27].mFileTimeHi = 0U;
  info[28].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/external/eml_blas_xgemm.m";
  info[28].name = "eml_scalar_eg";
  info[28].dominantType = "double";
  info[28].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/eml_scalar_eg.m";
  info[28].fileTimeLo = 1286851196U;
  info[28].fileTimeHi = 0U;
  info[28].mFileTimeLo = 0U;
  info[28].mFileTimeHi = 0U;
  info[29].context =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/external/eml_blas_xgemm.m";
  info[29].name = "eml_refblas_xgemm";
  info[29].dominantType = "char";
  info[29].resolved =
    "[ILXE]$matlabroot$/toolbox/eml/lib/matlab/eml/blas/refblas/eml_refblas_xgemm.m";
  info[29].fileTimeLo = 1299109174U;
  info[29].fileTimeHi = 0U;
  info[29].mFileTimeLo = 0U;
  info[29].mFileTimeHi = 0U;
}

const mxArray *emlrtMexFcnResolvedFunctionsInfo(void)
{
  const mxArray *nameCaptureInfo;
  ResolvedFunctionInfo info[30];
  ResolvedFunctionInfo u[30];
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
  for (i = 0; i < 30; i++) {
    u[i] = info[i];
  }

  y = NULL;
  iv0[0] = 30;
  emlrtAssign(&y, mxCreateStructArray(1, iv0, 0, NULL));
  for (i = 0; i < 30; i++) {
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

void getStatefromKepler_Alg_api(const mxArray * const prhs[7], const mxArray
  *plhs[2])
{
  real_T (*rVect)[3];
  real_T (*vVect)[3];
  real_T sma;
  real_T ecc;
  real_T inc;
  real_T raan;
  real_T arg;
  real_T tru;
  real_T gmu;
  rVect = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));
  vVect = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));

  /* Marshall function inputs */
  sma = emlrt_marshallIn(emlrtAliasP(prhs[0]), "sma");
  ecc = emlrt_marshallIn(emlrtAliasP(prhs[1]), "ecc");
  inc = emlrt_marshallIn(emlrtAliasP(prhs[2]), "inc");
  raan = emlrt_marshallIn(emlrtAliasP(prhs[3]), "raan");
  arg = emlrt_marshallIn(emlrtAliasP(prhs[4]), "arg");
  tru = emlrt_marshallIn(emlrtAliasP(prhs[5]), "tru");
  gmu = emlrt_marshallIn(emlrtAliasP(prhs[6]), "gmu");

  /* Invoke the target function */
  getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu, *rVect, *vVect);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(*rVect);
  plhs[1] = emlrt_marshallOut(*vVect);
}

/* End of code generation (getStatefromKepler_Alg_api.c) */
