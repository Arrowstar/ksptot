/*
 * _coder_lambert_api.c
 *
 * Code generation for function '_coder_lambert_api'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "_coder_lambert_api.h"

/* Function Declarations */
static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId))[3];
static const mxArray *b_emlrt_marshallOut(const real_T u[2]);
static real_T c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *tf, const
  char_T *identifier);
static const mxArray *c_emlrt_marshallOut(const real_T u);
static real_T d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId);
static real_T (*e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
  const emlrtMsgIdentifier *msgId))[3];
static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *r1vec,
  const char_T *identifier))[3];
static const mxArray *emlrt_marshallOut(const real_T u[3]);
static real_T f_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src, const
  emlrtMsgIdentifier *msgId);

/* Function Definitions */
static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId))[3]
{
  real_T (*y)[3];
  y = e_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}
  static const mxArray *b_emlrt_marshallOut(const real_T u[2])
{
  const mxArray *y;
  static const int32_T iv4[2] = { 0, 0 };

  const mxArray *m1;
  static const int32_T iv5[2] = { 1, 2 };

  y = NULL;
  m1 = emlrtCreateNumericArray(2, iv4, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m1, (void *)u);
  emlrtSetDimensions((mxArray *)m1, iv5, 2);
  emlrtAssign(&y, m1);
  return y;
}

static real_T c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *tf, const
  char_T *identifier)
{
  real_T y;
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = d_emlrt_marshallIn(sp, emlrtAlias(tf), &thisId);
  emlrtDestroyArray(&tf);
  return y;
}

static const mxArray *c_emlrt_marshallOut(const real_T u)
{
  const mxArray *y;
  const mxArray *m2;
  y = NULL;
  m2 = emlrtCreateDoubleScalar(u);
  emlrtAssign(&y, m2);
  return y;
}

static real_T d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId)
{
  real_T y;
  y = f_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T (*e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
  const emlrtMsgIdentifier *msgId))[3]
{
  real_T (*ret)[3];
  int32_T iv6[2];
  int32_T i1;
  for (i1 = 0; i1 < 2; i1++) {
    iv6[i1] = 1 + (i1 << 1);
  }

  emlrtCheckBuiltInR2012b(sp, msgId, src, "double", false, 2U, iv6);
  ret = (real_T (*)[3])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}
  static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *r1vec,
  const char_T *identifier))[3]
{
  real_T (*y)[3];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = b_emlrt_marshallIn(sp, emlrtAlias(r1vec), &thisId);
  emlrtDestroyArray(&r1vec);
  return y;
}

static const mxArray *emlrt_marshallOut(const real_T u[3])
{
  const mxArray *y;
  static const int32_T iv2[2] = { 0, 0 };

  const mxArray *m0;
  static const int32_T iv3[2] = { 1, 3 };

  y = NULL;
  m0 = emlrtCreateNumericArray(2, iv2, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m0, (void *)u);
  emlrtSetDimensions((mxArray *)m0, iv3, 2);
  emlrtAssign(&y, m0);
  return y;
}

static real_T f_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src, const
  emlrtMsgIdentifier *msgId)
{
  real_T ret;
  emlrtCheckBuiltInR2012b(sp, msgId, src, "double", false, 0U, 0);
  ret = *(real_T *)mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

void lambert_api(const mxArray *prhs[5], const mxArray *plhs[4])
{
  real_T (*V1)[3];
  real_T (*V2)[3];
  real_T (*extremal_distances)[2];
  real_T (*r1vec)[3];
  real_T (*r2vec)[3];
  real_T tf;
  real_T m;
  real_T muC;
  real_T exitflag;
  emlrtStack st = { NULL, NULL, NULL };

  st.tls = emlrtRootTLSGlobal;
  V1 = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));
  V2 = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));
  extremal_distances = (real_T (*)[2])mxMalloc(sizeof(real_T [2]));
  prhs[0] = emlrtProtectR2012b(prhs[0], 0, false, -1);
  prhs[1] = emlrtProtectR2012b(prhs[1], 1, false, -1);

  /* Marshall function inputs */
  r1vec = emlrt_marshallIn(&st, emlrtAlias(prhs[0]), "r1vec");
  r2vec = emlrt_marshallIn(&st, emlrtAlias(prhs[1]), "r2vec");
  tf = c_emlrt_marshallIn(&st, emlrtAliasP(prhs[2]), "tf");
  m = c_emlrt_marshallIn(&st, emlrtAliasP(prhs[3]), "m");
  muC = c_emlrt_marshallIn(&st, emlrtAliasP(prhs[4]), "muC");

  /* Invoke the target function */
  lambert(&st, *r1vec, *r2vec, tf, m, muC, *V1, *V2, *extremal_distances,
          &exitflag);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(*V1);
  plhs[1] = emlrt_marshallOut(*V2);
  plhs[2] = b_emlrt_marshallOut(*extremal_distances);
  plhs[3] = c_emlrt_marshallOut(exitflag);
}

/* End of code generation (_coder_lambert_api.c) */
