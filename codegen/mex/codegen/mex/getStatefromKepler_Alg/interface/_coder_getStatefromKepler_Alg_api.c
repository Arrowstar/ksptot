/*
 * _coder_getStatefromKepler_Alg_api.c
 *
 * Code generation for function '_coder_getStatefromKepler_Alg_api'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getStatefromKepler_Alg.h"
#include "_coder_getStatefromKepler_Alg_api.h"
#include "getStatefromKepler_Alg_data.h"

/* Function Declarations */
static real_T b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId);
static real_T c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src, const
  emlrtMsgIdentifier *msgId);
static real_T emlrt_marshallIn(const emlrtStack *sp, const mxArray *sma, const
  char_T *identifier);
static const mxArray *emlrt_marshallOut(const real_T u[3]);

/* Function Definitions */
static real_T b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u, const
  emlrtMsgIdentifier *parentId)
{
  real_T y;
  y = c_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src, const
  emlrtMsgIdentifier *msgId)
{
  real_T ret;
  static const int32_T dims = 0;
  emlrtCheckBuiltInR2012b(sp, msgId, src, "double", false, 0U, &dims);
  ret = *(real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static real_T emlrt_marshallIn(const emlrtStack *sp, const mxArray *sma, const
  char_T *identifier)
{
  real_T y;
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = b_emlrt_marshallIn(sp, emlrtAlias(sma), &thisId);
  emlrtDestroyArray(&sma);
  return y;
}

static const mxArray *emlrt_marshallOut(const real_T u[3])
{
  const mxArray *y;
  const mxArray *m0;
  static const int32_T iv0[1] = { 0 };

  static const int32_T iv1[1] = { 3 };

  y = NULL;
  m0 = emlrtCreateNumericArray(1, iv0, mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m0, (void *)&u[0]);
  emlrtSetDimensions((mxArray *)m0, iv1, 1);
  emlrtAssign(&y, m0);
  return y;
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
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  st.tls = emlrtRootTLSGlobal;
  rVect = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));
  vVect = (real_T (*)[3])mxMalloc(sizeof(real_T [3]));

  /* Marshall function inputs */
  sma = emlrt_marshallIn(&st, emlrtAliasP(prhs[0]), "sma");
  ecc = emlrt_marshallIn(&st, emlrtAliasP(prhs[1]), "ecc");
  inc = emlrt_marshallIn(&st, emlrtAliasP(prhs[2]), "inc");
  raan = emlrt_marshallIn(&st, emlrtAliasP(prhs[3]), "raan");
  arg = emlrt_marshallIn(&st, emlrtAliasP(prhs[4]), "arg");
  tru = emlrt_marshallIn(&st, emlrtAliasP(prhs[5]), "tru");
  gmu = emlrt_marshallIn(&st, emlrtAliasP(prhs[6]), "gmu");

  /* Invoke the target function */
  getStatefromKepler_Alg(&st, sma, ecc, inc, raan, arg, tru, gmu, *rVect, *vVect);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(*rVect);
  plhs[1] = emlrt_marshallOut(*vVect);
}

/* End of code generation (_coder_getStatefromKepler_Alg_api.c) */
