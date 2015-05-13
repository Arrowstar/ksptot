/*
 * eml_error.c
 *
 * Code generation for function 'eml_error'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "eml_error.h"

/* Variable Definitions */
static emlrtRTEInfo emlrtRTEI = { 20, 5, "eml_error",
  "C:\\Program Files\\MATLAB\\R2014b\\toolbox\\eml\\lib\\matlab\\eml\\eml_error.m"
};

/* Function Definitions */
void b_eml_error(const emlrtStack *sp)
{
  static const char_T varargin_1[4] = { 'a', 'c', 'o', 's' };

  emlrtErrorWithMessageIdR2012b(sp, &emlrtRTEI, "Coder:toolbox:ElFunDomainError",
    3, 4, 4, varargin_1);
}

void c_eml_error(const emlrtStack *sp)
{
  static const char_T varargin_1[3] = { 'l', 'o', 'g' };

  emlrtErrorWithMessageIdR2012b(sp, &emlrtRTEI, "Coder:toolbox:ElFunDomainError",
    3, 4, 3, varargin_1);
}

void d_eml_error(const emlrtStack *sp)
{
  static const char_T varargin_1[4] = { 'a', 's', 'i', 'n' };

  emlrtErrorWithMessageIdR2012b(sp, &emlrtRTEI, "Coder:toolbox:ElFunDomainError",
    3, 4, 4, varargin_1);
}

void e_eml_error(const emlrtStack *sp)
{
  static const char_T varargin_1[5] = { 'a', 'c', 'o', 's', 'h' };

  emlrtErrorWithMessageIdR2012b(sp, &emlrtRTEI, "Coder:toolbox:ElFunDomainError",
    3, 4, 5, varargin_1);
}

void eml_error(const emlrtStack *sp)
{
  static const char_T varargin_1[4] = { 's', 'q', 'r', 't' };

  emlrtErrorWithMessageIdR2012b(sp, &emlrtRTEI, "Coder:toolbox:ElFunDomainError",
    3, 4, 4, varargin_1);
}

void f_eml_error(const emlrtStack *sp)
{
  emlrtErrorWithMessageIdR2012b(sp, &emlrtRTEI,
    "Coder:toolbox:power_domainError", 0);
}

/* End of code generation (eml_error.c) */
