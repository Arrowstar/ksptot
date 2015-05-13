/*
 * rdivide.c
 *
 * Code generation for function 'rdivide'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "rdivide.h"

/* Function Definitions */
void b_rdivide(real_T x, const real_T y[2], real_T z[2])
{
  int32_T i0;
  for (i0 = 0; i0 < 2; i0++) {
    z[i0] = x / y[i0];
  }
}

real_T rdivide(real_T x, real_T y)
{
  return x / y;
}

/* End of code generation (rdivide.c) */
