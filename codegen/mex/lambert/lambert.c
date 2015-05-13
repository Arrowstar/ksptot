/*
 * lambert.c
 *
 * Code generation for function 'lambert'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "eml_error.h"
#include "mod.h"
#include "rdivide.h"
#include "power.h"
#include "sqrt.h"
#include "acos.h"
#include "cross.h"
#include "asinh.h"
#include "acosh.h"
#include "sin.h"
#include "asin.h"
#include "log.h"
#include "lambert_data.h"

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = { 169, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo b_emlrtRSI = { 170, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo c_emlrtRSI = { 174, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo d_emlrtRSI = { 176, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo e_emlrtRSI = { 185, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo f_emlrtRSI = { 188, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo g_emlrtRSI = { 192, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo h_emlrtRSI = { 199, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo i_emlrtRSI = { 207, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo j_emlrtRSI = { 208, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo k_emlrtRSI = { 227, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo l_emlrtRSI = { 229, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo m_emlrtRSI = { 232, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo n_emlrtRSI = { 236, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo o_emlrtRSI = { 237, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo p_emlrtRSI = { 260, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo q_emlrtRSI = { 262, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo r_emlrtRSI = { 264, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo s_emlrtRSI = { 265, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo t_emlrtRSI = { 269, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo u_emlrtRSI = { 271, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo v_emlrtRSI = { 274, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo w_emlrtRSI = { 289, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo x_emlrtRSI = { 311, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo y_emlrtRSI = { 313, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ab_emlrtRSI = { 316, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo bb_emlrtRSI = { 318, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo cb_emlrtRSI = { 319, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo db_emlrtRSI = { 322, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo eb_emlrtRSI = { 342, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo fb_emlrtRSI = { 343, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo gb_emlrtRSI = { 359, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ob_emlrtRSI = { 394, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo pb_emlrtRSI = { 395, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo qb_emlrtRSI = { 399, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo rb_emlrtRSI = { 403, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo sb_emlrtRSI = { 414, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo tb_emlrtRSI = { 416, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ub_emlrtRSI = { 417, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo vb_emlrtRSI = { 423, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo wb_emlrtRSI = { 437, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo xb_emlrtRSI = { 438, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo yb_emlrtRSI = { 442, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ac_emlrtRSI = { 444, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo bc_emlrtRSI = { 457, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo cc_emlrtRSI = { 459, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo dc_emlrtRSI = { 471, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ec_emlrtRSI = { 486, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo fc_emlrtRSI = { 496, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo gc_emlrtRSI = { 500, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo hc_emlrtRSI = { 504, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ic_emlrtRSI = { 512, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo jc_emlrtRSI = { 515, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo kc_emlrtRSI = { 519, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo lc_emlrtRSI = { 523, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo mc_emlrtRSI = { 542, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo nc_emlrtRSI = { 559, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo oc_emlrtRSI = { 565, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo pc_emlrtRSI = { 567, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo qc_emlrtRSI = { 591, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo rc_emlrtRSI = { 621, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo sc_emlrtRSI = { 622, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo tc_emlrtRSI = { 634, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo uc_emlrtRSI = { 635, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo vc_emlrtRSI = { 638, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo ad_emlrtRSI = { 37, "mpower",
  "C:\\Program Files\\MATLAB\\R2014b\\toolbox\\eml\\lib\\matlab\\ops\\mpower.m"
};

static emlrtRSInfo bd_emlrtRSI = { 704, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo cd_emlrtRSI = { 721, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

static emlrtRSInfo dd_emlrtRSI = { 722, "lambert",
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\helper_methods\\astrodynamics\\lambert"
  ".m" };

/* Function Declarations */
static real_T LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m);
static void b_LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m, real_T *T, real_T *Tp, real_T *Tpp, real_T *Tppp);
static void c_LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m, real_T *T, real_T *Tp, real_T *Tpp);
static void lambert_LancasterBlanchard(const emlrtStack *sp, const real_T r1vec
  [3], const real_T r2vec[3], real_T tf, real_T m, real_T muC, real_T V1[3],
  real_T V2[3], real_T extremal_distances[2], real_T *exitflag);
static void minmax_distances(const emlrtStack *sp, const real_T r1vec[3], real_T
  r1, const real_T r2vec[3], real_T r2, real_T dth, real_T a, const real_T V1[3],
  const real_T V2[3], real_T m, real_T muC, real_T extremal_distances[2]);
static void sigmax(real_T y, real_T *sig, real_T *dsigdx, real_T *d2sigdx2,
                   real_T *d3sigdx3);

/* Function Definitions */
static real_T LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m)
{
  real_T T;
  real_T E;
  real_T g;
  real_T f;
  real_T z;
  real_T sig1;
  real_T y;
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;

  /*  Lancaster & Blanchard's function, and three derivatives thereof */
  /*  protection against idiotic input */
  if (x < -1.0) {
    /*  impossible; negative eccentricity */
    x = muDoubleScalarAbs(x) - 2.0;
  } else {
    if (x == -1.0) {
      /*  impossible; offset x slightly */
      x = -0.99999999999999978;
    }
  }

  /*  compute parameter E */
  E = x * x - 1.0;

  /*  T(x), T'(x), T''(x) */
  if (x == 1.0) {
    /*  exactly parabolic; solutions known exactly */
    /*  T(x) */
    T = 1.3333333333333333 * (1.0 - muDoubleScalarPower(q, 3.0));

    /*  T'(x) */
    /*  T''(x) */
    /*  T'''(x) */
  } else if (muDoubleScalarAbs(x - 1.0) < 0.01) {
    /*  near-parabolic; compute with series */
    /*  evaluate sigma */
    st.site = &rc_emlrtRSI;
    sigmax(-E, &sig1, &z, &f, &g);
    st.site = &sc_emlrtRSI;
    sigmax(-E * q * q, &z, &f, &g, &y);

    /*  T(x) */
    T = sig1 - muDoubleScalarPower(q, 3.0) * z;

    /*  T'(x) */
    /*  T''(x)         */
    /*  T'''(x) */
  } else {
    /*  all other cases */
    /*  compute all substitution functions */
    st.site = &tc_emlrtRSI;
    y = muDoubleScalarSqrt(muDoubleScalarAbs(E));
    st.site = &uc_emlrtRSI;
    z = 1.0 + q * q * E;
    if (z < 0.0) {
      b_st.site = &hb_emlrtRSI;
      eml_error(&b_st);
    }

    z = muDoubleScalarSqrt(z);
    f = y * (z - q * x);
    g = x * z - q * E;
    st.site = &vc_emlrtRSI;

    /*  T(x) */
    T = 2.0 * ((x - q * z) - ((real_T)(E < 0.0) * (muDoubleScalarAtan2(f, g) +
      3.1415926535897931 * m) + (real_T)(E > 0.0) * muDoubleScalarLog
                (muDoubleScalarMax(0.0, f + g))) / y) / E;

    /*   T'(x) */
    /*  T''(x) */
    /*  T'''(x)  */
  }

  return T;
}

