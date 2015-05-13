/*
 * dotARH.c
 *
 * Code generation for function 'dotARH'
 *
 * C source code generated on: Sun Feb 02 16:40:17 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "dotARH.h"

/* Function Definitions */
real_T dotARH(const real_T v1[3], const real_T v2[3])
{
  real_T dotP;
  int32_T k;

  /* UNTITLED3 Summary of this function goes here */
  /*    Detailed explanation goes here */
  dotP = 0.0;
  for (k = 0; k < 3; k++) {
    dotP += v1[k] * v2[k];
  }

  return dotP;
}

/* End of code generation (dotARH.c) */
