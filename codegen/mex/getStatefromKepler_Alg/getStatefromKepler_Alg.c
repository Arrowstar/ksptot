/*
 * getStatefromKepler_Alg.c
 *
 * Code generation for function 'getStatefromKepler_Alg'
 *
 * C source code generated on: Sun Feb 02 17:16:06 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getStatefromKepler_Alg.h"

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = { 35, "getStatefromKepler_Alg",
  "C:/Users/Adam/Dropbox/Documents/homework/Personal Projects/KSP Trajectory Optimization Tool/helper_methods/astrodynamics/getStatefromKepler_Alg.m"
};

static emlrtRSInfo b_emlrtRSI = { 14, "sqrt",
  "C:/Program Files (x86)/MATLAB/R2013a/toolbox/eml/lib/matlab/elfun/sqrt.m" };

static emlrtRSInfo c_emlrtRSI = { 20, "eml_error",
  "C:/Program Files (x86)/MATLAB/R2013a/toolbox/eml/lib/matlab/eml/eml_error.m"
};

static emlrtRTEInfo emlrtRTEI = { 20, 5, "eml_error",
  "C:/Program Files (x86)/MATLAB/R2013a/toolbox/eml/lib/matlab/eml/eml_error.m"
};

/* Function Declarations */
static void eml_error(void);

/* Function Definitions */
static void eml_error(void)
{
  static char_T cv0[4][1] = { { 's' }, { 'q' }, { 'r' }, { 't' } };

  emlrtPushRtStackR2012b(&c_emlrtRSI, emlrtRootTLSGlobal);
  emlrtErrorWithMessageIdR2012b(emlrtRootTLSGlobal, &emlrtRTEI,
    "Coder:toolbox:ElFunDomainError", 3, 4, 4, cv0);
  emlrtPopRtStackR2012b(&c_emlrtRSI, emlrtRootTLSGlobal);
}

void getStatefromKepler_Alg(real_T sma, real_T ecc, real_T inc, real_T raan,
  real_T arg, real_T tru, real_T gmu, real_T rVect[3], real_T vVect[3])
{
  real_T p;
  real_T y;
  real_T b_y;
  real_T TransMatrix[9];
  real_T b_p[3];
  real_T dv0[3];
  int32_T i0;
  int32_T i1;

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
  }

  /* %%%%%%%%% */
  /*  Special Case: Elliptical Equitorial */
  /* %%%%%%%%% */
  if ((ecc >= 1.0E-10) && ((inc < 1.0E-10) || (muDoubleScalarAbs(inc -
         3.1415926535897931) < 1.0E-10))) {
    raan = 0.0;
  }

  p = sma * (1.0 - ecc * ecc);
  emlrtPushRtStackR2012b(&emlrtRSI, emlrtRootTLSGlobal);
  y = gmu / p;
  if (y < 0.0) {
    emlrtPushRtStackR2012b(&b_emlrtRSI, emlrtRootTLSGlobal);
    eml_error();
    emlrtPopRtStackR2012b(&b_emlrtRSI, emlrtRootTLSGlobal);
  }

  b_y = gmu / p;
  if (b_y < 0.0) {
    emlrtPushRtStackR2012b(&b_emlrtRSI, emlrtRootTLSGlobal);
    eml_error();
    emlrtPopRtStackR2012b(&b_emlrtRSI, emlrtRootTLSGlobal);
  }

  emlrtPopRtStackR2012b(&emlrtRSI, emlrtRootTLSGlobal);
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
  dv0[0] = -muDoubleScalarSqrt(y) * muDoubleScalarSin(tru);
  dv0[1] = muDoubleScalarSqrt(b_y) * (ecc + muDoubleScalarCos(tru));
  dv0[2] = 0.0;
  for (i0 = 0; i0 < 3; i0++) {
    rVect[i0] = 0.0;
    for (i1 = 0; i1 < 3; i1++) {
      rVect[i0] += TransMatrix[i0 + 3 * i1] * b_p[i1];
    }

    vVect[i0] = 0.0;
    for (i1 = 0; i1 < 3; i1++) {
      vVect[i0] += TransMatrix[i0 + 3 * i1] * dv0[i1];
    }
  }
}

/* End of code generation (getStatefromKepler_Alg.c) */