static void b_LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m, real_T *T, real_T *Tp, real_T *Tpp, real_T *Tppp)
{
  real_T E;
  real_T d3sigdx31;
  real_T d2sigdx21;
  real_T y;
  real_T f;
  real_T d3sigdx32;
  real_T d2sigdx22;
  real_T z;
  real_T g;
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;

  /*  Lancaster & Blanchard's function, and three derivatives thereof */
  /*  protection against idiotic input */
  if (x < -1.0) {
    /*  impossible; negative eccentricity */
    x = muDoubleScalarAbs(x) - 2.0;
  } else {
    if (x == -1.0) {
      /*  impossible; offset x slightly */
      x = -0.99999999999999978;
    }
  }

  /*  compute parameter E */
  E = x * x - 1.0;

  /*  T(x), T'(x), T''(x) */
  if (x == 1.0) {
    /*  exactly parabolic; solutions known exactly */
    /*  T(x) */
    *T = 1.3333333333333333 * (1.0 - muDoubleScalarPower(q, 3.0));

    /*  T'(x) */
    *Tp = 0.8 * (muDoubleScalarPower(q, 5.0) - 1.0);

    /*  T''(x) */
    *Tpp = *Tp + 1.7142857142857142 * (1.0 - muDoubleScalarPower(q, 7.0));

    /*  T'''(x) */
    *Tppp = 3.0 * (*Tpp - *Tp) + 2.2222222222222223 * (muDoubleScalarPower(q,
      9.0) - 1.0);
  } else if (muDoubleScalarAbs(x - 1.0) < 0.01) {
    /*  near-parabolic; compute with series */
    /*  evaluate sigma */
    st.site = &rc_emlrtRSI;
    sigmax(-E, &f, &y, &d2sigdx21, &d3sigdx31);
    st.site = &sc_emlrtRSI;
    sigmax(-E * q * q, &g, &z, &d2sigdx22, &d3sigdx32);

    /*  T(x) */
    *T = f - muDoubleScalarPower(q, 3.0) * g;

    /*  T'(x) */
    *Tp = 2.0 * x * (muDoubleScalarPower(q, 5.0) * z - y);

    /*  T''(x)         */
    *Tpp = *Tp / x + 4.0 * (x * x) * (d2sigdx21 - muDoubleScalarPower(q, 7.0) *
      d2sigdx22);

    /*  T'''(x) */
    *Tppp = 3.0 * (*Tpp - *Tp / x) / x + 8.0 * x * x * (muDoubleScalarPower(q,
      9.0) * d3sigdx32 - d3sigdx31);
  } else {
    /*  all other cases */
    /*  compute all substitution functions */
    st.site = &tc_emlrtRSI;
    y = muDoubleScalarSqrt(muDoubleScalarAbs(E));
    st.site = &uc_emlrtRSI;
    f = 1.0 + q * q * E;
    if (f < 0.0) {
      b_st.site = &hb_emlrtRSI;
      eml_error(&b_st);
    }

    z = muDoubleScalarSqrt(f);
    f = y * (z - q * x);
    g = x * z - q * E;
    st.site = &vc_emlrtRSI;

    /*  T(x) */
    *T = 2.0 * ((x - q * z) - ((real_T)(E < 0.0) * (muDoubleScalarAtan2(f, g) +
      3.1415926535897931 * m) + (real_T)(E > 0.0) * muDoubleScalarLog
      (muDoubleScalarMax(0.0, f + g))) / y) / E;

    /*   T'(x) */
    *Tp = ((4.0 - 4.0 * muDoubleScalarPower(q, 3.0) * x / z) - 3.0 * x * *T) / E;

    /*  T''(x) */
    *Tpp = ((-4.0 * muDoubleScalarPower(q, 3.0) / z * (1.0 - q * q * (x * x) /
              (z * z)) - 3.0 * *T) - 3.0 * x * *Tp) / E;

    /*  T'''(x)  */
    *Tppp = ((4.0 * muDoubleScalarPower(q, 3.0) / (z * z) * ((1.0 - q * q * (x *
      x) / (z * z)) + 2.0 * (q * q) * x / (z * z) * (z - x)) - 8.0 * *Tp) - 7.0 *
             x * *Tpp) / E;
  }
}

static void c_LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m, real_T *T, real_T *Tp, real_T *Tpp)
{
  real_T E;
  real_T f;
  real_T d2sigdx21;
  real_T dsigdx1;
  real_T y;
  real_T g;
  real_T d2sigdx22;
  real_T z;
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;

  /*  Lancaster & Blanchard's function, and three derivatives thereof */
  /*  protection against idiotic input */
  if (x < -1.0) {
    /*  impossible; negative eccentricity */
    x = muDoubleScalarAbs(x) - 2.0;
  } else {
    if (x == -1.0) {
      /*  impossible; offset x slightly */
      x = -0.99999999999999978;
    }
  }

  /*  compute parameter E */
  E = x * x - 1.0;

  /*  T(x), T'(x), T''(x) */
  if (x == 1.0) {
    /*  exactly parabolic; solutions known exactly */
    /*  T(x) */
    *T = 1.3333333333333333 * (1.0 - muDoubleScalarPower(q, 3.0));

    /*  T'(x) */
    *Tp = 0.8 * (muDoubleScalarPower(q, 5.0) - 1.0);

    /*  T''(x) */
    *Tpp = *Tp + 1.7142857142857142 * (1.0 - muDoubleScalarPower(q, 7.0));

    /*  T'''(x) */
  } else if (muDoubleScalarAbs(x - 1.0) < 0.01) {
    /*  near-parabolic; compute with series */
    /*  evaluate sigma */
    st.site = &rc_emlrtRSI;
    sigmax(-E, &y, &dsigdx1, &d2sigdx21, &f);
    st.site = &sc_emlrtRSI;
    sigmax(-E * q * q, &f, &z, &d2sigdx22, &g);

    /*  T(x) */
    *T = y - muDoubleScalarPower(q, 3.0) * f;

    /*  T'(x) */
    *Tp = 2.0 * x * (muDoubleScalarPower(q, 5.0) * z - dsigdx1);

    /*  T''(x)         */
    *Tpp = *Tp / x + 4.0 * (x * x) * (d2sigdx21 - muDoubleScalarPower(q, 7.0) *
      d2sigdx22);

    /*  T'''(x) */
  } else {
    /*  all other cases */
    /*  compute all substitution functions */
    st.site = &tc_emlrtRSI;
    y = muDoubleScalarSqrt(muDoubleScalarAbs(E));
    st.site = &uc_emlrtRSI;
    f = 1.0 + q * q * E;
    if (f < 0.0) {
      b_st.site = &hb_emlrtRSI;
      eml_error(&b_st);
    }

    z = muDoubleScalarSqrt(f);
    f = y * (z - q * x);
    g = x * z - q * E;
    st.site = &vc_emlrtRSI;

    /*  T(x) */
    *T = 2.0 * ((x - q * z) - ((real_T)(E < 0.0) * (muDoubleScalarAtan2(f, g) +
      3.1415926535897931 * m) + (real_T)(E > 0.0) * muDoubleScalarLog
      (muDoubleScalarMax(0.0, f + g))) / y) / E;

    /*   T'(x) */
    *Tp = ((4.0 - 4.0 * muDoubleScalarPower(q, 3.0) * x / z) - 3.0 * x * *T) / E;

    /*  T''(x) */
    *Tpp = ((-4.0 * muDoubleScalarPower(q, 3.0) / z * (1.0 - q * q * (x * x) /
              (z * z)) - 3.0 * *T) - 3.0 * x * *Tp) / E;

    /*  T'''(x)  */
  }
}

