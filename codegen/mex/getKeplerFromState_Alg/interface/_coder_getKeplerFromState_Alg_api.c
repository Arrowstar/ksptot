/*
 * _coder_getKeplerFromState_Alg_api.c
 *
 * Code generation for function '_coder_getKeplerFromState_Alg_api'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "_coder_getKeplerFromState_Alg_api.h"

/* Function Declarations */
static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId))[3];
static real_T c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *gmu, const
  char_T *identifier);
static real_T d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId);
static real_T (*e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
  const emlrtMsgIdentifier *msgId))[3];
static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *rVect,
  const char_T *identifier))[3];
static const mxArray *emlrt_marshallOut(const real_T u);
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
  static real_T c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *gmu,
  const char_T *identifier)
{
  real_T y;
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = d_emlrt_marshallIn(sp, emlrtAlias(gmu), &thisId);
  emlrtDestroyArray(&gmu);
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
  int32_T iv0[1];
  iv0[0] = 3;
  emlrtCheckBuiltInR2012b(sp, msgId, src, "double", false, 1U, iv0);
  ret = (real_T (*)[3])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}
  static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *rVect,
  const char_T *identifier))[3]
{
  real_T (*y)[3];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = identifier;
  thisId.fParent = NULL;
  y = b_emlrt_marshallIn(sp, emlrtAlias(rVect), &thisId);
  emlrtDestroyArray(&rVect);
  return y;
}

static const mxArray *emlrt_marshallOut(const real_T u)
{
  const mxArray *y;
  const mxArray *m0;
  y = NULL;
  m0 = emlrtCreateDoubleScalar(u);
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

void getKeplerFromState_Alg_api(const mxArray * const prhs[3], const mxArray
  *plhs[6])
{
  real_T (*rVect)[3];
  real_T (*vVect)[3];
  real_T gmu;
  real_T tru;
  real_T arg;
  real_T raan;
  real_T inc;
  real_T ecc;
  real_T sma;
  emlrtStack st = { NULL, NULL, NULL };

  st.tls = emlrtRootTLSGlobal;

  /* Marshall function inputs */
  rVect = emlrt_marshallIn(&st, emlrtAlias(prhs[0]), "rVect");
  vVect = emlrt_marshallIn(&st, emlrtAlias(prhs[1]), "vVect");
  gmu = c_emlrt_marshallIn(&st, emlrtAliasP(prhs[2]), "gmu");

  /* Invoke the target function */
  getKeplerFromState_Alg(*rVect, *vVect, gmu, &sma, &ecc, &inc, &raan, &arg,
    &tru);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(sma);
  plhs[1] = emlrt_marshallOut(ecc);
  plhs[2] = emlrt_marshallOut(inc);
  plhs[3] = emlrt_marshallOut(raan);
  plhs[4] = emlrt_marshallOut(arg);
  plhs[5] = emlrt_marshallOut(tru);
}

/* End of code generation (_coder_getKeplerFromState_Alg_api.c) */
