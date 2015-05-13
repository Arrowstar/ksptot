/*
 * getKeplerFromState_Alg.h
 *
 * Code generation for function 'getKeplerFromState_Alg'
 *
 */

#ifndef __GETKEPLERFROMSTATE_ALG_H__
#define __GETKEPLERFROMSTATE_ALG_H__

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
#include "getKeplerFromState_Alg_types.h"

/* Function Declarations */
extern void getKeplerFromState_Alg(const real_T rVect[3], const real_T vVect[3],
  real_T gmu, real_T *sma, real_T *ecc, real_T *inc, real_T *raan, real_T *arg,
  real_T *tru);

#endif

/* End of code generation (getKeplerFromState_Alg.h) */
