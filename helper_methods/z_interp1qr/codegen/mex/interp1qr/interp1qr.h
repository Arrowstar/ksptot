/*
 * interp1qr.h
 *
 * Code generation for function 'interp1qr'
 *
 */

#ifndef INTERP1QR_H
#define INTERP1QR_H

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
#include "interp1qr_types.h"

/* Function Declarations */
extern void interp1qr(const emlrtStack *sp, const emxArray_real_T *x, const
                      emxArray_real_T *y, const emxArray_real_T *xi,
                      emxArray_real_T *yi);

#endif

/* End of code generation (interp1qr.h) */
