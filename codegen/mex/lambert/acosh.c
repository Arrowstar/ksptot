/*
 * acosh.c
 *
 * Code generation for function 'acosh'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "acosh.h"
#include "eml_error.h"
#include "lambert_data.h"

/* Variable Definitions */
static emlrtRSInfo lb_emlrtRSI = { 14, "acosh",
  "C:\\Program Files\\MATLAB\\R2014b\\toolbox\\eml\\lib\\matlab\\elfun\\acosh.m"
};

static emlrtRSInfo mb_emlrtRSI = { 19, "acosh",
  "C:\\Program Files\\MATLAB\\R2014b\\toolbox\\eml\\lib\\matlab\\elfun\\acosh.m"
};

static emlrtRSInfo nb_emlrtRSI = { 27, "eml_scalar_acosh",
  "C:\\Program Files\\MATLAB\\R2014b\\toolbox\\eml\\lib\\matlab\\elfun\\eml_scalar_acosh.m"
};

/* Function Definitions */
void b_acosh(const emlrtStack *sp, real_T *x)
{
  real_T absz;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  if (*x < 1.0) {
    st.site = &lb_emlrtRSI;
    e_eml_error(&st);
  }

  st.site = &mb_emlrtRSI;
  if (*x < 1.0) {
    *x = rtNaN;
  } else if (*x >= 2.68435456E+8) {
    *x = muDoubleScalarLog(*x) + 0.69314718055994529;
  } else if (*x > 2.0) {
    *x = muDoubleScalarLog(*x + muDoubleScalarSqrt(*x * *x - 1.0));
  } else {
    (*x)--;
    b_st.site = &nb_emlrtRSI;
    absz = 2.0 * *x + *x * *x;
    if (absz < 0.0) {
      c_st.site = &hb_emlrtRSI;
      eml_error(&c_st);
    }

    *x += muDoubleScalarSqrt(absz);
    absz = muDoubleScalarAbs(*x);
    if ((absz > 4.503599627370496E+15) || (!((!muDoubleScalarIsInf(*x)) &&
          (!muDoubleScalarIsNaN(*x))))) {
      *x = muDoubleScalarLog(1.0 + *x);
    } else if (absz < 2.2204460492503131E-16) {
    } else {
      *x = muDoubleScalarLog(1.0 + *x) * (*x / ((1.0 + *x) - 1.0));
    }
  }
}

/* End of code generation (acosh.c) */
