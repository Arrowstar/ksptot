/*
 * acos.h
 *
 * Code generation for function 'acos'
 *
 */

#ifndef ACOS_H
#define ACOS_H

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
extern void b_acos(const emlrtStack *sp, real_T *x);
extern void c_acos(const emlrtStack *sp, real_T x[2]);

#endif

/* End of code generation (acos.h) */
