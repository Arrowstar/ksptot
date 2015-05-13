/*
 * lambert.h
 *
 * Code generation for function 'lambert'
 *
 */

#ifndef __LAMBERT_H__
#define __LAMBERT_H__

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
extern void lambert(const emlrtStack *sp, real_T r1vec[3], real_T r2vec[3],
                    real_T tf, real_T m, real_T muC, real_T V1[3], real_T V2[3],
                    real_T extremal_distances[2], real_T *exitflag);

#endif

/* End of code generation (lambert.h) */
