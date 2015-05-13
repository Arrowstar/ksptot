/*
 * AngleZero2Pi.c
 *
 * Code generation for function 'AngleZero2Pi'
 *
 * C source code generated on: Sun Feb 02 17:27:56 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "AngleZero2Pi.h"
#include "AngleZero2Pi_data.h"

/* Function Definitions */
real_T AngleZero2Pi(real_T Angle)
{
  real_T CorrectedAngle;

  /*  Accepts a radian measure angle and returns that angle between 0 and 2*pi. */
  /*  Angle is a scalar input, measured in radians. */
  if (Angle < 0.0) {
    while (Angle < 0.0) {
      Angle += 6.2831853071795862;
      emlrtBreakCheckFastR2012b(emlrtBreakCheckR2012bFlagVar, emlrtRootTLSGlobal);
    }

    CorrectedAngle = Angle;
  } else if (Angle >= 6.2831853071795862) {
    while (Angle >= 6.2831853071795862) {
      Angle -= 6.2831853071795862;
      emlrtBreakCheckFastR2012b(emlrtBreakCheckR2012bFlagVar, emlrtRootTLSGlobal);
    }

    CorrectedAngle = Angle;
  } else {
    CorrectedAngle = Angle;
  }

  return CorrectedAngle;
}

/* End of code generation (AngleZero2Pi.c) */
