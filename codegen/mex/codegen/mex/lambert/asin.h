/*
 * asin.h
 *
 * Code generation for function 'asin'
 *
 */

#ifndef ASIN_H
#define ASIN_H

/* Include files */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mwmathutil.h"
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include "rtwtypes.h"
#include "lambert_types.h"

/* Function Declarations */
extern void b_asin(const emlrtStack *sp, real_T x[2]);
extern void c_asin(const emlrtStack *sp, real_T *x);

#endif

/* End of code generation (asin.h) */
