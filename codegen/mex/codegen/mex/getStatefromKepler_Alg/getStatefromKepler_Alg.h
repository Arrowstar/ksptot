/*
 * getStatefromKepler_Alg.h
 *
 * Code generation for function 'getStatefromKepler_Alg'
 *
 */

#ifndef GETSTATEFROMKEPLER_ALG_H
#define GETSTATEFROMKEPLER_ALG_H

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
#include "getStatefromKepler_Alg_types.h"

/* Function Declarations */
extern void getStatefromKepler_Alg(const emlrtStack *sp, real_T sma, real_T ecc,
  real_T inc, real_T raan, real_T arg, real_T tru, real_T gmu, real_T rVect[3],
  real_T vVect[3]);

#endif

/* End of code generation (getStatefromKepler_Alg.h) */
