/*
 * lambert.h
 *
 * Code generation for function 'lambert'
 *
 */

#ifndef LAMBERT_H
#define LAMBERT_H

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
extern void an_not_empty_init(void);
extern void lambert(const emlrtStack *sp, real_T r1vec[3], real_T r2vec[3],
                    real_T tf, real_T m, real_T muC, real_T V1[3], real_T V2[3],
                    real_T extremal_distances[2], real_T *exitflag);
extern void sigmax_init(void);

#endif

/* End of code generation (lambert.h) */
