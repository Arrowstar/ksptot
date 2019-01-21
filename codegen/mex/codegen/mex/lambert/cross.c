/*
 * cross.c
 *
 * Code generation for function 'cross'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "cross.h"

/* Function Definitions */
void cross(const real_T a[3], const real_T b[3], real_T c[3])
{
  c[0] = a[1] * b[2] - a[2] * b[1];
  c[1] = a[2] * b[0] - a[0] * b[2];
  c[2] = a[0] * b[1] - a[1] * b[0];
}

/* End of code generation (cross.c) */
