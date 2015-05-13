/*
 * crossARH.c
 *
 * Code generation for function 'crossARH'
 *
 * C source code generated on: Sun Feb 02 16:50:08 2014
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "crossARH.h"

/* Function Definitions */
void crossARH(const real_T u[3], const real_T v[3], real_T w[3])
{
  /* UNTITLED4 Summary of this function goes here */
  /*    Detailed explanation goes here */
  w[0] = u[1] * v[2] - u[2] * v[1];
  w[1] = u[2] * v[0] - u[0] * v[2];
  w[2] = u[0] * v[1] - u[1] * v[0];
}

/* End of code generation (crossARH.c) */
