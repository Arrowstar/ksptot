/*
 * getStatefromKepler_Alg.c
 *
 * Code generation for function 'getStatefromKepler_Alg'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getStatefromKepler_Alg.h"
#include "error.h"

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = { 31,    /* lineNo */
  "getStatefromKepler_Alg",            /* fcnName */
  "/home/adam/ksptot/ksptot/codegen/mex/getStatefromKepler_Alg/getStatefromKepler_Alg.m"/* pathName */
};

static emlrtRSInfo b_emlrtRSI = { 36,  /* lineNo */
  "getStatefromKepler_Alg",            /* fcnName */
  "/home/adam/ksptot/ksptot/codegen/mex/getStatefromKepler_Alg/getStatefromKepler_Alg.m"/* pathName */
};

static emlrtRSInfo c_emlrtRSI = { 37,  /* lineNo */
  "getStatefromKepler_Alg",            /* fcnName */
  "/home/adam/ksptot/ksptot/codegen/mex/getStatefromKepler_Alg/getStatefromKepler_Alg.m"/* pathName */
};

static emlrtRSInfo d_emlrtRSI = { 40,  /* lineNo */
  "mpower",                            /* fcnName */
  "/usr/local/MATLAB/R2017b/toolbox/eml/lib/matlab/ops/mpower.m"/* pathName */
};

static emlrtRSInfo f_emlrtRSI = { 12,  /* lineNo */
  "sqrt",                              /* fcnName */
  "/usr/local/MATLAB/R2017b/toolbox/eml/lib/matlab/elfun/sqrt.m"/* pathName */
};

/* Function Definitions */
void getStatefromKepler_Alg(const emlrtStack *sp, real_T sma, real_T ecc, real_T
  inc, real_T raan, real_T arg, real_T tru, real_T gmu, real_T rVect[3], real_T
  vVect[3])
{
  real_T p;
  real_T x;
  real_T b_x;
  real_T TransMatrix[9];
  real_T b_p[3];
  real_T dv0[3];
  int32_T i0;
  int32_T i1;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;

  /* getStatefromKepler_Alg Summary of this function goes here */
  /*    Detailed explanation goes here */
  /* %%%%%%%%% */
  /*  Special Case: Circular Equitorial */
  /* %%%%%%%%% */
  if ((ecc < 1.0E-10) && ((inc < 1.0E-10) || (muDoubleScalarAbs(inc -
         3.1415926535897931) < 1.0E-10))) {
    tru += raan + arg;
    raan = 0.0;
    arg = 0.0;
  }

  /* %%%%%%%%% */
  /*  Special Case: Circular Inclined */
  /* %%%%%%%%% */
  if ((ecc < 1.0E-10) && (inc >= 1.0E-10) && (muDoubleScalarAbs(inc -
        3.1415926535897931) >= 1.0E-10)) {
    tru += arg;
    arg = 0.0;
  }

  /* %%%%%%%%% */
  /*  Special Case: Elliptical Equitorial */
  /* %%%%%%%%% */
  if ((ecc >= 1.0E-10) && ((inc < 1.0E-10) || (muDoubleScalarAbs(inc -
         3.1415926535897931) < 1.0E-10))) {
    raan = 0.0;
  }

  st.site = &emlrtRSI;
  b_st.site = &d_emlrtRSI;
  p = sma * (1.0 - ecc * ecc);
  x = gmu / p;
  b_x = gmu / p;
  st.site = &b_emlrtRSI;
  if (x < 0.0) {
    b_st.site = &f_emlrtRSI;
    c_st.site = &f_emlrtRSI;
    error(&c_st);
  }

  st.site = &c_emlrtRSI;
  if (b_x < 0.0) {
    b_st.site = &f_emlrtRSI;
    c_st.site = &f_emlrtRSI;
    error(&c_st);
  }

  TransMatrix[0] = muDoubleScalarCos(raan) * muDoubleScalarCos(arg) -
    muDoubleScalarSin(raan) * muDoubleScalarSin(arg) * muDoubleScalarCos(inc);
  TransMatrix[3] = -muDoubleScalarCos(raan) * muDoubleScalarSin(arg) -
    muDoubleScalarSin(raan) * muDoubleScalarCos(arg) * muDoubleScalarCos(inc);
  TransMatrix[6] = muDoubleScalarSin(raan) * muDoubleScalarSin(inc);
  TransMatrix[1] = muDoubleScalarSin(raan) * muDoubleScalarCos(arg) +
    muDoubleScalarCos(raan) * muDoubleScalarSin(arg) * muDoubleScalarCos(inc);
  TransMatrix[4] = -muDoubleScalarSin(raan) * muDoubleScalarSin(arg) +
    muDoubleScalarCos(raan) * muDoubleScalarCos(arg) * muDoubleScalarCos(inc);
  TransMatrix[7] = -muDoubleScalarCos(raan) * muDoubleScalarSin(inc);
  TransMatrix[2] = muDoubleScalarSin(arg) * muDoubleScalarSin(inc);
  TransMatrix[5] = muDoubleScalarCos(arg) * muDoubleScalarSin(inc);
  TransMatrix[8] = muDoubleScalarCos(inc);
  b_p[0] = p * muDoubleScalarCos(tru) / (1.0 + ecc * muDoubleScalarCos(tru));
  b_p[1] = p * muDoubleScalarSin(tru) / (1.0 + ecc * muDoubleScalarCos(tru));
  b_p[2] = 0.0;
  dv0[0] = -muDoubleScalarSqrt(x) * muDoubleScalarSin(tru);
  dv0[1] = muDoubleScalarSqrt(b_x) * (ecc + muDoubleScalarCos(tru));
  dv0[2] = 0.0;
  for (i0 = 0; i0 < 3; i0++) {
    rVect[i0] = 0.0;
    vVect[i0] = 0.0;
    for (i1 = 0; i1 < 3; i1++) {
      rVect[i0] += TransMatrix[i0 + 3 * i1] * b_p[i1];
      vVect[i0] += TransMatrix[i0 + 3 * i1] * dv0[i1];
    }
  }
}

/* End of code generation (getStatefromKepler_Alg.c) */
