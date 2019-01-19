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
#include "error.h"
#include "lambert_data.h"

/* Variable Definitions */
static emlrtRSInfo sb_emlrtRSI = { 12, /* lineNo */
  "acosh",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\elfun\\acosh.m"/* pathName */
};

static emlrtRSInfo tb_emlrtRSI = { 15, /* lineNo */
  "acosh",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\elfun\\acosh.m"/* pathName */
};

static emlrtRSInfo ub_emlrtRSI = { 15, /* lineNo */
  "applyScalarFunctionInPlace",        /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\applyScalarFunctionInPlace.m"/* pathName */
};

static emlrtRSInfo vb_emlrtRSI = { 8,  /* lineNo */
  "acosh",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\+scalar\\acosh.m"/* pathName */
};

static emlrtRSInfo wb_emlrtRSI = { 35, /* lineNo */
  "acosh",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\+scalar\\acosh.m"/* pathName */
};

/* Function Definitions */
void b_acosh(const emlrtStack *sp, real_T *x)
{
  real_T b_x;
  real_T absz;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  emlrtStack e_st;
  emlrtStack f_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  d_st.prev = &c_st;
  d_st.tls = c_st.tls;
  e_st.prev = &d_st;
  e_st.tls = d_st.tls;
  f_st.prev = &e_st;
  f_st.tls = e_st.tls;
  if (*x < 1.0) {
    st.site = &sb_emlrtRSI;
    b_st.site = &sb_emlrtRSI;
    f_error(&b_st);
  }

  st.site = &tb_emlrtRSI;
  b_st.site = &ub_emlrtRSI;
  c_st.site = &vb_emlrtRSI;
  if (*x < 1.0) {
    *x = rtNaN;
  } else if (*x >= 2.68435456E+8) {
    *x = muDoubleScalarLog(*x) + 0.69314718055994529;
  } else if (*x > 2.0) {
    *x = muDoubleScalarLog(*x + muDoubleScalarSqrt(*x * *x - 1.0));
  } else {
    (*x)--;
    d_st.site = &wb_emlrtRSI;
    b_x = 2.0 * *x + *x * *x;
    if (b_x < 0.0) {
      e_st.site = &lb_emlrtRSI;
      f_st.site = &lb_emlrtRSI;
      error(&f_st);
    }

    b_x = *x + muDoubleScalarSqrt(b_x);
    *x = b_x;
    absz = muDoubleScalarAbs(b_x);
    if ((absz > 4.503599627370496E+15) || (!((!muDoubleScalarIsInf(b_x)) &&
          (!muDoubleScalarIsNaN(b_x))))) {
      *x = muDoubleScalarLog(1.0 + b_x);
    } else {
      if (!(absz < 2.2204460492503131E-16)) {
        *x = muDoubleScalarLog(1.0 + b_x) * (b_x / ((1.0 + b_x) - 1.0));
      }
    }
  }
}

/* End of code generation (acosh.c) */