static void lambert_LancasterBlanchard(const emlrtStack *sp, const real_T r1vec
  [3], const real_T r2vec[3], real_T tf, real_T m, real_T muC, real_T V1[3],
  real_T V2[3], real_T extremal_distances[2], real_T *exitflag)
{
  real_T r1;
  int32_T iterations;
  real_T r2;
  real_T crsprod[3];
  real_T mcrsprd;
  real_T r1unit[3];
  real_T r2unit[3];
  real_T b_crsprod[3];
  real_T c_crsprod[3];
  real_T th1unit[3];
  real_T dth;
  real_T leftbranch;
  real_T c;
  real_T s;
  real_T T;
  real_T q;
  real_T T0;
  real_T Td;
  real_T phr;
  boolean_T guard1 = false;
  real_T x01;
  real_T W;
  real_T TmTM;
  real_T xM0;
  real_T Tp;
  int32_T exitg2;
  real_T Vr1;
  int32_T exitg1;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  d_st.prev = &c_st;
  d_st.tls = c_st.tls;

  /*  ----------------------------------------------------------------- */
  /*  Lancaster & Blanchard version, with improvements by Gooding */
  /*  Very reliable, moderately fast for both simple and complicated cases */
  /*  ----------------------------------------------------------------- */
  /* { */
  /* LAMBERT_LANCASTERBLANCHARD       High-Thrust Lambert-targeter */
  /*  */
  /* lambert_LancasterBlanchard() uses the method developed by  */
  /* Lancaster & Blancard, as described in their 1969 paper. Initial values,  */
  /* and several details of the procedure, are provided by R.H. Gooding,  */
  /* as described in his 1990 paper.  */
  /* } */
  /*  Please report bugs and inquiries to:  */
  /*  */
  /*  Name       : Rody P.S. Oldenhuis */
  /*  E-mail     : oldenhuis@gmail.com    (personal) */
  /*               oldenhuis@luxspace.lu  (professional) */
  /*  Affiliation: LuxSpace s�rl */
  /*  Licence    : BSD */
  /*  If you find this work useful, please consider a donation: */
  /*  https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6G3S5UYM7HJ3N */
  /*  ADJUSTED FOR EML-COMPILATION 29/Sep/2009 */
  /*  manipulate input */
  /*  optimum for numerical noise v.s. actual precision */
  r1 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r1 += r1vec[iterations] * r1vec[iterations];
  }

  st.site = &ob_emlrtRSI;
  b_sqrt(&st, &r1);

  /*  magnitude of r1vec */
  r2 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r2 += r2vec[iterations] * r2vec[iterations];
  }

  st.site = &pb_emlrtRSI;
  b_sqrt(&st, &r2);

  /*  magnitude of r2vec     */
  /*  unit vector of r2vec */
  cross(r1vec, r2vec, crsprod);

  /*  cross product of r1vec and r2vec */
  mcrsprd = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r1unit[iterations] = r1vec[iterations] / r1;

    /*  unit vector of r1vec         */
    r2unit[iterations] = r2vec[iterations] / r2;
    mcrsprd += crsprod[iterations] * crsprod[iterations];
  }

  st.site = &qb_emlrtRSI;
  b_sqrt(&st, &mcrsprd);

  /*  magnitude of that cross product */
  for (iterations = 0; iterations < 3; iterations++) {
    b_crsprod[iterations] = crsprod[iterations] / mcrsprd;
    c_crsprod[iterations] = crsprod[iterations] / mcrsprd;
  }

  b_cross(b_crsprod, r1unit, th1unit);

  /*  unit vectors in the tangential-directions */
  b_cross(c_crsprod, r2unit, crsprod);

  /*  make 100.4% sure it's in (-1 <= x <= +1) */
  mcrsprd = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    mcrsprd += r1vec[iterations] * r2vec[iterations];
  }

  dth = muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, mcrsprd / r1 / r2));
  st.site = &rb_emlrtRSI;
  b_acos(&st, &dth);

  /*  turn angle */
  /*  if the long way was selected, the turn-angle must be negative */
  /*  to take care of the direction of final velocity */
  mcrsprd = muDoubleScalarSign(tf);
  tf = muDoubleScalarAbs(tf);
  if (mcrsprd < 0.0) {
    dth -= 6.2831853071795862;
  }

  /*  left-branch */
  leftbranch = muDoubleScalarSign(m);
  m = muDoubleScalarAbs(m);

  /*  define constants */
  c = (r1 * r1 + r2 * r2) - 2.0 * r1 * r2 * muDoubleScalarCos(dth);
  st.site = &sb_emlrtRSI;
  b_sqrt(&st, &c);
  s = ((r1 + r2) + c) / 2.0;
  mcrsprd = 8.0 * muC / muDoubleScalarPower(s, 3.0);
  st.site = &tb_emlrtRSI;
  b_sqrt(&st, &mcrsprd);
  T = mcrsprd * tf;
  mcrsprd = r1 * r2;
  st.site = &ub_emlrtRSI;
  b_sqrt(&st, &mcrsprd);
  q = mcrsprd / s * muDoubleScalarCos(dth / 2.0);

  /*  general formulae for the initial values (Gooding) */
  /*  ------------------------------------------------- */
  /*  some initial values */
  st.site = &vb_emlrtRSI;
  T0 = LancasterBlanchard(&st, 0.0, q, m);
  Td = T0 - T;
  phr = b_mod(2.0 * muDoubleScalarAtan2(1.0 - q * q, 2.0 * q),
              6.2831853071795862);

  /*  initial output is pessimistic */
  for (iterations = 0; iterations < 3; iterations++) {
    V1[iterations] = rtNaN;
    V2[iterations] = rtNaN;
  }

  for (iterations = 0; iterations < 2; iterations++) {
    extremal_distances[iterations] = rtNaN;
  }

  /*  single-revolution case */
  guard1 = false;
  if (m == 0.0) {
    if (Td > 0.0) {
      leftbranch = T0 * Td / 4.0 / T;
    } else {
      x01 = Td / (4.0 - Td);
      mcrsprd = -Td / (T + T0 / 2.0);
      st.site = &wb_emlrtRSI;
      b_sqrt(&st, &mcrsprd);
      st.site = &xb_emlrtRSI;
      if (2.0 - phr / 3.1415926535897931 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      W = x01 + 1.7 * muDoubleScalarSqrt(2.0 - phr / 3.1415926535897931);
      if (W >= 0.0) {
        TmTM = x01;
      } else {
        st.site = &yb_emlrtRSI;
        TmTM = x01 + b_power(&st, -W) * (-mcrsprd - x01);
      }

      st.site = &ac_emlrtRSI;
      if (1.0 + x01 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      leftbranch = ((1.0 + TmTM * (1.0 + x01) / 2.0) - 0.03 * (TmTM * TmTM) *
                    muDoubleScalarSqrt(1.0 + x01)) * TmTM;
    }

    /*  this estimate might not give a solution */
    if (leftbranch < -1.0) {
      *exitflag = -1.0;
    } else {
      /*  multi-revolution case */
      guard1 = true;
    }
  } else {
    /*  determine minimum Tp(x) */
    mcrsprd = 4.0 / (9.42477796076938 * (2.0 * m + 1.0));
    if (phr < 3.1415926535897931) {
      x01 = phr / 3.1415926535897931;
      st.site = &bc_emlrtRSI;
      b_st.site = &ad_emlrtRSI;
      c_st.site = &xc_emlrtRSI;
      if (x01 < 0.0) {
        d_st.site = &yc_emlrtRSI;
        f_eml_error(&d_st);
      }

      xM0 = mcrsprd * muDoubleScalarPower(x01, 0.125);
    } else if (phr > 3.1415926535897931) {
      st.site = &cc_emlrtRSI;
      b_st.site = &ad_emlrtRSI;
      c_st.site = &xc_emlrtRSI;
      if (2.0 - phr / 3.1415926535897931 < 0.0) {
        d_st.site = &yc_emlrtRSI;
        f_eml_error(&d_st);
      }

      xM0 = mcrsprd * (2.0 - muDoubleScalarPower(2.0 - phr / 3.1415926535897931,
        0.125));

      /*  EMLMEX requires this one */
    } else {
      xM0 = 0.0;
    }

    /*  use Halley's method */
    Tp = rtInf;
    iterations = 0;
    do {
      exitg2 = 0;
      if (muDoubleScalarAbs(Tp) > 1.0E-12) {
        /*  iterations */
        iterations++;

        /*  compute first three derivatives */
        st.site = &dc_emlrtRSI;
        b_LancasterBlanchard(&st, xM0, q, m, &Vr1, &Tp, &W, &x01);

        /*  new value of xM */
        mcrsprd = xM0;
        xM0 -= rdivide(2.0 * Tp * W, 2.0 * (W * W) - Tp * x01);

        /*  escape clause */
        if (b_mod(iterations, 7.0) != 0.0) {
          xM0 = (mcrsprd + xM0) / 2.0;
        }

        /*  the method might fail. Exit in that case */
        emlrtBreakCheckFastR2012b(emlrtBreakCheckR2012bFlagVar, sp);
        if (iterations > 25) {
          *exitflag = -2.0;
          exitg2 = 1;
        }
      } else {
        /*  xM should be elliptic (-1 < x < 1) */
        /*  (this should be impossible to go wrong) */
        exitg2 = 2;
      }
    } while (exitg2 == 0);

    if (exitg2 == 1) {
    } else if ((xM0 < -1.0) || (xM0 > 1.0)) {
      *exitflag = -1.0;
    } else {
      /*  corresponding time */
      st.site = &ec_emlrtRSI;
      mcrsprd = LancasterBlanchard(&st, xM0, q, m);

      /*  T should lie above the minimum T */
      if (mcrsprd > T) {
        *exitflag = -1.0;
      } else {
        /*  find two initial values for second solution (again with lambda-type patch) */
        /*  -------------------------------------------------------------------------- */
        /*  some initial values */
        TmTM = T - mcrsprd;
        st.site = &fc_emlrtRSI;
        c_LancasterBlanchard(&st, xM0, q, m, &Vr1, &Tp, &W);

        /*  first estimate (only if m > 0) */
        if (leftbranch > 0.0) {
          x01 = TmTM / (W / 2.0 + TmTM / ((1.0 - xM0) * (1.0 - xM0)));
          st.site = &gc_emlrtRSI;
          if (x01 < 0.0) {
            b_st.site = &hb_emlrtRSI;
            eml_error(&b_st);
          }

          leftbranch = muDoubleScalarSqrt(x01);
          W = xM0 + leftbranch;
          W = 4.0 * W / (4.0 + TmTM) + (1.0 - W) * (1.0 - W);
          st.site = &hc_emlrtRSI;
          if (W < 0.0) {
            b_st.site = &hb_emlrtRSI;
            eml_error(&b_st);
          }

          leftbranch = leftbranch * (1.0 - ((1.0 + m) + (dth - 0.5)) / (1.0 +
            0.15 * m) * leftbranch * (W / 2.0 + 0.03 * leftbranch *
            muDoubleScalarSqrt(W))) + xM0;

          /*  first estimate might not be able to yield possible solution */
          if (leftbranch > 1.0) {
            *exitflag = -1.0;
          } else {
            /*  second estimate (only if m > 0) */
            guard1 = true;
          }
        } else {
          if (Td > 0.0) {
            x01 = mcrsprd / (W / 2.0 - TmTM * (W / 2.0 / (T0 - mcrsprd) - 1.0 /
                              (xM0 * xM0)));
            st.site = &ic_emlrtRSI;
            if (x01 < 0.0) {
              b_st.site = &hb_emlrtRSI;
              eml_error(&b_st);
            }

            leftbranch = xM0 - muDoubleScalarSqrt(x01);
          } else {
            TmTM = Td / (4.0 - Td);
            st.site = &jc_emlrtRSI;
            x01 = 2.0 * (1.0 - phr);
            if (x01 < 0.0) {
              b_st.site = &hb_emlrtRSI;
              eml_error(&b_st);
            }

            W = TmTM + 1.7 * muDoubleScalarSqrt(x01);
            if (W >= 0.0) {
            } else {
              st.site = &kc_emlrtRSI;
              b_st.site = &ad_emlrtRSI;
              c_st.site = &xc_emlrtRSI;
              x01 = muDoubleScalarPower(-W, 0.125);
              mcrsprd = -Td / (1.5 * T0 - Td);
              st.site = &kc_emlrtRSI;
              if (x01 < 0.0) {
                b_st.site = &hb_emlrtRSI;
                eml_error(&b_st);
              }

              st.site = &kc_emlrtRSI;
              if (mcrsprd < 0.0) {
                b_st.site = &hb_emlrtRSI;
                eml_error(&b_st);
              }

              TmTM -= muDoubleScalarSqrt(x01) * (TmTM + muDoubleScalarSqrt
                (mcrsprd));
            }

            W = 4.0 / (4.0 - Td);
            st.site = &lc_emlrtRSI;
            leftbranch = TmTM * (1.0 + ((1.0 + m) + 0.24 * (dth - 0.5)) / (1.0 +
              0.15 * m) * TmTM * (W / 2.0 - 0.03 * TmTM * muDoubleScalarSqrt(W)));
          }

          /*  estimate might not give solutions */
          if (leftbranch < -1.0) {
            *exitflag = -1.0;
          } else {
            guard1 = true;
          }
        }
      }
    }
  }

  if (guard1) {
    /*  find root of Lancaster & Blancard's function */
    /*  -------------------------------------------- */
    /*  (Halley's method)     */
    mcrsprd = rtInf;
    iterations = 0;
    do {
      exitg1 = 0;
      if (muDoubleScalarAbs(mcrsprd) > 1.0E-12) {
        /*  iterations */
        iterations++;

        /*  compute function value, and first two derivatives */
        st.site = &mc_emlrtRSI;
        c_LancasterBlanchard(&st, leftbranch, q, m, &mcrsprd, &Tp, &W);

        /*  find the root of the *difference* between the */
        /*  function value [T_x] and the required time [T] */
        mcrsprd -= T;

        /*  new value of x */
        x01 = leftbranch;
        leftbranch -= rdivide(2.0 * mcrsprd * Tp, 2.0 * (Tp * Tp) - mcrsprd * W);

        /*  escape clause */
        if (b_mod(iterations, 7.0) != 0.0) {
          leftbranch = (x01 + leftbranch) / 2.0;
        }

        /*  Halley's method might fail */
        emlrtBreakCheckFastR2012b(emlrtBreakCheckR2012bFlagVar, sp);
        if (iterations > 25) {
          *exitflag = -2.0;
          exitg1 = 1;
        }
      } else {
        /*  calculate terminal velocities */
        /*  ----------------------------- */
        /*  constants required for this calculation */
        x01 = muC * s / 2.0;
        st.site = &nc_emlrtRSI;
        if (x01 < 0.0) {
          b_st.site = &hb_emlrtRSI;
          eml_error(&b_st);
        }

        xM0 = muDoubleScalarSqrt(x01);
        if (c == 0.0) {
          Tp = 1.0;
          mcrsprd = 0.0;
          x01 = muDoubleScalarAbs(leftbranch);
        } else {
          x01 = r1 * r2 / (c * c);
          st.site = &oc_emlrtRSI;
          if (x01 < 0.0) {
            b_st.site = &hb_emlrtRSI;
            eml_error(&b_st);
          }

          Tp = 2.0 * muDoubleScalarSqrt(x01) * muDoubleScalarSin(dth / 2.0);
          mcrsprd = (r1 - r2) / c;
          st.site = &pc_emlrtRSI;
          x01 = 1.0 + q * q * (leftbranch * leftbranch - 1.0);
          if (x01 < 0.0) {
            b_st.site = &hb_emlrtRSI;
            eml_error(&b_st);
          }

          x01 = muDoubleScalarSqrt(x01);
        }

        /*  radial component */
        Vr1 = xM0 * ((q * x01 - leftbranch) - mcrsprd * (q * x01 + leftbranch)) /
          r1;
        TmTM = -xM0 * ((q * x01 - leftbranch) + mcrsprd * (q * x01 + leftbranch))
          / r2;

        /*  tangential component */
        W = Tp * xM0 * (x01 + q * leftbranch) / r1;
        mcrsprd = Tp * xM0 * (x01 + q * leftbranch) / r2;

        /*  Cartesian velocity */
        for (iterations = 0; iterations < 3; iterations++) {
          V1[iterations] = W * th1unit[iterations] + Vr1 * r1unit[iterations];
          V2[iterations] = mcrsprd * crsprod[iterations] + TmTM *
            r2unit[iterations];
        }

        /*  exitflag */
        *exitflag = 1.0;

        /*  (success) */
        /*  also determine minimum/maximum distance */
        /*  semi-major axis */
        st.site = &qc_emlrtRSI;
        minmax_distances(&st, r1vec, r1, r1vec, r2, dth, s / 2.0 / (1.0 -
          leftbranch * leftbranch), V1, V2, m, muC, extremal_distances);
        exitg1 = 1;
      }
    } while (exitg1 == 0);
  }
}

static void minmax_distances(const emlrtStack *sp, const real_T r1vec[3], real_T
  r1, const real_T r2vec[3], real_T r2, real_T dth, real_T a, const real_T V1[3],
  const real_T V2[3], real_T m, real_T muC, real_T extremal_distances[2])
{
  real_T minimum_distance;
  real_T maximum_distance;
  real_T y;
  real_T b_y;
  int32_T k;
  real_T theta2;
  real_T evec[3];
  real_T theta1;
  real_T e;
  real_T pericenter;
  real_T apocenter;
  real_T c_y;
  real_T d_y;
  real_T e_y;
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;

  /*  ----------------------------------------------------------------- */
  /*  Helper functions */
  /*  ----------------------------------------------------------------- */
  /*  compute minimum and maximum distances to the central body */
  /*  default - minimum/maximum of r1,r2 */
  minimum_distance = muDoubleScalarMin(r1, r2);
  maximum_distance = muDoubleScalarMax(r1, r2);

  /*  was the longway used or not? */
  /*  eccentricity vector (use triple product identity) */
  y = 0.0;
  b_y = 0.0;
  for (k = 0; k < 3; k++) {
    y += V1[k] * V1[k];
    b_y += V1[k] * r1vec[k];
  }

  /*  eccentricity */
  theta2 = 0.0;
  for (k = 0; k < 3; k++) {
    theta1 = (y * r1vec[k] - b_y * V1[k]) / muC - r1vec[k] / r1;
    theta2 += theta1 * theta1;
    evec[k] = theta1;
  }

  st.site = &bd_emlrtRSI;
  if (theta2 < 0.0) {
    b_st.site = &hb_emlrtRSI;
    eml_error(&b_st);
  }

  e = muDoubleScalarSqrt(theta2);

  /*  apses */
  pericenter = a * (1.0 - e);
  apocenter = rtInf;

  /*  parabolic/hyperbolic case */
  if (e < 1.0) {
    apocenter = a * (1.0 + e);
  }

  /*  elliptic case */
  /*  since we have the eccentricity vector, we know exactly where the */
  /*  pericenter lies. Use this fact, and the given value of [dth], to  */
  /*  cross-check if the trajectory goes past it */
  if (m > 0.0) {
    /*  obvious case (always elliptical and both apses are traversed) */
    minimum_distance = pericenter;
    maximum_distance = apocenter;
  } else {
    /*  less obvious case */
    /*  compute theta1&2 ( use (AxB)-(CxD) = (C·B)(D·A) - (C·A)(B·D) )) */
    y = 0.0;
    b_y = 0.0;
    theta2 = 0.0;
    c_y = 0.0;
    d_y = 0.0;
    e_y = 0.0;
    theta1 = 0.0;
    for (k = 0; k < 3; k++) {
      y += evec[k] * V1[k];
      b_y += r1vec[k] * evec[k];
      theta2 += r1vec[k] * V1[k];
      c_y += evec[k] * V2[k];
      d_y += r2vec[k] * evec[k];
      e_y += r2vec[k] * V2[k];

      /*  make 100.4% sure it's in (-1 <= theta12 <= +1) */
      theta1 += r1vec[k] / r1 * (evec[k] / e);
    }

    st.site = &cd_emlrtRSI;
    theta1 = muDoubleScalarSign(r1 * r1 * y - b_y * theta2) * muDoubleScalarAcos
      (muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, theta1)));
    y = 0.0;
    for (k = 0; k < 3; k++) {
      y += r2vec[k] / r2 * (evec[k] / e);
    }

    st.site = &dd_emlrtRSI;
    theta2 = muDoubleScalarSign(r2 * r2 * c_y - d_y * e_y) * muDoubleScalarAcos
      (muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, y)));

    /*  points 1&2 are on opposite sides of the symmetry axis -- minimum  */
    /*  and maximum distance depends both on the value of [dth], and both  */
    /*  [theta1] and [theta2] */
    if (theta1 * theta2 < 0.0) {
      /*  if |th1| + |th2| = turnangle, we know that the pericenter was  */
      /*  passed */
      if (muDoubleScalarAbs(theta1) + muDoubleScalarAbs(theta2) == dth) {
        minimum_distance = pericenter;

        /*  this condition can only be false for elliptic cases, and  */
        /*  when it is indeed false, we know that the orbit passed  */
        /*  apocenter */
      } else {
        maximum_distance = apocenter;
      }

      /*  points 1&2 are on the same side of the symmetry axis. Only if the  */
      /*  long-way was used are the min. and max. distances different from  */
      /*  the min. and max. values of the radii (namely, equal to the apses) */
    } else {
      if (muDoubleScalarAbs(dth) > 3.1415926535897931) {
        minimum_distance = pericenter;
        if (e < 1.0) {
          maximum_distance = apocenter;
        }
      }
    }
  }

  /*  output argument */
  extremal_distances[0] = minimum_distance;
  extremal_distances[1] = maximum_distance;
}

