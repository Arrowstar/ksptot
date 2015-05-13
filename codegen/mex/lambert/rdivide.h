/*
 * rdivide.h
 *
 * Code generation for function 'rdivide'
 *
 */

#ifndef __RDIVIDE_H__
#define __RDIVIDE_H__

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
extern void b_rdivide(real_T x, const real_T y[2], real_T z[2]);
extern real_T rdivide(real_T x, real_T y);

#ifdef __WATCOMC__

#pragma aux rdivide value [8087];

#endif
#endif

/* End of code generation (rdivide.h) */
