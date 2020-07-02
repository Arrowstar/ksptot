/*
 * interp1qr.c
 *
 * Code generation for function 'interp1qr'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "interp1qr.h"
#include "interp1qr_emxutil.h"
#include "eml_int_forloop_overflow_check.h"
#include "scalexpAlloc.h"

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = { 65,    /* lineNo */
  "interp1qr",                         /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pathName */
};

static emlrtRSInfo b_emlrtRSI = { 66,  /* lineNo */
  "interp1qr",                         /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pathName */
};

static emlrtRSInfo c_emlrtRSI = { 67,  /* lineNo */
  "interp1qr",                         /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pathName */
};

static emlrtRSInfo d_emlrtRSI = { 72,  /* lineNo */
  "interp1qr",                         /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pathName */
};

static emlrtRSInfo e_emlrtRSI = { 59,  /* lineNo */
  "histc",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\datafun\\histc.m"/* pathName */
};

static emlrtRSInfo f_emlrtRSI = { 137, /* lineNo */
  "histc",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\datafun\\histc.m"/* pathName */
};

static emlrtRSInfo g_emlrtRSI = { 21,  /* lineNo */
  "eml_int_forloop_overflow_check",    /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\eml\\eml_int_forloop_overflow_check.m"/* pathName */
};

static emlrtRSInfo h_emlrtRSI = { 13,  /* lineNo */
  "max",                               /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\datafun\\max.m"/* pathName */
};

static emlrtRSInfo i_emlrtRSI = { 19,  /* lineNo */
  "minOrMax",                          /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\minOrMax.m"/* pathName */
};

static emlrtRSInfo j_emlrtRSI = { 81,  /* lineNo */
  "minOrMax",                          /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\minOrMax.m"/* pathName */
};

static emlrtRSInfo k_emlrtRSI = { 243, /* lineNo */
  "minOrMax",                          /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\minOrMax.m"/* pathName */
};

static emlrtRSInfo l_emlrtRSI = { 269, /* lineNo */
  "minOrMax",                          /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\minOrMax.m"/* pathName */
};

static emlrtRSInfo m_emlrtRSI = { 13,  /* lineNo */
  "min",                               /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\datafun\\min.m"/* pathName */
};