static void sigmax(real_T y, real_T *sig, real_T *dsigdx, real_T *d2sigdx2,
                   real_T *d3sigdx3)
{
  real_T powers[25];
  int32_T k;
  real_T b_y;
  static const real_T b[25] = { 0.4, 0.2142857142857143, 0.0462962962962963,
    0.006628787878787879, 0.00072115384615384609, 6.36574074074074E-5,
    4.7414799253034548E-6, 3.0594063283208018E-7, 1.74283640925506E-8,
    8.8924773311095776E-10, 4.1101115319865317E-11, 1.7367093848414581E-12,
    6.7597672400414259E-14, 2.4391233866140258E-15, 8.2034116145380068E-17,
    2.583771576869575E-18, 7.6523313279767163E-20, 2.138860629743989E-21,
    5.6599594511655524E-23, 1.4221048338173659E-24, 3.4013984832723061E-26,
    7.7625443047741554E-28, 1.693916882090479E-29, 3.54129500676686E-31,
    7.1053361878044024E-33 };

  real_T dv1[25];
  real_T dv2[25];
  static const int16_T iv0[25] = { 0, 2, 6, 12, 20, 30, 42, 56, 72, 90, 110, 132,
    156, 182, 210, 240, 272, 306, 342, 380, 420, 462, 506, 552, 600 };

  real_T dv3[25];
  static const int16_T iv1[25] = { 0, 0, 6, 24, 60, 120, 210, 336, 504, 720, 990,
    1320, 1716, 2184, 2730, 3360, 4080, 4896, 5814, 6840, 7980, 9240, 10626,
    12144, 13800 };

  /*  series approximation to T(x) and its derivatives  */
  /*  (used for near-parabolic cases) */
  /*  preload the factors [an]  */
  /*  (25 factors is more than enough for 16-digit accuracy)     */
  /*  powers of y */
  for (k = 0; k < 25; k++) {
    powers[k] = muDoubleScalarPower(y, 1.0 + (real_T)k);
  }

  /*  sigma */
  b_y = 0.0;
  for (k = 0; k < 25; k++) {
    b_y += powers[k] * b[k];
  }

  *sig = 1.3333333333333333 + b_y;

  /*  dsigma / dx */
  dv1[0] = 1.0;
  memcpy(&dv1[1], &powers[0], 24U * sizeof(real_T));
  *dsigdx = 0.0;
  for (k = 0; k < 25; k++) {
    *dsigdx += (1.0 + (real_T)k) * dv1[k] * b[k];
  }

  /*  d2sigma / dx2 */
  dv2[0] = 1.0 / y;
  dv2[1] = 1.0;
  memcpy(&dv2[2], &powers[0], 23U * sizeof(real_T));
  *d2sigdx2 = 0.0;
  for (k = 0; k < 25; k++) {
    *d2sigdx2 += (real_T)iv0[k] * dv2[k] * b[k];
  }

  /*  d3sigma / dx3 */
  dv3[0] = 1.0 / y / y;
  dv3[1] = 1.0 / y;
  dv3[2] = 1.0;
  memcpy(&dv3[3], &powers[0], 22U * sizeof(real_T));
  *d3sigdx3 = 0.0;
  for (k = 0; k < 25; k++) {
    *d3sigdx3 += (real_T)iv1[k] * dv3[k] * b[k];
  }
}

