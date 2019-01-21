/*
 * getKeplerFromState_Alg.c
 *
 * Code generation for function 'getKeplerFromState_Alg'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "getKeplerFromState_Alg.h"
#include "acos.h"
#include "norm.h"

/* Function Definitions */
void getKeplerFromState_Alg(const emlrtStack *sp, const real_T rVect[3], const
  real_T vVect[3], real_T gmu, real_T *sma, real_T *ecc, real_T *inc, real_T
  *raan, real_T *arg, real_T *tru)
{
  real_T hVect[3];
  real_T r;
  real_T v;
  real_T nVect[3];
  real_T a;
  real_T dotP;
  int32_T i;
  real_T eVect[3];
  creal_T dc0;
  (void)sp;

  /* getKeplerFromState_Alg Summary of this function goes here */
  /*    Detailed explanation goes here */
  /* UNTITLED4 Summary of this function goes here */
  /*    Detailed explanation goes here */
  hVect[0] = rVect[1] * vVect[2] - rVect[2] * vVect[1];
  hVect[1] = rVect[2] * vVect[0] - rVect[0] * vVect[2];
  hVect[2] = rVect[0] * vVect[1] - rVect[1] * vVect[0];
  r = norm(rVect);
  v = norm(vVect);

  /* UNTITLED4 Summary of this function goes here */
  /*    Detailed explanation goes here */
  nVect[0] = 0.0 * hVect[2] - hVect[1];
  nVect[1] = hVect[0] - 0.0 * hVect[2];
  nVect[2] = 0.0 * hVect[1] - 0.0 * hVect[0];
  a = v * v - gmu / r;

  /* dotARH Summary of this function goes here */
  /*    Detailed explanation goes here */
  dotP = 0.0;
  for (i = 0; i < 3; i++) {
    dotP += rVect[i] * vVect[i];
  }

  for (i = 0; i < 3; i++) {
    eVect[i] = (a * rVect[i] - dotP * vVect[i]) / gmu;
  }

  *ecc = norm(eVect);
  if (*ecc != 1.0) {
    *sma = -gmu / (2.0 * (v * v / 2.0 - gmu / r));

    /*          p = sma*(1-ecc^2); */
  } else {
    *sma = rtInf;

    /*          p = h^2/gmu; */
  }

  dc0.re = hVect[2] / norm(hVect);
  dc0.im = 0.0;
  b_acos(&dc0);
  *inc = dc0.re;
  dc0.re = nVect[0] / norm(nVect);
  dc0.im = 0.0;
  b_acos(&dc0);
  *raan = dc0.re;
  if (nVect[1] < 0.0) {
    *raan = 6.2831853071795862 - dc0.re;
  }

  /* dotARH Summary of this function goes here */
  /*    Detailed explanation goes here */
  dotP = 0.0;
  for (i = 0; i < 3; i++) {
    dotP += nVect[i] * eVect[i];
  }

  dc0.re = dotP / (norm(nVect) * norm(eVect));
  dc0.im = 0.0;
  b_acos(&dc0);
  *arg = dc0.re;
  if (eVect[2] < 0.0) {
    *arg = 6.2831853071795862 - dc0.re;
  }

  /* dotARH Summary of this function goes here */
  /*    Detailed explanation goes here */
  dotP = 0.0;
  for (i = 0; i < 3; i++) {
    dotP += eVect[i] * rVect[i];
  }

  dc0.re = dotP / (norm(eVect) * norm(rVect));
  dc0.im = 0.0;
  b_acos(&dc0);
  *tru = dc0.re;

  /* dotARH Summary of this function goes here */
  /*    Detailed explanation goes here */
  dotP = 0.0;
  for (i = 0; i < 3; i++) {
    dotP += rVect[i] * vVect[i];
  }

  if (dotP < 0.0) {
    *tru = -dc0.re;

    /*          tru = 2*pi - tru; %this is the same thing as far as I can tell! */
  }

  /* %%%%%%%%% */
  /*  Special Case: Elliptical Equitorial */
  /* %%%%%%%%% */
  if ((*ecc >= 1.0E-10) && ((*inc < 1.0E-10) || (muDoubleScalarAbs(*inc -
         3.1415926535897931) < 1.0E-10))) {
    *arg = eVect[0] / norm(eVect);
    if (eVect[1] < 0.0) {
      *arg = 6.2831853071795862 - *arg;
    }

    *raan = 0.0;

    /* these two lines are my convention, hopefully they work */
  }

  /* %%%%%%%%% */
  /*  Special Case: Circular Inclined */
  /* %%%%%%%%% */
  if ((*ecc < 1.0E-10) && (*inc >= 1.0E-10) && (muDoubleScalarAbs(*inc -
        3.1415926535897931) >= 1.0E-10)) {
    /* dotARH Summary of this function goes here */
    /*    Detailed explanation goes here */
    dotP = 0.0;
    for (i = 0; i < 3; i++) {
      dotP += nVect[i] * rVect[i];
    }

    dc0.re = dotP / (norm(nVect) * norm(rVect));
    dc0.im = 0.0;
    b_acos(&dc0);
    *tru = dc0.re;
    if (rVect[2] < 0.0) {
      *tru = 6.2831853071795862 - dc0.re;
    }

    *arg = 0.0;
  }

  /* %%%%%%%%% */
  /*  Special Case: Circular Equitorial */
  /* %%%%%%%%% */
  if ((*ecc < 1.0E-10) && ((*inc < 1.0E-10) || (muDoubleScalarAbs(*inc -
         3.1415926535897931) < 1.0E-10))) {
    dc0.re = rVect[0] / norm(rVect);
    dc0.im = 0.0;
    b_acos(&dc0);
    *tru = dc0.re;
    if (rVect[1] < 0.0) {
      *tru = 6.2831853071795862 - dc0.re;
    }

    *raan = 0.0;
    *arg = 0.0;
  }
}

/* End of code generation (getKeplerFromState_Alg.c) */
