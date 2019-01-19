/*
 * sin.c
 *
 * Code generation for function 'sin'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "sin.h"

/* Function Definitions */
void b_sin(real_T x[2])
{
  int32_T k;
  for (k = 0; k < 2; k++) {
    x[k] = muDoubleScalarSin(x[k]);
  }
}

/* End of code generation (sin.c) */