void lambert(const emlrtStack *sp, real_T r1vec[3], real_T r2vec[3], real_T tf,
             real_T m, real_T muC, real_T V1[3], real_T V2[3], real_T
             extremal_distances[2], real_T *exitflag)
{
  boolean_T bad;
  real_T r1;
  int32_T iterations;
  real_T V;
  real_T T;
  real_T mr2vec;
  real_T inn2;
  real_T dth;
  real_T leftbranch;
  real_T longway;
  real_T c;
  real_T s;
  real_T a_min;
  real_T err;
  real_T Lambda;
  real_T crossprd[3];
  real_T mcr;
  real_T logt;
  real_T inn1;
  real_T x1;
  real_T x2;
  real_T xx[2];
  real_T dv0[2];
  real_T bbeta[2];
  real_T aa[2];
  real_T a;
  real_T aalfa[2];
  real_T minval[2];
  real_T y2;
  real_T xnew;
  boolean_T exitg1;
  real_T x;
  real_T b_r2vec[3];
  real_T r2n[3];
  real_T b_crossprd[3];
  real_T c_crossprd[3];
  emlrtStack st;
  emlrtStack b_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;

  /*  LAMBERT            Lambert-targeter for ballistic flights */
  /*                     (Izzo, and Lancaster, Blanchard & Gooding) */
  /*  */
  /*  Usage:  */
  /*     [V1, V2, extremal_distances, exitflag] = lambert(r1, r2, tf, m, GM_central) */
  /*  */
  /*  Dimensions: */
  /*              r1, r2 ->  [1x3] */
  /*              V1, V2 ->  [1x3] */
  /*  extremal_distances ->  [1x2] */
  /*               tf, m ->  [1x1] */
  /*          GM_central ->  [1x1] */
  /*  */
  /*  This function solves any Lambert problem *robustly*. It uses two separate */
  /*  solvers; the first one tried is a new and unpublished algorithm developed  */
  /*  by Dr. D. Izzo from the European Space Agency [1]. This version is extremely */
  /*  fast, but especially for larger [m] it still fails quite frequently. In such  */
  /*  cases, a MUCH more robust algorithm is started (the one by Lancaster &  */
  /*  Blancard [2], with modifcations, initial values and other improvements by  */
  /*  R.Gooding [3]), which is a lot slower partly because of its robustness. */
  /*  */
  /*  INPUT ARGUMENTS: */
  /*  ====================================================================== */
  /*     name        units    description */
  /*  ====================================================================== */
  /*    r1, r1       [km]     position vectors of the two terminal points.     */
  /*      tf        [days]    time of flight to solve for      */
  /*       m          [-]     specifies the number of complete orbits to complete */
  /*                          (should be an integer)     */
  /*  GM_central   [km3/s2]   std. grav. parameter (G�M = mu) of the central body */
  /*   */
  /*  OUTPUT ARGUMENTS: */
  /*  ====================================================================== */
  /*    name             units   description */
  /*  ====================================================================== */
  /*   V1, V2             [km/s]  terminal velocities at the end-points */
  /*   extremal_distances  [km]   minimum(1) and maximum(2) distance of the */
  /*                              spacecraft to the central body. */
  /*   exitflag             [-]   Integer containing information on why the */
  /*                              routine terminated. A value of +1 indicates */
  /*                              success; a normal exit. A value of -1 */
  /*                              indicates that the given problem has no */
  /*                              solution and cannot be solved. A value of -2 */
  /*                              indicates that both algorithms failed to find */
  /*                              a solution. This should never occur since */
  /*                              these problems are well-defined, and at the */
  /*                              very least it can be determined that the */
  /*                              problem has no solution. Nevertheless, it */
  /*                              still occurs sometimes for accidental */
  /*                              erroneous input, so it provides a basic */
  /*                              mechanism to check any application using this */
  /*                              algorithm.  */
  /*   */
  /*  This routine can be compiled to increase its speed by a factor of about */
  /*  50, which is certainly advisable when the complete application requires  */
  /*  a great number of Lambert problems to be solved. The entire routine is  */
  /*  written in embedded MATLAB, so it can be compiled with the emlmex()  */
  /*  function. To do this, make sure MATLAB's current directory is equal to  */
  /*  where this file is located. Then, copy-paste and execute the following  */
  /*  commands to the command window: */
  /*  */
  /*     example_input = {... */
  /*          [0.0, 0.0, 0.0], ...% r1vec */
  /*          [0.0, 0.0, 0.0], ...% r2vec */
  /*           0.0, ...           % tf */
  /*           0.0, ...           % m */
  /*           0.0};              % muC */
  /*     emlmex -eg example_input lambert.m */
  /*  */
  /*  This is of course assuming your compiler is configured correctly. See the  */
  /*  docs on emlmex() on how to do that.  */
  /*  */
  /*  References: */
  /*  */
  /*  [1] Izzo, D. ESA Advanced Concepts team. Code used available in MGA.M, on */
  /*      http://www.esa.int/gsp/ACT/inf/op/globopt.htm. Last retreived Nov, 2009. */
  /*  [2] Lancaster, E.R. and Blanchard, R.C. "A unified form of Lambert's theorem."  */
  /*      NASA technical note TN D-5368,1969. */
  /*  [3] Gooding, R.H. "A procedure for the solution of Lambert's orbital boundary-value  */
  /*      problem. Celestial Mechanics and Dynamical Astronomy, 48:145�165,1990. */
  /*  */
  /*  See also lambert_low_ExpoSins. */
  /*  Please report bugs and inquiries to:  */
  /*  */
  /*  Name       : Rody P.S. Oldenhuis */
  /*  E-mail     : oldenhuis@gmail.com    (personal) */
  /*               oldenhuis@luxspace.lu  (professional) */
  /*  Affiliation: LuxSpace s�rl */
  /*  Licence    : BSD */
  /*  If you find this work useful, please consider a donation: */
  /*  https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6G3S5UYM7HJ3N */
  /*  ----------------------------------------------------------------- */
  /*  Izzo's version: */
  /*  Very fast, but not very robust for more complicated cases */
  /*  ----------------------------------------------------------------- */
  /*  original documentation: */
  /* { */
  /*  This routine implements a new algorithm that solves Lambert's problem. The */
  /*  algorithm has two major characteristics that makes it favorable to other */
  /*  existing ones. */
  /*  */
  /*  1) It describes the generic orbit solution of the boundary condition */
  /*  problem through the variable X=log(1+cos(alpha/2)). By doing so the */
  /*  graph of the time of flight become defined in the entire real axis and */
  /*  resembles a straight line. Convergence is granted within few iterations */
  /*  for all the possible geometries (except, of course, when the transfer */
  /*  angle is zero). When multiple revolutions are considered the variable is */
  /*  X=tan(cos(alpha/2)*pi/2). */
  /*  */
  /*  2) Once the orbit has been determined in the plane, this routine */
  /*  evaluates the velocity vectors at the two points in a way that is not */
  /*  singular for the transfer angle approaching to pi (Lagrange coefficient */
  /*  based methods are numerically not well suited for this purpose). */
  /*  */
  /*  As a result Lambert's problem is solved (with multiple revolutions */
  /*  being accounted for) with the same computational effort for all */
  /*  possible geometries. The case of near 180 transfers is also solved */
  /*  efficiently. */
  /*  */
  /*   We note here that even when the transfer angle is exactly equal to pi */
  /*  the algorithm does solve the problem in the plane (it finds X), but it */
  /*  is not able to evaluate the plane in which the orbit lies. A solution */
  /*  to this would be to provide the direction of the plane containing the */
  /*  transfer orbit from outside. This has not been implemented in this */
  /*  routine since such a direction would depend on which application the */
  /*  transfer is going to be used in. */
  /*  */
  /*  please report bugs to dario.izzo@esa.int     */
  /* } */
  /*  adjusted documentation: */
  /* { */
  /*  By default, the short-way solution is computed. The long way solution */
  /*  may be requested by giving a negative value to the corresponding */
  /*  time-of-flight [tf]. */
  /*  */
  /*  For problems with |m| > 0, there are generally two solutions. By */
  /*  default, the right branch solution will be returned. The left branch */
  /*  may be requested by giving a negative value to the corresponding */
  /*  number of complete revolutions [m]. */
  /* } */
  /*  Authors */
  /*  .-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-. */
  /*  Name       : Dr. Dario Izzo */
  /*  E-mail     : dario.izzo@esa.int */
  /*  Affiliation: ESA / Advanced Concepts Team (ACT) */
  /*  Made more readible and optimized for speed by Rody P.S. Oldenhuis */
  /*  Code available in MGA.M on   http://www.esa.int/gsp/ACT/inf/op/globopt.htm */
  /*  last edited 12/Dec/2009 */
  /*  ADJUSTED FOR EML-COMPILATION 24/Dec/2009 */
  /*  initial values         */
  bad = false;

  /*  work with non-dimensional units */
  r1 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r1 += r1vec[iterations] * r1vec[iterations];
  }

  st.site = &emlrtRSI;
  b_sqrt(&st, &r1);
  for (iterations = 0; iterations < 3; iterations++) {
    r1vec[iterations] /= r1;
  }

  V = muC / r1;
  st.site = &b_emlrtRSI;
  b_sqrt(&st, &V);
  T = r1 / V;
  tf = tf * 86400.0 / T;

  /*  also transform to seconds */
  /*  relevant geometry parameters (non dimensional) */
  mr2vec = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    inn2 = r2vec[iterations] / r1;
    mr2vec += inn2 * inn2;
    r2vec[iterations] = inn2;
  }

  st.site = &c_emlrtRSI;
  b_sqrt(&st, &mr2vec);

  /*  make 100% sure it's in (-1 <= dth <= +1) */
  inn2 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    inn2 += r1vec[iterations] * r2vec[iterations];
  }

  dth = muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, inn2 / mr2vec));
  st.site = &d_emlrtRSI;
  b_acos(&st, &dth);

  /*  decide whether to use the left or right branch (for multi-revolution */
  /*  problems), and the long- or short way     */
  leftbranch = muDoubleScalarSign(m);
  longway = muDoubleScalarSign(tf);
  m = muDoubleScalarAbs(m);
  tf = muDoubleScalarAbs(tf);
  if (longway < 0.0) {
    dth = 6.2831853071795862 - dth;
  }

  /*  derived quantities         */
  c = (1.0 + mr2vec * mr2vec) - 2.0 * mr2vec * muDoubleScalarCos(dth);
  st.site = &e_emlrtRSI;
  b_sqrt(&st, &c);

  /*  non-dimensional chord */
  s = ((1.0 + mr2vec) + c) / 2.0;

  /*  non-dimensional semi-perimeter */
  a_min = s / 2.0;

  /*  minimum energy ellipse semi major axis */
  err = mr2vec;
  st.site = &f_emlrtRSI;
  b_sqrt(&st, &err);
  Lambda = err * muDoubleScalarCos(dth / 2.0) / s;

  /*  lambda parameter (from BATTIN's book) */
  /* % non-dimensional normal vectors */
  crossprd[0] = r1vec[1] * r2vec[2] - r1vec[2] * r2vec[1];
  crossprd[1] = r1vec[2] * r2vec[0] - r1vec[0] * r2vec[2];
  crossprd[2] = r1vec[0] * r2vec[1] - r1vec[1] * r2vec[0];
  mcr = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    mcr += crossprd[iterations] * crossprd[iterations];
  }

  st.site = &g_emlrtRSI;
  b_sqrt(&st, &mcr);

  /*  magnitues thereof */
  /*  unit vector thereof */
  /*  Initial values */
  /*  --------------------------------------------------------- */
  /*  ELMEX requires this variable to be declared OUTSIDE the IF-statement */
  logt = tf;
  st.site = &h_emlrtRSI;
  b_log(&st, &logt);

  /*  avoid re-computing the same value */
  /*  single revolution (1 solution) */
  if (m == 0.0) {
    /*  initial values         */
    inn1 = -0.5233;

    /*  first initial guess */
    inn2 = 0.5233;

    /*  second initial guess */
    x1 = 0.4767;
    st.site = &i_emlrtRSI;
    b_log(&st, &x1);

    /*  transformed first initial guess */
    x2 = 1.5232999999999999;
    st.site = &j_emlrtRSI;
    b_log(&st, &x2);

    /*  transformed first second guess */
    /*  multiple revolutions (0, 1 or 2 solutions) */
    /*  the returned soltuion depends on the sign of [m] */
  } else {
    /*  select initial values */
    if (leftbranch < 0.0) {
      inn1 = -0.5234;

      /*  first initial guess, left branch */
      inn2 = -0.2234;

      /*  second initial guess, left branch */
    } else {
      inn1 = 0.7234;

      /*  first initial guess, right branch */
      inn2 = 0.5234;

      /*  second initial guess, right branch */
    }

    x1 = muDoubleScalarTan(inn1 * 3.1415926535897931 / 2.0);

    /*  transformed first initial guess */
    x2 = muDoubleScalarTan(inn2 * 3.1415926535897931 / 2.0);

    /*  transformed first second guess */
  }

  /*  since (inn1, inn2) < 0, initial estimate is always ellipse */
  xx[0] = inn1;
  xx[1] = inn2;
  power(xx, dv0);
  for (iterations = 0; iterations < 2; iterations++) {
    bbeta[iterations] = 1.0 - dv0[iterations];
  }

  b_rdivide(a_min, bbeta, aa);
  b_rdivide((s - c) / 2.0, aa, bbeta);
  st.site = &k_emlrtRSI;
  c_sqrt(&st, bbeta);
  a = longway * 2.0;
  st.site = &k_emlrtRSI;
  b_asin(&st, bbeta);

  /*  make 100.4% sure it's in (-1 <= xx <= +1) */
  for (iterations = 0; iterations < 2; iterations++) {
    aalfa[iterations] = xx[iterations];
    bbeta[iterations] *= a;
  }

  st.site = &l_emlrtRSI;
  c_acos(&st, aalfa);
  for (iterations = 0; iterations < 2; iterations++) {
    /*  evaluate the time of flight via Lagrange expression */
    dv0[iterations] = aa[iterations];
    aalfa[iterations] *= 2.0;
  }

  st.site = &m_emlrtRSI;
  c_sqrt(&st, dv0);
  for (iterations = 0; iterations < 2; iterations++) {
    xx[iterations] = aalfa[iterations];
  }

  b_sin(xx);
  for (iterations = 0; iterations < 2; iterations++) {
    minval[iterations] = bbeta[iterations];
  }

  b_sin(minval);
  err = 6.2831853071795862 * m;
  for (iterations = 0; iterations < 2; iterations++) {
    aa[iterations] = aa[iterations] * dv0[iterations] * (((aalfa[iterations] -
      xx[iterations]) - (bbeta[iterations] - minval[iterations])) + err);
  }

  /*  initial estimates for y */
  if (m == 0.0) {
    st.site = &n_emlrtRSI;
    if (aa[0] < 0.0) {
      b_st.site = &jb_emlrtRSI;
      c_eml_error(&b_st);
    }

    inn2 = muDoubleScalarLog(aa[0]) - logt;
    st.site = &o_emlrtRSI;
    if (aa[1] < 0.0) {
      b_st.site = &jb_emlrtRSI;
      c_eml_error(&b_st);
    }

    y2 = muDoubleScalarLog(aa[1]) - logt;
  } else {
    inn2 = aa[0] - tf;
    y2 = aa[1] - tf;
  }

  /*  Solve for x */
  /*  --------------------------------------------------------- */
  /*  Newton-Raphson iterations */
  /*  NOTE - the number of iterations will go to infinity in case */
  /*  m > 0  and there is no solution. Start the other routine in  */
  /*  that case */
  err = rtInf;
  iterations = 0;
  xnew = 0.0;
  exitg1 = false;
  while ((!exitg1) && (err > 1.0E-14)) {
    /*  increment number of iterations */
    iterations++;

    /*  new x */
    xnew = (x1 * y2 - inn2 * x2) / (y2 - inn2);

    /*  copy-pasted code (for performance) */
    if (m == 0.0) {
      x = muDoubleScalarExp(xnew) - 1.0;
    } else {
      x = muDoubleScalarAtan(xnew) * 2.0 / 3.1415926535897931;
    }

    a = a_min / (1.0 - x * x);
    if (x < 1.0) {
      /*  ellipse */
      inn1 = (s - c) / 2.0 / a;
      st.site = &p_emlrtRSI;
      if (inn1 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      inn1 = muDoubleScalarSqrt(inn1);
      st.site = &p_emlrtRSI;
      if (1.0 < inn1) {
        b_st.site = &kb_emlrtRSI;
        d_eml_error(&b_st);
      }

      inn1 = longway * 2.0 * muDoubleScalarAsin(inn1);

      /*  make 100.4% sure it's in (-1 <= xx <= +1) */
      st.site = &q_emlrtRSI;
      inn2 = 2.0 * muDoubleScalarAcos(muDoubleScalarMax(-1.0, x));
    } else {
      /*  hyperbola */
      st.site = &r_emlrtRSI;
      b_acosh(&st, &x);
      inn2 = 2.0 * x;
      x = (s - c) / (-2.0 * a);
      st.site = &s_emlrtRSI;
      if (x < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      err = muDoubleScalarSqrt(x);
      b_asinh(&err);
      inn1 = longway * 2.0 * err;
    }

    /*  evaluate the time of flight via Lagrange expression */
    if (a > 0.0) {
      st.site = &t_emlrtRSI;
      x1 = a * muDoubleScalarSqrt(a) * (((inn2 - muDoubleScalarSin(inn2)) -
        (inn1 - muDoubleScalarSin(inn1))) + 6.2831853071795862 * m);
    } else {
      st.site = &u_emlrtRSI;
      x1 = -a * muDoubleScalarSqrt(-a) * ((muDoubleScalarSinh(inn2) - inn2) -
        (muDoubleScalarSinh(inn1) - inn1));
    }

    /*  new value of y */
    if (m == 0.0) {
      st.site = &v_emlrtRSI;
      if (x1 < 0.0) {
        b_st.site = &jb_emlrtRSI;
        c_eml_error(&b_st);
      }

      inn1 = muDoubleScalarLog(x1) - logt;
    } else {
      inn1 = x1 - tf;
    }

    /*  save previous and current values for the next iterarion */
    /*  (prevents getting stuck between two values) */
    x1 = x2;
    x2 = xnew;
    inn2 = y2;
    y2 = inn1;

    /*  update error */
    err = muDoubleScalarAbs(x1 - xnew);

    /*  escape clause */
    emlrtBreakCheckFastR2012b(emlrtBreakCheckR2012bFlagVar, sp);
    if (iterations > 15) {
      bad = true;
      exitg1 = true;
    }
  }

  /*  If the Newton-Raphson scheme failed, try to solve the problem */
  /*  with the other Lambert targeter.  */
  if (bad) {
    /*  NOTE: use the original, UN-normalized quantities */
    for (iterations = 0; iterations < 3; iterations++) {
      crossprd[iterations] = r1vec[iterations] * r1;
      b_r2vec[iterations] = r2vec[iterations] * r1;
    }

    st.site = &w_emlrtRSI;
    lambert_LancasterBlanchard(&st, crossprd, b_r2vec, longway * tf * T,
      leftbranch * m, muC, V1, V2, extremal_distances, exitflag);
  } else {
    /*  convert converged value of x */
    if (m == 0.0) {
      x = muDoubleScalarExp(xnew) - 1.0;
    } else {
      x = muDoubleScalarAtan(xnew) * 2.0 / 3.1415926535897931;
    }

    /*     %{ */
    /*       The solution has been evaluated in terms of log(x+1) or tan(x*pi/2), we */
    /*       now need the conic. As for transfer angles near to pi the Lagrange- */
    /*       coefficients technique goes singular (dg approaches a zero/zero that is */
    /*       numerically bad) we here use a different technique for those cases. When */
    /*       the transfer angle is exactly equal to pi, then the ih unit vector is not */
    /*       determined. The remaining equations, though, are still valid. */
    /*     %} */
    /*  Solution for the semi-major axis */
    a = a_min / (1.0 - x * x);

    /*  Calculate psi */
    if (x < 1.0) {
      /*  ellipse */
      inn1 = (s - c) / 2.0 / a;
      st.site = &x_emlrtRSI;
      if (inn1 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      inn1 = muDoubleScalarSqrt(inn1);
      st.site = &x_emlrtRSI;
      if (1.0 < inn1) {
        b_st.site = &kb_emlrtRSI;
        d_eml_error(&b_st);
      }

      /*  make 100.4% sure it's in (-1 <= xx <= +1) */
      st.site = &y_emlrtRSI;
      inn1 = muDoubleScalarSin((2.0 * muDoubleScalarAcos(muDoubleScalarMax(-1.0,
        x)) - longway * 2.0 * muDoubleScalarAsin(inn1)) / 2.0);
      x1 = 2.0 * a * (inn1 * inn1) / s;
      st.site = &ab_emlrtRSI;
      if (x1 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      inn2 = muDoubleScalarSqrt(x1);
    } else {
      /*  hyperbola */
      inn1 = (c - s) / 2.0 / a;
      st.site = &bb_emlrtRSI;
      if (inn1 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      err = x;
      st.site = &cb_emlrtRSI;
      b_acosh(&st, &err);
      x1 = muDoubleScalarSqrt(inn1);
      b_asinh(&x1);
      inn1 = muDoubleScalarSinh((2.0 * err - longway * 2.0 * x1) / 2.0);
      x1 = -2.0 * a * (inn1 * inn1) / s;
      st.site = &db_emlrtRSI;
      if (x1 < 0.0) {
        b_st.site = &hb_emlrtRSI;
        eml_error(&b_st);
      }

      inn2 = muDoubleScalarSqrt(x1);
    }

    /*  unit of the normalized normal vector */
    for (iterations = 0; iterations < 3; iterations++) {
      /*  unit vector for normalized [r2vec] */
      r2n[iterations] = r2vec[iterations] / mr2vec;
      crossprd[iterations] = longway * (crossprd[iterations] / mcr);
    }

    /*  cross-products */
    /*  don't use cross() (emlmex() would try to compile it, and this way it */
    /*  also does not create any additional overhead) */
    /*  radial and tangential directions for departure velocity */
    st.site = &eb_emlrtRSI;
    if (a_min < 0.0) {
      b_st.site = &hb_emlrtRSI;
      eml_error(&b_st);
    }

    err = 1.0 / inn2 / muDoubleScalarSqrt(a_min) * ((2.0 * Lambda * a_min -
      Lambda) - x * inn2);
    x = muDoubleScalarSin(dth / 2.0);
    st.site = &fb_emlrtRSI;
    x = mr2vec / a_min / x1 * (x * x);
    if (x < 0.0) {
      b_st.site = &hb_emlrtRSI;
      eml_error(&b_st);
    }

    inn2 = muDoubleScalarSqrt(x);

    /*  radial and tangential directions for arrival velocity */
    x1 = inn2 / mr2vec;
    inn1 = (inn2 - x1) / muDoubleScalarTan(dth / 2.0) - err;

    /*  terminal velocities */
    b_crossprd[0] = crossprd[1] * r1vec[2] - crossprd[2] * r1vec[1];
    b_crossprd[1] = crossprd[2] * r1vec[0] - crossprd[0] * r1vec[2];
    b_crossprd[2] = crossprd[0] * r1vec[1] - crossprd[1] * r1vec[0];
    c_crossprd[0] = crossprd[1] * r2n[2] - crossprd[2] * r2n[1];
    c_crossprd[1] = crossprd[2] * r2n[0] - crossprd[0] * r2n[2];
    c_crossprd[2] = crossprd[0] * r2n[1] - crossprd[1] * r2n[0];

    /*  exitflag */
    *exitflag = 1.0;

    /*  (success) */
    /*  also compute minimum distance to central body */
    /*  NOTE: use un-transformed vectors again! */
    for (iterations = 0; iterations < 3; iterations++) {
      V1[iterations] = (err * r1vec[iterations] + inn2 * b_crossprd[iterations])
        * V;
      V2[iterations] = (inn1 * r2n[iterations] + x1 * c_crossprd[iterations]) *
        V;
      crossprd[iterations] = r1vec[iterations] * r1;
      b_r2vec[iterations] = r2vec[iterations] * r1;
    }

    st.site = &gb_emlrtRSI;
    minmax_distances(&st, crossprd, r1, b_r2vec, mr2vec * r1, dth, a * r1, V1,
                     V2, m, muC, extremal_distances);
  }
}

/* End of code generation (lambert.c) */