static emlrtRTEInfo emlrtRTEI = { 1,   /* lineNo */
  15,                                  /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtRTEInfo b_emlrtRTEI = { 19,/* lineNo */
  24,                                  /* colNo */
  "scalexpAllocNoCheck",               /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\scalexpAllocNoCheck.m"/* pName */
};

static emlrtRTEInfo c_emlrtRTEI = { 243,/* lineNo */
  16,                                  /* colNo */
  "minOrMax",                          /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\minOrMax.m"/* pName */
};

static emlrtRTEInfo d_emlrtRTEI = { 81,/* lineNo */
  20,                                  /* colNo */
  "minOrMax",                          /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\minOrMax.m"/* pName */
};

static emlrtRTEInfo e_emlrtRTEI = { 65,/* lineNo */
  4,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtRTEInfo f_emlrtRTEI = { 70,/* lineNo */
  1,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtRTEInfo g_emlrtRTEI = { 71,/* lineNo */
  1,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtECInfo emlrtECI = { -1,    /* nDims */
  70,                                  /* lineNo */
  7,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtECInfo b_emlrtECI = { -1,  /* nDims */
  71,                                  /* lineNo */
  6,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtECInfo c_emlrtECI = { 2,   /* nDims */
  75,                                  /* lineNo */
  37,                                  /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtECInfo d_emlrtECI = { 2,   /* nDims */
  75,                                  /* lineNo */
  20,                                  /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtECInfo e_emlrtECI = { 2,   /* nDims */
  75,                                  /* lineNo */
  6,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtBCInfo emlrtBCI = { -1,    /* iFirst */
  -1,                                  /* iLast */
  78,                                  /* lineNo */
  9,                                   /* colNo */
  "x",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtECInfo f_emlrtECI = { -1,  /* nDims */
  78,                                  /* lineNo */
  4,                                   /* colNo */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m"                                 /* pName */
};

static emlrtRTEInfo i_emlrtRTEI = { 60,/* lineNo */
  15,                                  /* colNo */
  "histc",                             /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\datafun\\histc.m"/* pName */
};

static emlrtRTEInfo j_emlrtRTEI = { 22,/* lineNo */
  19,                                  /* colNo */
  "histc",                             /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\datafun\\histc.m"/* pName */
};

static emlrtRTEInfo k_emlrtRTEI = { 17,/* lineNo */
  19,                                  /* colNo */
  "scalexpAlloc",                      /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\eml\\+coder\\+internal\\scalexpAlloc.m"/* pName */
};

static emlrtRTEInfo l_emlrtRTEI = { 13,/* lineNo */
  15,                                  /* colNo */
  "rdivide",                           /* fName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\ops\\rdivide.m"/* pName */
};

static emlrtBCInfo b_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  70,                                  /* lineNo */
  12,                                  /* colNo */
  "x",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo c_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  71,                                  /* lineNo */
  8,                                   /* colNo */
  "x",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo d_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  71,                                  /* lineNo */
  20,                                  /* colNo */
  "x",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo e_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  75,                                  /* lineNo */
  39,                                  /* colNo */
  "y",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo f_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  75,                                  /* lineNo */
  53,                                  /* colNo */
  "y",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo g_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  75,                                  /* lineNo */
  8,                                   /* colNo */
  "y",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo h_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  78,                                  /* lineNo */
  19,                                  /* colNo */
  "x",                                 /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo i_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  78,                                  /* lineNo */
  4,                                   /* colNo */
  "yi",                                /* aName */
  "interp1qr",                         /* fName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\z_interp1qr\\interp1qr"
  ".m",                                /* pName */
  0                                    /* checkKind */
};

/* Function Definitions */
void interp1qr(const emlrtStack *sp, const emxArray_real_T *x, const
               emxArray_real_T *y, const emxArray_real_T *xi, emxArray_real_T
               *yi)
{
  boolean_T eok;
  emxArray_real_T *dxi;
  uint32_T varargin_1[2];
  int32_T mid_i;
  int32_T low_ip1;
  int32_T nbins;
  int32_T m;
  int32_T exitg1;
  emxArray_real_T *dx;
  int32_T low_i;
  emxArray_real_T *z;
  int32_T high_i;
  uint32_T dxi_idx_0;
  uint32_T b_dxi_idx_0;
  emxArray_real_T *xi_pos;
  uint32_T varargin_2[2];
  boolean_T p;
  boolean_T exitg2;
  emxArray_real_T *r0;
  emxArray_int32_T *r1;
  int32_T b_xi_pos[2];
  int32_T c_xi_pos[2];
  emxArray_real_T *r2;
  emxArray_boolean_T *r3;
  real_T b_x;
  emxArray_boolean_T *r4;
  emxArray_int32_T *r5;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  emlrtStack e_st;
  emlrtStack f_st;
  emlrtStack g_st;
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
  g_st.prev = &f_st;
  g_st.tls = f_st.tls;
  emlrtHeapReferenceStackEnterFcnR2012b(sp);

  /*  Quicker 1D linear interpolation */
  /*  Performs 1D linear interpolation of 'xi' points using 'x' and 'y', */
  /*  resulting in 'yi', following the formula yi = y1 + (y2-y1)/(x2-x1)*(xi-x1). */
  /*  Returns NaN for values of 'xi' out of range of 'x', and when 'xi' is NaN. */
  /*  */
  /*  'x'  is column vector [m x 1], monotonically increasing. */
  /*  'y'  is matrix [m x n], corresponding to 'x'. */
  /*  'xi' is column vector [p x 1], in any order. */
  /*  'yi' is matrix [p x n], corresponding to 'xi'. */
  /*  */
  /*  Copyright (c) 2013 Jose M. Mier */
  /*  */
  /*  Full function description */
  /*  Quicker 1D linear interpolation: 'interp1qr' */
  /*  Performs 1D linear interpolation of 'xi' points using 'x' and 'y', */
  /*  resulting in 'yi', following the formula yi = y1 + (y2-y1)/(x2-x1)*(xi-x1). */
  /*  */
  /*  It has same functionality as built-in MATLAB function 'interp1q' (see */
  /*  MATLAB help for details). */
  /*  */
  /*  It runs at least 3x faster than 'interp1q' and 8x faster than 'interp1', */
  /*  and more than 10x faster as m=length(x) increases (see attached performance */
  /*  graph). */
  /*  */
  /*  As with 'interp1q', this function does no input checking. To work properly */
  /*  user has to be aware of the following: */
  /*   - 'x'  must be a monotonically increasing column vector. */
  /*   - 'y'  must be a column vector or matrix with m=length(x) rows. */
  /*   - 'xi' must be a column vector. */
  /*  */
  /*  As with 'interp1q', if 'y' is a matrix, then the interpolation is performed */
  /*  for each column of 'y', in which case 'yi' is p=length(xi) by n=size(y,2). */
  /*  */
  /*  As with 'interp1q', this function returns NaN for any values of 'xi' that */
  /*  lie outside the coordinates in 'x', and when 'xi' is NaN. */
  /*  */
  /*  This function uses the approach given by Loren Shure (The MathWorks) in */
  /*  http://blogs.mathworks.com/loren/2008/08/25/piecewise-linear-interpolation/ */
  /*   - Uses the function 'histc' to get the 'xi_pos' vector. */
  /*   - Also uses a small trick to rearrange the linear operation, such that */
  /*     yi = y1 + s*(xi-x1), where s = (y2-y1)/(x2-x1), now becomes */
  /*     yi = y1 + t*(y2-y1), where t = (xi-x1)/(x2-x1), which reduces the need */
  /*     for replicating a couple of matrices and the right hand division */
  /*     operation for 't' is simpler than it was for 's' because it takes place */
  /*     only in one dimension (both 'x' and 'xi' are column vectors). */
  /*  */
  /*  Acknowledgements: Nils Oberg, Blake Landry, Marcelo H. Garcia, */
  /*  the University of Illinois (USA), and the University of Cantabria (Spain). */
  /*  */
  /*  Author:   Jose M. Mier */
  /*  Contact:  jmierlo2@illinois.edu */
  /*  Date:     August 2013 */
  /*  Version:  4 */
  /*  */
  /*  Function begins */
  /*  Size of 'x' and 'y' */
  /*  For each 'xi', get the position of the 'x' element bounding it on the left [p x 1] */
  st.site = &emlrtRSI;
  if ((xi->size[0] == 1) || (xi->size[0] != 1)) {
    eok = true;
  } else {
    eok = false;
  }

  if (!eok) {
    emlrtErrorWithMessageIdR2012b(&st, &j_emlrtRTEI,
      "Coder:toolbox:autoDimIncompatibility", 0);
  }

  emxInit_real_T(&st, &dxi, 1, &f_emlrtRTEI, true);
  varargin_1[0] = (uint32_T)xi->size[0];
  mid_i = dxi->size[0];
  dxi->size[0] = (int32_T)varargin_1[0];
  emxEnsureCapacity_real_T(&st, dxi, mid_i, &emlrtRTEI);
  low_ip1 = (int32_T)varargin_1[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    dxi->data[mid_i] = 0.0;
  }

  b_st.site = &e_emlrtRSI;
  nbins = x->size[0];
  if (nbins > 1) {
    c_st.site = &f_emlrtRSI;
    if (nbins > 2147483646) {
      d_st.site = &g_emlrtRSI;
      e_st.site = &g_emlrtRSI;
      check_forloop_overflow_error(&e_st);
    }

    m = 1;
    do {
      exitg1 = 0;
      if (m + 1 <= nbins) {
        if (!(x->data[m] >= x->data[m - 1])) {
          eok = false;
          exitg1 = 1;
        } else {
          m++;
        }
      } else {
        eok = true;
        exitg1 = 1;
      }
    } while (exitg1 == 0);
  } else {
    eok = true;
  }

  if (!eok) {
    emlrtErrorWithMessageIdR2012b(&st, &i_emlrtRTEI,
      "Coder:MATLAB:histc_InvalidInput3", 0);
  }

  nbins = 0;
  for (m = 0; m < xi->size[0]; m++) {
    low_i = 0;
    if ((!(x->size[0] == 0)) && (!muDoubleScalarIsNaN(xi->data[nbins]))) {
      if ((xi->data[nbins] >= x->data[0]) && (xi->data[nbins] < x->data[x->size
           [0] - 1])) {
        low_i = 1;
        low_ip1 = 2;
        high_i = x->size[0];
        while (high_i > low_ip1) {
          mid_i = (low_i >> 1) + (high_i >> 1);
          if (((low_i & 1) == 1) && ((high_i & 1) == 1)) {
            mid_i++;
          }

          if (xi->data[nbins] >= x->data[mid_i - 1]) {
            low_i = mid_i;
            low_ip1 = mid_i + 1;
          } else {
            high_i = mid_i;
          }
        }
      }

      if (xi->data[nbins] == x->data[x->size[0] - 1]) {
        low_i = x->size[0];
      }
    }

    dxi->data[nbins] = low_i;
    nbins++;
  }

  emxInit_real_T(&st, &dx, 1, &g_emlrtRTEI, true);
  emxInit_real_T(&st, &z, 1, &emlrtRTEI, true);
  st.site = &b_emlrtRSI;
  b_st.site = &h_emlrtRSI;
  c_st.site = &i_emlrtRSI;
  d_st.site = &j_emlrtRSI;
  e_st.site = &k_emlrtRSI;
  dxi_idx_0 = (uint32_T)dxi->size[0];
  mid_i = dx->size[0];
  dx->size[0] = (int32_T)dxi_idx_0;
  emxEnsureCapacity_real_T(&e_st, dx, mid_i, &b_emlrtRTEI);
  dxi_idx_0 = (uint32_T)dxi->size[0];
  b_dxi_idx_0 = (uint32_T)dxi->size[0];
  mid_i = z->size[0];
  z->size[0] = (int32_T)b_dxi_idx_0;
  emxEnsureCapacity_real_T(&e_st, z, mid_i, &c_emlrtRTEI);
  if (!dimagree(z, dxi)) {
    emlrtErrorWithMessageIdR2012b(&e_st, &k_emlrtRTEI, "MATLAB:dimagree", 0);
  }

  emxInit_real_T(&e_st, &xi_pos, 1, &e_emlrtRTEI, true);
  b_dxi_idx_0 = (uint32_T)dxi->size[0];
  mid_i = xi_pos->size[0];
  xi_pos->size[0] = (int32_T)b_dxi_idx_0;
  emxEnsureCapacity_real_T(&d_st, xi_pos, mid_i, &d_emlrtRTEI);
  e_st.site = &l_emlrtRSI;
  eok = ((!(1 > dx->size[0])) && (dx->size[0] > 2147483646));
  if (eok) {
    f_st.site = &g_emlrtRSI;
    g_st.site = &g_emlrtRSI;
    check_forloop_overflow_error(&g_st);
  }

  for (m = 0; m + 1 <= (int32_T)dxi_idx_0; m++) {
    xi_pos->data[m] = muDoubleScalarMax(dxi->data[m], 1.0);
  }

  /*  To avoid index=0 when xi < x(1) */
  st.site = &c_emlrtRSI;
  b_st.site = &m_emlrtRSI;
  c_st.site = &i_emlrtRSI;
  d_st.site = &j_emlrtRSI;
  mid_i = dxi->size[0];
  dxi->size[0] = xi_pos->size[0];
  emxEnsureCapacity_real_T(&d_st, dxi, mid_i, &emlrtRTEI);
  low_ip1 = xi_pos->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    dxi->data[mid_i] = xi_pos->data[mid_i];
  }

  e_st.site = &k_emlrtRSI;
  b_dxi_idx_0 = (uint32_T)xi_pos->size[0];
  mid_i = dx->size[0];
  dx->size[0] = (int32_T)b_dxi_idx_0;
  emxEnsureCapacity_real_T(&e_st, dx, mid_i, &b_emlrtRTEI);
  b_dxi_idx_0 = (uint32_T)xi_pos->size[0];
  dxi_idx_0 = (uint32_T)xi_pos->size[0];
  mid_i = z->size[0];
  z->size[0] = (int32_T)dxi_idx_0;
  emxEnsureCapacity_real_T(&e_st, z, mid_i, &c_emlrtRTEI);
  if (!dimagree(z, xi_pos)) {
    emlrtErrorWithMessageIdR2012b(&e_st, &k_emlrtRTEI, "MATLAB:dimagree", 0);
  }

  dxi_idx_0 = (uint32_T)xi_pos->size[0];
  mid_i = xi_pos->size[0];
  xi_pos->size[0] = (int32_T)dxi_idx_0;
  emxEnsureCapacity_real_T(&d_st, xi_pos, mid_i, &d_emlrtRTEI);
  e_st.site = &l_emlrtRSI;
  eok = ((!(1 > dx->size[0])) && (dx->size[0] > 2147483646));
  if (eok) {
    f_st.site = &g_emlrtRSI;
    g_st.site = &g_emlrtRSI;
    check_forloop_overflow_error(&g_st);
  }

  for (m = 0; m + 1 <= (int32_T)b_dxi_idx_0; m++) {
    xi_pos->data[m] = muDoubleScalarMin(dxi->data[m], (real_T)x->size[0] - 1.0);
  }

  /*  To avoid index=m+1 when xi > x(end). */
  /*  't' matrix [p x 1] */
  nbins = x->size[0];
  low_ip1 = xi_pos->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    high_i = (int32_T)xi_pos->data[mid_i];
    if (!((high_i >= 1) && (high_i <= nbins))) {
      emlrtDynamicBoundsCheckR2012b(high_i, 1, nbins, &b_emlrtBCI, sp);
    }
  }

  mid_i = xi->size[0];
  high_i = xi_pos->size[0];
  if (mid_i != high_i) {
    emlrtSizeEqCheck1DR2012b(mid_i, high_i, &emlrtECI, sp);
  }

  mid_i = dxi->size[0];
  dxi->size[0] = xi->size[0];
  emxEnsureCapacity_real_T(sp, dxi, mid_i, &emlrtRTEI);
  low_ip1 = xi->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    dxi->data[mid_i] = xi->data[mid_i] - x->data[(int32_T)xi_pos->data[mid_i] -
      1];
  }

  nbins = x->size[0];
  mid_i = z->size[0];
  z->size[0] = xi_pos->size[0];
  emxEnsureCapacity_real_T(sp, z, mid_i, &emlrtRTEI);
  low_ip1 = xi_pos->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    high_i = (int32_T)((uint32_T)xi_pos->data[mid_i] + 1U);
    if (!((high_i >= 1) && (high_i <= nbins))) {
      emlrtDynamicBoundsCheckR2012b(high_i, 1, nbins, &c_emlrtBCI, sp);
    }

    z->data[mid_i] = x->data[high_i - 1];
  }

  nbins = x->size[0];
  low_ip1 = xi_pos->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    high_i = (int32_T)xi_pos->data[mid_i];
    if (!((high_i >= 1) && (high_i <= nbins))) {
      emlrtDynamicBoundsCheckR2012b(high_i, 1, nbins, &d_emlrtBCI, sp);
    }
  }

  mid_i = xi_pos->size[0];
  high_i = xi_pos->size[0];
  if (mid_i != high_i) {
    emlrtSizeEqCheck1DR2012b(mid_i, high_i, &b_emlrtECI, sp);
  }

  mid_i = dx->size[0];
  dx->size[0] = z->size[0];
  emxEnsureCapacity_real_T(sp, dx, mid_i, &emlrtRTEI);
  low_ip1 = z->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    dx->data[mid_i] = z->data[mid_i] - x->data[(int32_T)xi_pos->data[mid_i] - 1];
  }

  emxFree_real_T(&z);
  st.site = &d_emlrtRSI;
  varargin_1[0] = (uint32_T)dxi->size[0];
  varargin_1[1] = 1U;
  varargin_2[0] = (uint32_T)dx->size[0];
  varargin_2[1] = 1U;
  eok = false;
  p = true;
  m = 0;
  exitg2 = false;
  while ((!exitg2) && (m < 2)) {
    if (!((int32_T)varargin_1[m] == (int32_T)varargin_2[m])) {
      p = false;
      exitg2 = true;
    } else {
      m++;
    }
  }

  if (p) {
    eok = true;
  }

  if (!eok) {
    emlrtErrorWithMessageIdR2012b(&st, &l_emlrtRTEI, "MATLAB:dimagree", 0);
  }

  mid_i = dxi->size[0];
  emxEnsureCapacity_real_T(&st, dxi, mid_i, &emlrtRTEI);
  low_ip1 = dxi->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    dxi->data[mid_i] /= dx->data[mid_i];
  }

  emxFree_real_T(&dx);
  emxInit_real_T1(&st, &r0, 2, &emlrtRTEI, true);

  /*  Get 'yi' */
  nbins = y->size[0];
  low_ip1 = y->size[1];
  mid_i = r0->size[0] * r0->size[1];
  r0->size[0] = xi_pos->size[0];
  r0->size[1] = low_ip1;
  emxEnsureCapacity_real_T1(sp, r0, mid_i, &emlrtRTEI);
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    m = xi_pos->size[0];
    for (high_i = 0; high_i < m; high_i++) {
      low_i = (int32_T)((uint32_T)xi_pos->data[high_i] + 1U);
      if (!((low_i >= 1) && (low_i <= nbins))) {
        emlrtDynamicBoundsCheckR2012b(low_i, 1, nbins, &e_emlrtBCI, sp);
      }

      r0->data[high_i + r0->size[0] * mid_i] = y->data[(low_i + y->size[0] *
        mid_i) - 1];
    }
  }

  nbins = y->size[0];
  low_ip1 = xi_pos->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    high_i = (int32_T)xi_pos->data[mid_i];
    if (!((high_i >= 1) && (high_i <= nbins))) {
      emlrtDynamicBoundsCheckR2012b(high_i, 1, nbins, &f_emlrtBCI, sp);
    }
  }

  emxInit_int32_T(sp, &r1, 1, &emlrtRTEI, true);
  mid_i = y->size[1];
  high_i = y->size[1];
  b_xi_pos[0] = xi_pos->size[0];
  b_xi_pos[1] = mid_i;
  c_xi_pos[0] = xi_pos->size[0];
  c_xi_pos[1] = high_i;
  if ((b_xi_pos[0] != c_xi_pos[0]) || (b_xi_pos[1] != c_xi_pos[1])) {
    emlrtSizeEqCheckNDR2012b(&b_xi_pos[0], &c_xi_pos[0], &c_emlrtECI, sp);
  }

  mid_i = dxi->size[0];
  high_i = y->size[1];
  nbins = y->size[1];
  low_i = r1->size[0];
  r1->size[0] = nbins;
  emxEnsureCapacity_int32_T(sp, r1, low_i, &emlrtRTEI);
  for (low_i = 0; low_i < nbins; low_i++) {
    r1->data[low_i] = 1;
  }

  c_xi_pos[0] = mid_i;
  c_xi_pos[1] = r1->size[0];
  b_xi_pos[0] = xi_pos->size[0];
  b_xi_pos[1] = high_i;
  if ((c_xi_pos[0] != b_xi_pos[0]) || (c_xi_pos[1] != b_xi_pos[1])) {
    emlrtSizeEqCheckNDR2012b(&c_xi_pos[0], &b_xi_pos[0], &d_emlrtECI, sp);
  }

  nbins = y->size[0];
  low_ip1 = xi_pos->size[0];
  emxFree_int32_T(&r1);
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    high_i = (int32_T)xi_pos->data[mid_i];
    if (!((high_i >= 1) && (high_i <= nbins))) {
      emlrtDynamicBoundsCheckR2012b(high_i, 1, nbins, &g_emlrtBCI, sp);
    }
  }

  emxInit_real_T1(sp, &r2, 2, &emlrtRTEI, true);
  low_ip1 = dxi->size[0];
  nbins = y->size[1];
  mid_i = r2->size[0] * r2->size[1];
  r2->size[0] = low_ip1;
  r2->size[1] = nbins;
  emxEnsureCapacity_real_T1(sp, r2, mid_i, &emlrtRTEI);
  for (mid_i = 0; mid_i < nbins; mid_i++) {
    for (high_i = 0; high_i < low_ip1; high_i++) {
      r2->data[high_i + r2->size[0] * mid_i] = dxi->data[high_i] * (r0->
        data[high_i + r0->size[0] * mid_i] - y->data[((int32_T)xi_pos->
        data[high_i] + y->size[0] * mid_i) - 1]);
    }
  }

  emxFree_real_T(&r0);
  emxFree_real_T(&dxi);
  mid_i = y->size[1];
  b_xi_pos[0] = xi_pos->size[0];
  b_xi_pos[1] = mid_i;
  for (mid_i = 0; mid_i < 2; mid_i++) {
    c_xi_pos[mid_i] = r2->size[mid_i];
  }

  if ((b_xi_pos[0] != c_xi_pos[0]) || (b_xi_pos[1] != c_xi_pos[1])) {
    emlrtSizeEqCheckNDR2012b(&b_xi_pos[0], &c_xi_pos[0], &e_emlrtECI, sp);
  }

  low_ip1 = y->size[1];
  mid_i = yi->size[0] * yi->size[1];
  yi->size[0] = xi_pos->size[0];
  yi->size[1] = low_ip1;
  emxEnsureCapacity_real_T1(sp, yi, mid_i, &emlrtRTEI);
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    m = xi_pos->size[0];
    for (high_i = 0; high_i < m; high_i++) {
      yi->data[high_i + yi->size[0] * mid_i] = y->data[((int32_T)xi_pos->
        data[high_i] + y->size[0] * mid_i) - 1] + r2->data[high_i + r2->size[0] *
        mid_i];
    }
  }

  emxFree_real_T(&r2);
  emxFree_real_T(&xi_pos);
  emxInit_boolean_T(sp, &r3, 1, &emlrtRTEI, true);

  /*  Give NaN to the values of 'yi' corresponding to 'xi' out of the range of 'x' */
  mid_i = x->size[0];
  if (!(1 <= mid_i)) {
    emlrtDynamicBoundsCheckR2012b(1, 1, mid_i, &emlrtBCI, sp);
  }

  b_x = x->data[0];
  mid_i = r3->size[0];
  r3->size[0] = xi->size[0];
  emxEnsureCapacity_boolean_T(sp, r3, mid_i, &emlrtRTEI);
  low_ip1 = xi->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    r3->data[mid_i] = (xi->data[mid_i] < b_x);
  }

  emxInit_boolean_T(sp, &r4, 1, &emlrtRTEI, true);
  mid_i = x->size[0];
  high_i = x->size[0];
  if (!((high_i >= 1) && (high_i <= mid_i))) {
    emlrtDynamicBoundsCheckR2012b(high_i, 1, mid_i, &h_emlrtBCI, sp);
  }

  b_x = x->data[high_i - 1];
  mid_i = r4->size[0];
  r4->size[0] = xi->size[0];
  emxEnsureCapacity_boolean_T(sp, r4, mid_i, &emlrtRTEI);
  low_ip1 = xi->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    r4->data[mid_i] = (xi->data[mid_i] > b_x);
  }

  mid_i = r3->size[0];
  high_i = r4->size[0];
  if (mid_i != high_i) {
    emlrtSizeEqCheck1DR2012b(mid_i, high_i, &f_emlrtECI, sp);
  }

  low_i = r3->size[0] - 1;
  nbins = 0;
  for (m = 0; m <= low_i; m++) {
    if (r3->data[m] || r4->data[m]) {
      nbins++;
    }
  }

  emxInit_int32_T(sp, &r5, 1, &emlrtRTEI, true);
  mid_i = r5->size[0];
  r5->size[0] = nbins;
  emxEnsureCapacity_int32_T(sp, r5, mid_i, &emlrtRTEI);
  nbins = 0;
  for (m = 0; m <= low_i; m++) {
    if (r3->data[m] || r4->data[m]) {
      r5->data[nbins] = m + 1;
      nbins++;
    }
  }

  emxFree_boolean_T(&r4);
  emxFree_boolean_T(&r3);
  low_ip1 = yi->size[1];
  nbins = r5->size[0];
  m = yi->size[0];
  for (mid_i = 0; mid_i < low_ip1; mid_i++) {
    for (high_i = 0; high_i < nbins; high_i++) {
      low_i = r5->data[high_i];
      if (!((low_i >= 1) && (low_i <= m))) {
        emlrtDynamicBoundsCheckR2012b(low_i, 1, m, &i_emlrtBCI, sp);
      }

      yi->data[(low_i + yi->size[0] * mid_i) - 1] = rtNaN;
    }
  }

  emxFree_int32_T(&r5);
  emlrtHeapReferenceStackLeaveFcnR2012b(sp);
}

/* End of code generation (interp1qr.c) */
