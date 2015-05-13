/*
 * power.h
 *
 * Code generation for function 'power'
 *
 */

#ifndef __POWER_H__
#define __POWER_H__

/* Include files */
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "mwmathutil.h"
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include "blas.h"
#include "rtwtypes.h"
#include "lambert_types.h"

/* Function Declarations */
extern real_T b_power(const emlrtStack *sp, real_T a);

#ifdef __WATCOMC__

#pragma aux b_power value [8087];

#endif

extern void power(const real_T a[2], real_T y[2]);

#endif

/* End of code generation (power.h) */
