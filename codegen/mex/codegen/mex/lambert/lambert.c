/*
 * lambert.c
 *
 * Code generation for function 'lambert'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "lambert.h"
#include "error.h"
#include "toLogicalCheck.h"
#include "mod.h"
#include "sqrt.h"
#include "acos.h"
#include "cross.h"
#include "asin.h"
#include "asinh.h"
#include "acosh.h"
#include "log.h"
#include "sin.h"
#include "power.h"
#include "lambert_data.h"

/* Variable Definitions */
static real_T an[25];
static emlrtRSInfo emlrtRSI = { 201,   /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo b_emlrtRSI = { 202, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo c_emlrtRSI = { 206, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo d_emlrtRSI = { 208, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo e_emlrtRSI = { 217, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo f_emlrtRSI = { 220, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo g_emlrtRSI = { 224, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo h_emlrtRSI = { 231, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo i_emlrtRSI = { 239, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo j_emlrtRSI = { 240, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo k_emlrtRSI = { 259, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo l_emlrtRSI = { 261, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo m_emlrtRSI = { 264, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo n_emlrtRSI = { 268, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo o_emlrtRSI = { 269, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo p_emlrtRSI = { 290, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo q_emlrtRSI = { 292, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo r_emlrtRSI = { 294, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo s_emlrtRSI = { 296, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo t_emlrtRSI = { 297, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo u_emlrtRSI = { 301, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo v_emlrtRSI = { 303, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo w_emlrtRSI = { 306, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo x_emlrtRSI = { 321, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo y_emlrtRSI = { 339, /* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ab_emlrtRSI = { 343,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo bb_emlrtRSI = { 345,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo cb_emlrtRSI = { 347,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo db_emlrtRSI = { 348,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo eb_emlrtRSI = { 350,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo fb_emlrtRSI = { 351,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo gb_emlrtRSI = { 353,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo hb_emlrtRSI = { 354,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ib_emlrtRSI = { 374,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo jb_emlrtRSI = { 375,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo kb_emlrtRSI = { 391,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo nb_emlrtRSI = { 40, /* lineNo */
  "mpower",                            /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\ops\\mpower.m"/* pathName */
};

static emlrtRSInfo ob_emlrtRSI = { 49, /* lineNo */
  "power",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\ops\\power.m"/* pathName */
};

static emlrtRSInfo pb_emlrtRSI = { 61, /* lineNo */
  "power",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2017b\\toolbox\\eml\\lib\\matlab\\ops\\power.m"/* pathName */
};

static emlrtRSInfo xb_emlrtRSI = { 430,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo yb_emlrtRSI = { 431,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ac_emlrtRSI = { 435,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo bc_emlrtRSI = { 439,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo cc_emlrtRSI = { 450,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo dc_emlrtRSI = { 452,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ec_emlrtRSI = { 453,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo fc_emlrtRSI = { 459,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo gc_emlrtRSI = { 461,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo hc_emlrtRSI = { 473,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ic_emlrtRSI = { 474,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo jc_emlrtRSI = { 478,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo kc_emlrtRSI = { 480,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo lc_emlrtRSI = { 493,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo mc_emlrtRSI = { 495,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo nc_emlrtRSI = { 507,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo oc_emlrtRSI = { 510,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo pc_emlrtRSI = { 512,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo qc_emlrtRSI = { 522,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo rc_emlrtRSI = { 532,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo sc_emlrtRSI = { 536,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo tc_emlrtRSI = { 538,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo uc_emlrtRSI = { 540,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo vc_emlrtRSI = { 548,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo wc_emlrtRSI = { 551,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo xc_emlrtRSI = { 555,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo yc_emlrtRSI = { 559,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ad_emlrtRSI = { 578,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo bd_emlrtRSI = { 584,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo cd_emlrtRSI = { 586,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo dd_emlrtRSI = { 595,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ed_emlrtRSI = { 601,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo fd_emlrtRSI = { 603,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo gd_emlrtRSI = { 626,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo hd_emlrtRSI = { 627,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo id_emlrtRSI = { 647,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo jd_emlrtRSI = { 649,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo kd_emlrtRSI = { 651,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ld_emlrtRSI = { 653,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo md_emlrtRSI = { 657,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo nd_emlrtRSI = { 658,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo od_emlrtRSI = { 660,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo pd_emlrtRSI = { 662,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo qd_emlrtRSI = { 664,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo rd_emlrtRSI = { 666,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo sd_emlrtRSI = { 670,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo td_emlrtRSI = { 671,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ud_emlrtRSI = { 683,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo vd_emlrtRSI = { 689,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo wd_emlrtRSI = { 691,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo xd_emlrtRSI = { 693,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo be_emlrtRSI = { 760,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ce_emlrtRSI = { 777,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo de_emlrtRSI = { 778,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

static emlrtRSInfo ee_emlrtRSI = { 785,/* lineNo */
  "lambert",                           /* fcnName */
  "C:\\Users\\Adam\\Dropbox\\Documents\\homework\\Personal Projects\\KSP Trajectory Optimization Tool\\codegen\\mex\\lambert\\lambert.m"/* pathName */
};

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
  real_T y;
  real_T sig1;
  real_T f;
  real_T g;
  real_T z;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;

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
    st.site = &id_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    T = 1.3333333333333333 * (1.0 - muDoubleScalarPower(q, 3.0));

    /*  T'(x) */
    st.site = &jd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;

    /*  T''(x) */
    st.site = &kd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;

    /*  T'''(x) */
    st.site = &ld_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
  } else if (muDoubleScalarAbs(x - 1.0) < 0.01) {
    /*  near-parabolic; compute with series */
    /*  evaluate sigma */
    st.site = &md_emlrtRSI;
    sigmax(-E, &sig1, &f, &g, &z);
    st.site = &nd_emlrtRSI;
    sigmax(-E * q * q, &f, &g, &z, &y);

    /*  T(x) */
    st.site = &od_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    T = sig1 - muDoubleScalarPower(q, 3.0) * f;

    /*  T'(x) */
    st.site = &pd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;

    /*  T''(x) */
    st.site = &qd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &qd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;

    /*  T'''(x) */
    st.site = &rd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
  } else {
    /*  all other cases */
    /*  compute all substitution functions */
    y = muDoubleScalarAbs(E);
    st.site = &sd_emlrtRSI;
    b_sqrt(&st, &y);
    st.site = &td_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &td_emlrtRSI;
    f = 1.0 + q * q * E;
    if (f < 0.0) {
      b_st.site = &lb_emlrtRSI;
      c_st.site = &lb_emlrtRSI;
      error(&c_st);
    }

    z = muDoubleScalarSqrt(f);
    f = y * (z - q * x);
    g = x * z - q * E;

    /*  BUGFIX: (Simon Tardivel) this line is incorrect for E==0 and f+g==0 */
    /*  d  = (E < 0)*(atan2(f, g) + pi*m) + (E > 0)*log( max(0, f + g) ); */
    /*  it should be written out like so: */
    if (E < 0.0) {
      f = muDoubleScalarAtan2(f, g) + 3.1415926535897931 * m;
    } else if (E == 0.0) {
      f = 0.0;
    } else {
      st.site = &ud_emlrtRSI;
      f = muDoubleScalarLog(muDoubleScalarMax(0.0, f + g));
    }

    /*  T(x) */
    T = 2.0 * ((x - q * z) - f / y) / E;

    /*   T'(x) */
    st.site = &vd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;

    /*  T''(x) */
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;

    /*  T'''(x) */
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
  }

  return T;
}

static void b_LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m, real_T *T, real_T *Tp, real_T *Tpp, real_T *Tppp)
{
  real_T E;
  real_T y;
  real_T f;
  real_T d2sigdx21;
  real_T d3sigdx31;
  real_T g;
  real_T z;
  real_T d2sigdx22;
  real_T d3sigdx32;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;

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
    st.site = &id_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *T = 1.3333333333333333 * (1.0 - muDoubleScalarPower(q, 3.0));

    /*  T'(x) */
    st.site = &jd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tp = 0.8 * (muDoubleScalarPower(q, 5.0) - 1.0);

    /*  T''(x) */
    st.site = &kd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tpp = *Tp + 1.7142857142857142 * (1.0 - muDoubleScalarPower(q, 7.0));

    /*  T'''(x) */
    st.site = &ld_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tppp = 3.0 * (*Tpp - *Tp) + 2.2222222222222223 * (muDoubleScalarPower(q,
      9.0) - 1.0);
  } else if (muDoubleScalarAbs(x - 1.0) < 0.01) {
    /*  near-parabolic; compute with series */
    /*  evaluate sigma */
    st.site = &md_emlrtRSI;
    sigmax(-E, &f, &y, &d2sigdx21, &d3sigdx31);
    st.site = &nd_emlrtRSI;
    sigmax(-E * q * q, &g, &z, &d2sigdx22, &d3sigdx32);

    /*  T(x) */
    st.site = &od_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *T = f - muDoubleScalarPower(q, 3.0) * g;

    /*  T'(x) */
    st.site = &pd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tp = 2.0 * x * (muDoubleScalarPower(q, 5.0) * z - y);

    /*  T''(x) */
    st.site = &qd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &qd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tpp = *Tp / x + 4.0 * (x * x) * (d2sigdx21 - muDoubleScalarPower(q, 7.0) *
      d2sigdx22);

    /*  T'''(x) */
    st.site = &rd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tppp = 3.0 * (*Tpp - *Tp / x) / x + 8.0 * x * x * (muDoubleScalarPower(q,
      9.0) * d3sigdx32 - d3sigdx31);
  } else {
    /*  all other cases */
    /*  compute all substitution functions */
    y = muDoubleScalarAbs(E);
    st.site = &sd_emlrtRSI;
    b_sqrt(&st, &y);
    st.site = &td_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &td_emlrtRSI;
    f = 1.0 + q * q * E;
    if (f < 0.0) {
      b_st.site = &lb_emlrtRSI;
      c_st.site = &lb_emlrtRSI;
      error(&c_st);
    }

    z = muDoubleScalarSqrt(f);
    f = y * (z - q * x);
    g = x * z - q * E;

    /*  BUGFIX: (Simon Tardivel) this line is incorrect for E==0 and f+g==0 */
    /*  d  = (E < 0)*(atan2(f, g) + pi*m) + (E > 0)*log( max(0, f + g) ); */
    /*  it should be written out like so: */
    if (E < 0.0) {
      f = muDoubleScalarAtan2(f, g) + 3.1415926535897931 * m;
    } else if (E == 0.0) {
      f = 0.0;
    } else {
      st.site = &ud_emlrtRSI;
      f = muDoubleScalarLog(muDoubleScalarMax(0.0, f + g));
    }

    /*  T(x) */
    *T = 2.0 * ((x - q * z) - f / y) / E;

    /*   T'(x) */
    st.site = &vd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tp = ((4.0 - 4.0 * muDoubleScalarPower(q, 3.0) * x / z) - 3.0 * x * *T) / E;

    /*  T''(x) */
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tpp = ((-4.0 * muDoubleScalarPower(q, 3.0) / z * (1.0 - q * q * (x * x) /
              (z * z)) - 3.0 * *T) - 3.0 * x * *Tp) / E;

    /*  T'''(x) */
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tppp = ((4.0 * muDoubleScalarPower(q, 3.0) / (z * z) * ((1.0 - q * q * (x *
      x) / (z * z)) + 2.0 * (q * q) * x / (z * z) * (z - x)) - 8.0 * *Tp) - 7.0 *
             x * *Tpp) / E;
  }
}

static void c_LancasterBlanchard(const emlrtStack *sp, real_T x, real_T q,
  real_T m, real_T *T, real_T *Tp, real_T *Tpp)
{
  real_T E;
  real_T y;
  real_T dsigdx1;
  real_T d2sigdx21;
  real_T f;
  real_T z;
  real_T d2sigdx22;
  real_T g;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;

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
    st.site = &id_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *T = 1.3333333333333333 * (1.0 - muDoubleScalarPower(q, 3.0));

    /*  T'(x) */
    st.site = &jd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tp = 0.8 * (muDoubleScalarPower(q, 5.0) - 1.0);

    /*  T''(x) */
    st.site = &kd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tpp = *Tp + 1.7142857142857142 * (1.0 - muDoubleScalarPower(q, 7.0));

    /*  T'''(x) */
    st.site = &ld_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
  } else if (muDoubleScalarAbs(x - 1.0) < 0.01) {
    /*  near-parabolic; compute with series */
    /*  evaluate sigma */
    st.site = &md_emlrtRSI;
    sigmax(-E, &y, &dsigdx1, &d2sigdx21, &f);
    st.site = &nd_emlrtRSI;
    sigmax(-E * q * q, &f, &z, &d2sigdx22, &g);

    /*  T(x) */
    st.site = &od_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *T = y - muDoubleScalarPower(q, 3.0) * f;

    /*  T'(x) */
    st.site = &pd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tp = 2.0 * x * (muDoubleScalarPower(q, 5.0) * z - dsigdx1);

    /*  T''(x) */
    st.site = &qd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &qd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tpp = *Tp / x + 4.0 * (x * x) * (d2sigdx21 - muDoubleScalarPower(q, 7.0) *
      d2sigdx22);

    /*  T'''(x) */
    st.site = &rd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
  } else {
    /*  all other cases */
    /*  compute all substitution functions */
    y = muDoubleScalarAbs(E);
    st.site = &sd_emlrtRSI;
    b_sqrt(&st, &y);
    st.site = &td_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &td_emlrtRSI;
    f = 1.0 + q * q * E;
    if (f < 0.0) {
      b_st.site = &lb_emlrtRSI;
      c_st.site = &lb_emlrtRSI;
      error(&c_st);
    }

    z = muDoubleScalarSqrt(f);
    f = y * (z - q * x);
    g = x * z - q * E;

    /*  BUGFIX: (Simon Tardivel) this line is incorrect for E==0 and f+g==0 */
    /*  d  = (E < 0)*(atan2(f, g) + pi*m) + (E > 0)*log( max(0, f + g) ); */
    /*  it should be written out like so: */
    if (E < 0.0) {
      f = muDoubleScalarAtan2(f, g) + 3.1415926535897931 * m;
    } else if (E == 0.0) {
      f = 0.0;
    } else {
      st.site = &ud_emlrtRSI;
      f = muDoubleScalarLog(muDoubleScalarMax(0.0, f + g));
    }

    /*  T(x) */
    *T = 2.0 * ((x - q * z) - f / y) / E;

    /*   T'(x) */
    st.site = &vd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tp = ((4.0 - 4.0 * muDoubleScalarPower(q, 3.0) * x / z) - 3.0 * x * *T) / E;

    /*  T''(x) */
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &wd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    *Tpp = ((-4.0 * muDoubleScalarPower(q, 3.0) / z * (1.0 - q * q * (x * x) /
              (z * z)) - 3.0 * *T) - 3.0 * x * *Tp) / E;

    /*  T'''(x) */
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &xd_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
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
  real_T th1unit[3];
  real_T dth;
  real_T leftbranch;
  real_T c;
  real_T s;
  real_T Vr1;
  real_T T;
  real_T TmTM;
  real_T q;
  real_T T0;
  real_T Td;
  real_T phr;
  boolean_T guard1 = false;
  real_T xM0;
  real_T Tp;
  int32_T exitg2;
  int32_T exitg1;
  real_T b_gamma;
  real_T xMp;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  emlrtStack e_st;
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

  /*  ----------------------------------------------------------------- */
  /*  Lancaster & Blanchard version, with improvements by Gooding */
  /*  Very reliable, moderately fast for both simple and complicated cases */
  /*  ----------------------------------------------------------------- */
  /* #coder */
  /* { */
  /* LAMBERT_LANCASTERBLANCHARD       High-Thrust Lambert-targeter */
  /*  */
  /* lambert_LancasterBlanchard() uses the method developed by */
  /* Lancaster & Blancard, as described in their 1969 paper. Initial values, */
  /* and several details of the procedure, are provided by R.H. Gooding, */
  /* as described in his 1990 paper. */
  /* } */
  /*  Please report bugs and inquiries to: */
  /*  */
  /*  Name       : Rody P.S. Oldenhuis */
  /*  E-mail     : oldenhuis@gmail.com */
  /*  Licence    : 2-clause BSD (see License.txt) */
  /*  If you find this work useful, please consider a donation: */
  /*  https://www.paypal.me/RodyO/3.5 */
  /*  ADJUSTED FOR EML-COMPILATION 29/Sep/2009 */
  /*  manipulate input */
  /*  optimum for numerical noise v.s. actual precision */
  r1 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r1 += r1vec[iterations] * r1vec[iterations];
  }

  st.site = &xb_emlrtRSI;
  b_sqrt(&st, &r1);

  /*  magnitude of r1vec */
  r2 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r2 += r2vec[iterations] * r2vec[iterations];
  }

  st.site = &yb_emlrtRSI;
  b_sqrt(&st, &r2);

  /*  magnitude of r2vec */
  /*  unit vector of r1vec */
  /*  unit vector of r2vec */
  cross(r1vec, r2vec, crsprod);

  /*  cross product of r1vec and r2vec */
  mcrsprd = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    r1unit[iterations] = r1vec[iterations] / r1;
    r2unit[iterations] = r2vec[iterations] / r2;
    mcrsprd += crsprod[iterations] * crsprod[iterations];
  }

  st.site = &ac_emlrtRSI;
  b_sqrt(&st, &mcrsprd);

  /*  magnitude of that cross product */
  for (iterations = 0; iterations < 3; iterations++) {
    b_crsprod[iterations] = crsprod[iterations] / mcrsprd;
  }

  cross(b_crsprod, r1unit, th1unit);

  /*  unit vectors in the tangential-directions */
  for (iterations = 0; iterations < 3; iterations++) {
    b_crsprod[iterations] = crsprod[iterations] / mcrsprd;
  }

  cross(b_crsprod, r2unit, crsprod);

  /*  make 100.4% sure it's in (-1 <= x <= +1) */
  mcrsprd = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    mcrsprd += r1vec[iterations] * r2vec[iterations];
  }

  dth = muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, mcrsprd / r1 / r2));
  st.site = &bc_emlrtRSI;
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
  st.site = &cc_emlrtRSI;
  b_st.site = &nb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  st.site = &cc_emlrtRSI;
  b_st.site = &nb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  c = (r1 * r1 + r2 * r2) - 2.0 * r1 * r2 * muDoubleScalarCos(dth);
  st.site = &cc_emlrtRSI;
  b_sqrt(&st, &c);
  s = ((r1 + r2) + c) / 2.0;
  st.site = &dc_emlrtRSI;
  b_st.site = &nb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  Vr1 = 8.0 * muC / muDoubleScalarPower(s, 3.0);
  st.site = &dc_emlrtRSI;
  b_sqrt(&st, &Vr1);
  T = Vr1 * tf;
  TmTM = r1 * r2;
  st.site = &ec_emlrtRSI;
  b_sqrt(&st, &TmTM);
  q = TmTM / s * muDoubleScalarCos(dth / 2.0);

  /*  general formulae for the initial values (Gooding) */
  /*  ------------------------------------------------- */
  /*  some initial values */
  st.site = &fc_emlrtRSI;
  T0 = LancasterBlanchard(&st, 0.0, q, m);
  Td = T0 - T;
  st.site = &gc_emlrtRSI;
  b_st.site = &nb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  phr = b_mod(2.0 * muDoubleScalarAtan2(1.0 - q * q, 2.0 * q));

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
      phr = T0 * Td / 4.0 / T;
    } else {
      xM0 = Td / (4.0 - Td);
      Vr1 = -Td / (T + T0 / 2.0);
      st.site = &hc_emlrtRSI;
      b_sqrt(&st, &Vr1);
      mcrsprd = 2.0 - phr / 3.1415926535897931;
      st.site = &ic_emlrtRSI;
      b_sqrt(&st, &mcrsprd);
      mcrsprd = xM0 + 1.7 * mcrsprd;
      if (mcrsprd >= 0.0) {
        TmTM = xM0;
      } else {
        st.site = &jc_emlrtRSI;
        b_st.site = &ob_emlrtRSI;
        TmTM = xM0 + muDoubleScalarPower(-mcrsprd, 0.0625) * (-Vr1 - xM0);
      }

      st.site = &kc_emlrtRSI;
      b_st.site = &nb_emlrtRSI;
      c_st.site = &ob_emlrtRSI;
      Vr1 = 1.0 + xM0;
      st.site = &kc_emlrtRSI;
      b_sqrt(&st, &Vr1);
      phr = ((1.0 + TmTM * (1.0 + xM0) / 2.0) - 0.03 * (TmTM * TmTM) * Vr1) *
        TmTM;
    }

    /*  this estimate might not give a solution */
    if (phr < -1.0) {
      *exitflag = -1.0;
    } else {
      /*  multi-revolution case */
      guard1 = true;
    }
  } else {
    /*  determine minimum Tp(x) */
    mcrsprd = 4.0 / (9.42477796076938 * (2.0 * m + 1.0));
    if (phr < 3.1415926535897931) {
      TmTM = phr / 3.1415926535897931;
      st.site = &lc_emlrtRSI;
      b_st.site = &nb_emlrtRSI;
      c_st.site = &ob_emlrtRSI;
      if (TmTM < 0.0) {
        d_st.site = &pb_emlrtRSI;
        e_st.site = &pb_emlrtRSI;
        c_error(&e_st);
      }

      xM0 = mcrsprd * muDoubleScalarPower(TmTM, 0.125);
    } else if (phr > 3.1415926535897931) {
      st.site = &mc_emlrtRSI;
      TmTM = 2.0 - phr / 3.1415926535897931;
      b_st.site = &nb_emlrtRSI;
      c_st.site = &ob_emlrtRSI;
      if (TmTM < 0.0) {
        d_st.site = &pb_emlrtRSI;
        e_st.site = &pb_emlrtRSI;
        c_error(&e_st);
      }

      xM0 = mcrsprd * (2.0 - muDoubleScalarPower(TmTM, 0.125));

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
        st.site = &nc_emlrtRSI;
        b_LancasterBlanchard(&st, xM0, q, m, &Vr1, &Tp, &b_gamma, &mcrsprd);

        /*  new value of xM */
        xMp = xM0;
        st.site = &oc_emlrtRSI;
        b_st.site = &ob_emlrtRSI;
        xM0 -= 2.0 * Tp * b_gamma / (2.0 * (b_gamma * b_gamma) - Tp * mcrsprd);

        /*  escape clause */
        Vr1 = c_mod(iterations);
        st.site = &pc_emlrtRSI;
        toLogicalCheck(&st, Vr1);
        if (Vr1 != 0.0) {
          xM0 = (xMp + xM0) / 2.0;
        }

        /*  the method might fail. Exit in that case */
        if (*emlrtBreakCheckR2012bFlagVar != 0) {
          emlrtBreakCheckR2012b(sp);
        }

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
      st.site = &qc_emlrtRSI;
      mcrsprd = LancasterBlanchard(&st, xM0, q, m);

      /*  T should lie above the minimum T */
      if (mcrsprd > T) {
        *exitflag = -1.0;
      } else {
        /*  find two initial values for second solution (again with lambda-type patch) */
        /*  -------------------------------------------------------------------------- */
        /*  some initial values */
        TmTM = T - mcrsprd;
        st.site = &rc_emlrtRSI;
        c_LancasterBlanchard(&st, xM0, q, m, &Vr1, &Tp, &b_gamma);

        /*  first estimate (only if m > 0) */
        if (leftbranch > 0.0) {
          st.site = &sc_emlrtRSI;
          b_st.site = &nb_emlrtRSI;
          c_st.site = &ob_emlrtRSI;
          phr = TmTM / (b_gamma / 2.0 + TmTM / ((1.0 - xM0) * (1.0 - xM0)));
          st.site = &sc_emlrtRSI;
          b_sqrt(&st, &phr);
          mcrsprd = xM0 + phr;
          st.site = &tc_emlrtRSI;
          b_st.site = &nb_emlrtRSI;
          c_st.site = &ob_emlrtRSI;
          mcrsprd = 4.0 * mcrsprd / (4.0 + TmTM) + (1.0 - mcrsprd) * (1.0 -
            mcrsprd);
          Vr1 = mcrsprd;
          st.site = &uc_emlrtRSI;
          b_sqrt(&st, &Vr1);
          phr = phr * (1.0 - ((1.0 + m) + (dth - 0.5)) / (1.0 + 0.15 * m) * phr *
                       (mcrsprd / 2.0 + 0.03 * phr * Vr1)) + xM0;

          /*  first estimate might not be able to yield possible solution */
          if (phr > 1.0) {
            *exitflag = -1.0;
          } else {
            /*  second estimate (only if m > 0) */
            guard1 = true;
          }
        } else {
          if (Td > 0.0) {
            st.site = &vc_emlrtRSI;
            b_st.site = &nb_emlrtRSI;
            c_st.site = &ob_emlrtRSI;
            Vr1 = mcrsprd / (b_gamma / 2.0 - TmTM * (b_gamma / 2.0 / (T0 -
              mcrsprd) - 1.0 / (xM0 * xM0)));
            st.site = &vc_emlrtRSI;
            b_sqrt(&st, &Vr1);
            phr = xM0 - Vr1;
          } else {
            TmTM = Td / (4.0 - Td);
            Vr1 = 2.0 * (1.0 - phr);
            st.site = &wc_emlrtRSI;
            b_sqrt(&st, &Vr1);
            mcrsprd = TmTM + 1.7 * Vr1;
            if (!(mcrsprd >= 0.0)) {
              st.site = &xc_emlrtRSI;
              b_st.site = &nb_emlrtRSI;
              c_st.site = &ob_emlrtRSI;
              Vr1 = muDoubleScalarPower(-mcrsprd, 0.125);
              st.site = &xc_emlrtRSI;
              b_sqrt(&st, &Vr1);
              mcrsprd = -Td / (1.5 * T0 - Td);
              st.site = &xc_emlrtRSI;
              b_sqrt(&st, &mcrsprd);
              TmTM -= Vr1 * (TmTM + mcrsprd);
            }

            mcrsprd = 4.0 / (4.0 - Td);
            Vr1 = mcrsprd;
            st.site = &yc_emlrtRSI;
            b_sqrt(&st, &Vr1);
            phr = TmTM * (1.0 + ((1.0 + m) + 0.24 * (dth - 0.5)) / (1.0 + 0.15 *
              m) * TmTM * (mcrsprd / 2.0 - 0.03 * TmTM * Vr1));
          }

          /*  estimate might not give solutions */
          if (phr < -1.0) {
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
    /*  (Halley's method) */
    mcrsprd = rtInf;
    iterations = 0;
    do {
      exitg1 = 0;
      if (muDoubleScalarAbs(mcrsprd) > 1.0E-12) {
        /*  iterations */
        iterations++;

        /*  compute function value, and first two derivatives */
        st.site = &ad_emlrtRSI;
        c_LancasterBlanchard(&st, phr, q, m, &mcrsprd, &Tp, &b_gamma);

        /*  find the root of the *difference* between the */
        /*  function value [T_x] and the required time [T] */
        mcrsprd -= T;

        /*  new value of x */
        TmTM = phr;
        st.site = &bd_emlrtRSI;
        b_st.site = &nb_emlrtRSI;
        c_st.site = &ob_emlrtRSI;
        phr -= 2.0 * mcrsprd * Tp / (2.0 * (Tp * Tp) - mcrsprd * b_gamma);

        /*  escape clause */
        Vr1 = c_mod(iterations);
        st.site = &cd_emlrtRSI;
        toLogicalCheck(&st, Vr1);
        if (Vr1 != 0.0) {
          phr = (TmTM + phr) / 2.0;
        }

        /*  Halley's method might fail */
        if (*emlrtBreakCheckR2012bFlagVar != 0) {
          emlrtBreakCheckR2012b(sp);
        }

        if (iterations > 25) {
          *exitflag = -2.0;
          exitg1 = 1;
        }
      } else {
        /*  calculate terminal velocities */
        /*  ----------------------------- */
        /*  constants required for this calculation */
        b_gamma = muC * s / 2.0;
        st.site = &dd_emlrtRSI;
        b_sqrt(&st, &b_gamma);
        if (c == 0.0) {
          leftbranch = 1.0;
          mcrsprd = 0.0;
          TmTM = muDoubleScalarAbs(phr);
        } else {
          st.site = &ed_emlrtRSI;
          b_st.site = &nb_emlrtRSI;
          c_st.site = &ob_emlrtRSI;
          TmTM = r1 * r2 / (c * c);
          st.site = &ed_emlrtRSI;
          if (TmTM < 0.0) {
            b_st.site = &lb_emlrtRSI;
            c_st.site = &lb_emlrtRSI;
            error(&c_st);
          }

          leftbranch = 2.0 * muDoubleScalarSqrt(TmTM) * muDoubleScalarSin(dth /
            2.0);
          mcrsprd = (r1 - r2) / c;
          st.site = &fd_emlrtRSI;
          b_st.site = &nb_emlrtRSI;
          c_st.site = &ob_emlrtRSI;
          st.site = &fd_emlrtRSI;
          b_st.site = &nb_emlrtRSI;
          c_st.site = &ob_emlrtRSI;
          st.site = &fd_emlrtRSI;
          TmTM = 1.0 + q * q * (phr * phr - 1.0);
          if (TmTM < 0.0) {
            b_st.site = &lb_emlrtRSI;
            c_st.site = &lb_emlrtRSI;
            error(&c_st);
          }

          TmTM = muDoubleScalarSqrt(TmTM);
        }

        /*  radial component */
        Vr1 = b_gamma * ((q * TmTM - phr) - mcrsprd * (q * TmTM + phr)) / r1;
        xM0 = -b_gamma * ((q * TmTM - phr) + mcrsprd * (q * TmTM + phr)) / r2;

        /*  tangential component */
        xMp = leftbranch * b_gamma * (TmTM + q * phr) / r1;
        mcrsprd = leftbranch * b_gamma * (TmTM + q * phr) / r2;

        /*  Cartesian velocity */
        for (iterations = 0; iterations < 3; iterations++) {
          V1[iterations] = xMp * th1unit[iterations] + Vr1 * r1unit[iterations];
          V2[iterations] = mcrsprd * crsprod[iterations] + xM0 *
            r2unit[iterations];
        }

        /*  exitflag */
        *exitflag = 1.0;

        /*  (success) */
        /*  also determine minimum/maximum distance */
        st.site = &gd_emlrtRSI;
        b_st.site = &nb_emlrtRSI;
        c_st.site = &ob_emlrtRSI;

        /*  semi-major axis */
        st.site = &hd_emlrtRSI;
        minmax_distances(&st, r1vec, r1, r1vec, r2, dth, s / 2.0 / (1.0 - phr *
          phr), V1, V2, m, muC, extremal_distances);
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
  real_T theta1;
  int32_T k;
  real_T absxk;
  real_T theta2;
  real_T evec[3];
  real_T e;
  real_T pericenter;
  real_T apocenter;
  real_T b_y;
  real_T c_y;
  real_T d_y;
  int32_T exponent;
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;

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
  theta1 = 0.0;
  for (k = 0; k < 3; k++) {
    y += V1[k] * V1[k];
    theta1 += V1[k] * r1vec[k];
  }

  /*  eccentricity */
  absxk = 0.0;
  for (k = 0; k < 3; k++) {
    theta2 = (y * r1vec[k] - theta1 * V1[k]) / muC - r1vec[k] / r1;
    absxk += theta2 * theta2;
    evec[k] = theta2;
  }

  st.site = &be_emlrtRSI;
  if (absxk < 0.0) {
    b_st.site = &lb_emlrtRSI;
    c_st.site = &lb_emlrtRSI;
    error(&c_st);
  }

  e = muDoubleScalarSqrt(absxk);

  /*  apses */
  pericenter = a * (1.0 - e);
  apocenter = rtInf;

  /*  parabolic/hyperbolic case */
  if (e < 1.0) {
    apocenter = a * (1.0 + e);
  }

  /*  elliptic case */
  /*  since we have the eccentricity vector, we know exactly where the */
  /*  pericenter lies. Use this fact, and the given value of [dth], to */
  /*  cross-check if the trajectory goes past it */
  if (m > 0.0) {
    /*  obvious case (always elliptical and both apses are traversed) */
    minimum_distance = pericenter;
    maximum_distance = apocenter;
  } else {
    /*  less obvious case */
    /*  compute theta1&2 ( use (AxB)-(CxD) = (C·B)(D·A) - (C·A)(B·D) )) */
    y = 0.0;
    theta1 = 0.0;
    theta2 = 0.0;
    b_y = 0.0;
    c_y = 0.0;
    d_y = 0.0;

    /*  make 100.4% sure it's in (-1 <= theta12 <= +1) */
    absxk = 0.0;
    for (k = 0; k < 3; k++) {
      y += evec[k] * V1[k];
      theta1 += r1vec[k] * evec[k];
      theta2 += r1vec[k] * V1[k];
      b_y += evec[k] * V2[k];
      c_y += r2vec[k] * evec[k];
      d_y += r2vec[k] * V2[k];
      absxk += r1vec[k] / r1 * (evec[k] / e);
    }

    absxk = muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, absxk));
    st.site = &ce_emlrtRSI;
    b_acos(&st, &absxk);
    theta1 = muDoubleScalarSign(r1 * r1 * y - theta1 * theta2) * absxk;
    y = 0.0;
    for (k = 0; k < 3; k++) {
      y += r2vec[k] / r2 * (evec[k] / e);
    }

    absxk = muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, y));
    st.site = &de_emlrtRSI;
    b_acos(&st, &absxk);
    theta2 = muDoubleScalarSign(r2 * r2 * b_y - c_y * d_y) * absxk;

    /*  points 1&2 are on opposite sides of the symmetry axis -- minimum */
    /*  and maximum distance depends both on the value of [dth], and both */
    /*  [theta1] and [theta2] */
    if (theta1 * theta2 < 0.0) {
      /*  if |th1| + |th2| = turnangle, we know that the pericenter was */
      /*  passed */
      st.site = &ee_emlrtRSI;
      absxk = muDoubleScalarAbs(dth);
      if ((!muDoubleScalarIsInf(absxk)) && (!muDoubleScalarIsNaN(absxk))) {
        if (absxk <= 2.2250738585072014E-308) {
          absxk = 4.94065645841247E-324;
        } else {
          frexp(absxk, &exponent);
          absxk = ldexp(1.0, exponent - 53);
        }
      } else {
        absxk = rtNaN;
      }

      if (muDoubleScalarAbs((muDoubleScalarAbs(theta1) + muDoubleScalarAbs
                             (theta2)) - dth) < 5.0 * absxk) {
        minimum_distance = pericenter;

        /*  this condition can only be false for elliptic cases, and */
        /*  when it is indeed false, we know that the orbit passed */
        /*  apocenter */
      } else {
        maximum_distance = apocenter;
      }

      /*  points 1&2 are on the same side of the symmetry axis. Only if the */
      /*  long-way was used are the min. and max. distances different from */
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
  int32_T k;
  real_T powers[25];
  real_T b_y;
  real_T dv1[25];
  static const int16_T iv0[25] = { 0, 2, 6, 12, 20, 30, 42, 56, 72, 90, 110, 132,
    156, 182, 210, 240, 272, 306, 342, 380, 420, 462, 506, 552, 600 };

  static const int16_T iv1[25] = { 0, 0, 6, 24, 60, 120, 210, 336, 504, 720, 990,
    1320, 1716, 2184, 2730, 3360, 4080, 4896, 5814, 6840, 7980, 9240, 10626,
    12144, 13800 };

  /*  series approximation to T(x) and its derivatives */
  /*  (used for near-parabolic cases) */
  /*  preload the factors [an] */
  /*  (25 factors is more than enough for 16-digit accuracy) */
  /*  powers of y */
  for (k = 0; k < 25; k++) {
    powers[k] = muDoubleScalarPower(y, 1.0 + (((real_T)k + 1.0) - 1.0));
  }

  /*  sigma itself */
  b_y = 0.0;
  for (k = 0; k < 25; k++) {
    b_y += powers[k] * an[k];
  }

  *sig = 1.3333333333333333 + b_y;

  /*  dsigma / dx (derivative) */
  dv1[0] = 1.0;
  memcpy(&dv1[1], &powers[0], 24U * sizeof(real_T));
  *dsigdx = 0.0;
  for (k = 0; k < 25; k++) {
    *dsigdx += (1.0 + (real_T)k) * dv1[k] * an[k];
  }

  /*  d2sigma / dx2 (second derivative) */
  dv1[0] = 1.0 / y;
  dv1[1] = 1.0;
  memcpy(&dv1[2], &powers[0], 23U * sizeof(real_T));
  *d2sigdx2 = 0.0;
  for (k = 0; k < 25; k++) {
    *d2sigdx2 += (real_T)iv0[k] * dv1[k] * an[k];
  }

  /*  d3sigma / dx3 (third derivative) */
  dv1[0] = 1.0 / y / y;
  dv1[1] = 1.0 / y;
  dv1[2] = 1.0;
  memcpy(&dv1[3], &powers[0], 22U * sizeof(real_T));
  *d3sigdx3 = 0.0;
  for (k = 0; k < 25; k++) {
    *d3sigdx3 += (real_T)iv1[k] * dv1[k] * an[k];
  }
}

void an_not_empty_init(void)
{
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
  real_T inn1;
  real_T dth;
  real_T leftbranch;
  real_T longway;
  real_T c;
  real_T s;
  real_T a_min;
  real_T tof;
  real_T Lambda;
  real_T crossprd[3];
  real_T mcr;
  real_T logt;
  real_T x1;
  real_T x2;
  real_T xx[2];
  real_T aa[2];
  real_T bbeta[2];
  real_T a;
  real_T aalfa[2];
  real_T minval[2];
  real_T dv0[2];
  real_T y2;
  real_T err;
  real_T xnew;
  boolean_T exitg1;
  real_T b_r2vec[3];
  real_T r2n[3];
  real_T Vt1[3];
  real_T Vt2[3];
  emlrtStack st;
  emlrtStack b_st;
  emlrtStack c_st;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;

  /*  LAMBERT            Lambert-targeter for ballistic flights */
  /*                     (Izzo, and Lancaster, Blanchard & Gooding) */
  /*  */
  /*  Usage: */
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
  /*  solvers; the first one tried is a new and unpublished algorithm developed */
  /*  by Dr. D. Izzo from the European Space Agency [1]. This version is extremely */
  /*  fast, but especially for larger [m] it still fails quite frequently. In such */
  /*  cases, a MUCH more robust algorithm is started (the one by Lancaster & */
  /*  Blancard [2], with modifcations, initial values and other improvements by */
  /*  R.Gooding [3]), which is a lot slower partly because of its robustness. */
  /*  */
  /*  INPUT ARGUMENTS: */
  /*  ====================================================================== */
  /*     name        units    description */
  /*  ====================================================================== */
  /*    r1, r1       [km]     position vectors of the two terminal points. */
  /*      tf        [days]    time of flight to solve for */
  /*       m          [-]     specifies the number of complete orbits to complete */
  /*                          (should be an integer) */
  /*  GM_central   [km3/s2]   std. grav. parameter (G�M = mu) of the central body */
  /*  */
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
  /*                              algorithm. */
  /*  */
  /*  This routine can be compiled to increase its speed by a factor of about */
  /*  10-15, which is certainly advisable when the complete application requires */
  /*  a great number of Lambert problems to be solved. The entire routine is */
  /*  written in embedded MATLAB, so it can be compiled with the emlmex() */
  /*  function (older MATLAB) or codegen() function (MATLAB 2011a and later). */
  /*  */
  /*  To do this using emlmex(), make sure MATLAB's current directory is equal */
  /*  to where this file is located. Then, copy-paste and execute the following */
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
  /*  This is of course assuming your compiler is configured correctly. See the */
  /*  documentation of emlmex() on how to do that. */
  /*  */
  /*  Using codegen(), the syntax is as follows: */
  /*  */
  /*     example_input = {... */
  /*          [0.0, 0.0, 0.0], ...% r1vec */
  /*          [0.0, 0.0, 0.0], ...% r2vec */
  /*           0.0, ...           % tf */
  /*           0.0, ...           % m */
  /*           0.0};              % muC */
  /*     codegen lambert.m -args example_input */
  /*  */
  /*  Note that in newer MATLAB versions, the code analyzer will complain about */
  /*  the pragma "%#eml" after the main function's name, and possibly, issue */
  /*  subsequent warnings related to this issue. To get rid of this problem, simply */
  /*  replace the "%#eml" directive with "%#codegen". */
  /*  */
  /*  */
  /*  */
  /*  References: */
  /*  */
  /*  [1] Izzo, D. ESA Advanced Concepts team. Code used available in MGA.M, on */
  /*      http://www.esa.int/gsp/ACT/inf/op/globopt.htm. Last retreived Nov, 2009. */
  /*  [2] Lancaster, E.R. and Blanchard, R.C. "A unified form of Lambert's theorem." */
  /*      NASA technical note TN D-5368,1969. */
  /*  [3] Gooding, R.H. "A procedure for the solution of Lambert's orbital boundary-value */
  /*      problem. Celestial Mechanics and Dynamical Astronomy, 48:145�165,1990. */
  /*  */
  /*  See also lambert_low_ExpoSins. */
  /*  Please report bugs and inquiries to: */
  /*  */
  /*  Name       : Rody P.S. Oldenhuis */
  /*  E-mail     : oldenhuis@gmail.com */
  /*  Licence    : 2-clause BSD (see License.txt) */
  /*  If you find this work useful, please consider a donation: */
  /*  https://www.paypal.me/RodyO/3.5 */
  /*  If you want to cite this work in an academic paper, please use */
  /*  the following template: */
  /*  */
  /*  Rody Oldenhuis, orcid.org/0000-0002-3162-3660. "Lambert" <version>, */
  /*  <date you last used it>. MATLAB Robust solver for Lambert's */
  /*  orbital-boundary value problem. */
  /*  https://nl.mathworks.com/matlabcentral/fileexchange/26348 */
  /*  ----------------------------------------------------------------- */
  /*  Izzo's version: */
  /*  Very fast, but not very robust for more complicated cases */
  /*  ----------------------------------------------------------------- */
  /* #coder */
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
  /*  please report bugs to dario.izzo@esa.int */
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
  /*  initial values */
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
  inn1 = 0.0;
  for (iterations = 0; iterations < 3; iterations++) {
    inn1 += r1vec[iterations] * r2vec[iterations];
  }

  dth = muDoubleScalarMax(-1.0, muDoubleScalarMin(1.0, inn1 / mr2vec));
  st.site = &d_emlrtRSI;
  b_acos(&st, &dth);

  /*  decide whether to use the left or right branch (for multi-revolution */
  /*  problems), and the long- or short way */
  leftbranch = muDoubleScalarSign(m);
  longway = muDoubleScalarSign(tf);
  m = muDoubleScalarAbs(m);
  tf = muDoubleScalarAbs(tf);
  if (longway < 0.0) {
    dth = 6.2831853071795862 - dth;
  }

  /*  derived quantities */
  st.site = &e_emlrtRSI;
  b_st.site = &nb_emlrtRSI;
  c = (1.0 + mr2vec * mr2vec) - 2.0 * mr2vec * muDoubleScalarCos(dth);
  st.site = &e_emlrtRSI;
  b_sqrt(&st, &c);

  /*  non-dimensional chord */
  s = ((1.0 + mr2vec) + c) / 2.0;

  /*  non-dimensional semi-perimeter */
  a_min = s / 2.0;

  /*  minimum energy ellipse semi major axis */
  tof = mr2vec;
  st.site = &f_emlrtRSI;
  b_sqrt(&st, &tof);
  Lambda = tof * muDoubleScalarCos(dth / 2.0) / s;

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
    /*  initial values */
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
  power(xx, aa);
  inn1 = (s - c) / 2.0;
  for (iterations = 0; iterations < 2; iterations++) {
    tof = a_min / (1.0 - aa[iterations]);
    bbeta[iterations] = inn1 / tof;
    aa[iterations] = tof;
  }

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

  /*  evaluate the time of flight via Lagrange expression */
  for (iterations = 0; iterations < 2; iterations++) {
    xx[iterations] = aa[iterations];
    aalfa[iterations] *= 2.0;
  }

  st.site = &m_emlrtRSI;
  c_sqrt(&st, xx);
  for (iterations = 0; iterations < 2; iterations++) {
    minval[iterations] = aalfa[iterations];
  }

  b_sin(minval);
  for (iterations = 0; iterations < 2; iterations++) {
    dv0[iterations] = bbeta[iterations];
  }

  b_sin(dv0);
  tof = 6.2831853071795862 * m;
  for (iterations = 0; iterations < 2; iterations++) {
    aa[iterations] = aa[iterations] * xx[iterations] * (((aalfa[iterations] -
      minval[iterations]) - (bbeta[iterations] - dv0[iterations])) + tof);
  }

  /*  initial estimates for y */
  if (m == 0.0) {
    tof = aa[0];
    st.site = &n_emlrtRSI;
    b_log(&st, &tof);
    inn2 = tof - logt;
    tof = aa[1];
    st.site = &o_emlrtRSI;
    b_log(&st, &tof);
    y2 = tof - logt;
  } else {
    inn2 = aa[0] - tf;
    y2 = aa[1] - tf;
  }

  /*  Solve for x */
  /*  --------------------------------------------------------- */
  /*  Newton-Raphson iterations */
  /*  NOTE - the number of iterations will go to infinity in case */
  /*  m > 0  and there is no solution. Start the other routine in */
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
      x1 = muDoubleScalarExp(xnew) - 1.0;
    } else {
      x1 = muDoubleScalarAtan(xnew) * 2.0 / 3.1415926535897931;
    }

    st.site = &p_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    a = a_min / (1.0 - x1 * x1);
    if (x1 < 1.0) {
      /*  ellipse */
      tof = (s - c) / 2.0 / a;
      st.site = &q_emlrtRSI;
      b_sqrt(&st, &tof);
      st.site = &q_emlrtRSI;
      c_asin(&st, &tof);
      inn2 = longway * 2.0 * tof;

      /*  make 100.4% sure it's in (-1 <= xx <= +1) */
      tof = muDoubleScalarMax(-1.0, x1);
      st.site = &r_emlrtRSI;
      b_acos(&st, &tof);
      inn1 = 2.0 * tof;
    } else {
      /*  hyperbola */
      st.site = &s_emlrtRSI;
      b_acosh(&st, &x1);
      inn1 = 2.0 * x1;
      tof = (s - c) / (-2.0 * a);
      st.site = &t_emlrtRSI;
      b_sqrt(&st, &tof);
      b_asinh(&tof);
      inn2 = longway * 2.0 * tof;
    }

    /*  evaluate the time of flight via Lagrange expression */
    if (a > 0.0) {
      tof = a;
      st.site = &u_emlrtRSI;
      b_sqrt(&st, &tof);
      tof = a * tof * (((inn1 - muDoubleScalarSin(inn1)) - (inn2 -
        muDoubleScalarSin(inn2))) + 6.2831853071795862 * m);
    } else {
      tof = -a;
      st.site = &v_emlrtRSI;
      b_sqrt(&st, &tof);
      tof = -a * tof * ((muDoubleScalarSinh(inn1) - inn1) - (muDoubleScalarSinh
        (inn2) - inn2));
    }

    /*  new value of y */
    if (m == 0.0) {
      st.site = &w_emlrtRSI;
      b_log(&st, &tof);
      inn1 = tof - logt;
    } else {
      inn1 = tof - tf;
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
    if (*emlrtBreakCheckR2012bFlagVar != 0) {
      emlrtBreakCheckR2012b(sp);
    }

    if (iterations > 15) {
      bad = true;
      exitg1 = true;
    }
  }

  /*  If the Newton-Raphson scheme failed, try to solve the problem */
  /*  with the other Lambert targeter. */
  if (bad) {
    /*  NOTE: use the original, UN-normalized quantities */
    for (iterations = 0; iterations < 3; iterations++) {
      crossprd[iterations] = r1vec[iterations] * r1;
      b_r2vec[iterations] = r2vec[iterations] * r1;
    }

    st.site = &x_emlrtRSI;
    lambert_LancasterBlanchard(&st, crossprd, b_r2vec, longway * tf * T,
      leftbranch * m, muC, V1, V2, extremal_distances, exitflag);
  } else {
    /*  convert converged value of x */
    if (m == 0.0) {
      x1 = muDoubleScalarExp(xnew) - 1.0;
    } else {
      x1 = muDoubleScalarAtan(xnew) * 2.0 / 3.1415926535897931;
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
    st.site = &y_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    a = a_min / (1.0 - x1 * x1);

    /*  Calculate psi */
    if (x1 < 1.0) {
      /*  ellipse */
      tof = (s - c) / 2.0 / a;
      st.site = &ab_emlrtRSI;
      b_sqrt(&st, &tof);
      st.site = &ab_emlrtRSI;
      c_asin(&st, &tof);

      /*  make 100.4% sure it's in (-1 <= xx <= +1) */
      inn1 = muDoubleScalarMax(-1.0, x1);
      st.site = &bb_emlrtRSI;
      b_acos(&st, &inn1);
      inn1 = muDoubleScalarSin((2.0 * inn1 - longway * 2.0 * tof) / 2.0);
      st.site = &cb_emlrtRSI;
      b_st.site = &nb_emlrtRSI;
      tof = 2.0 * a * (inn1 * inn1) / s;
      st.site = &db_emlrtRSI;
      if (tof < 0.0) {
        b_st.site = &lb_emlrtRSI;
        c_st.site = &lb_emlrtRSI;
        error(&c_st);
      }

      inn2 = muDoubleScalarSqrt(tof);
    } else {
      /*  hyperbola */
      inn1 = (c - s) / 2.0 / a;
      st.site = &eb_emlrtRSI;
      if (inn1 < 0.0) {
        b_st.site = &lb_emlrtRSI;
        c_st.site = &lb_emlrtRSI;
        error(&c_st);
      }

      tof = x1;
      st.site = &fb_emlrtRSI;
      b_acosh(&st, &tof);
      inn1 = muDoubleScalarSqrt(inn1);
      b_asinh(&inn1);
      inn1 = muDoubleScalarSinh((2.0 * tof - longway * 2.0 * inn1) / 2.0);
      st.site = &gb_emlrtRSI;
      b_st.site = &nb_emlrtRSI;
      tof = -2.0 * a * (inn1 * inn1) / s;
      st.site = &hb_emlrtRSI;
      if (tof < 0.0) {
        b_st.site = &lb_emlrtRSI;
        c_st.site = &lb_emlrtRSI;
        error(&c_st);
      }

      inn2 = muDoubleScalarSqrt(tof);
    }

    /*  unit of the normalized normal vector */
    /*  unit vector for normalized [r2vec] */
    for (iterations = 0; iterations < 3; iterations++) {
      r2n[iterations] = r2vec[iterations] / mr2vec;
      crossprd[iterations] = longway * (crossprd[iterations] / mcr);
    }

    /*  cross-products */
    /*  don't use cross() (emlmex() would try to compile it, and this way it */
    /*  also does not create any additional overhead) */
    /*  radial and tangential directions for departure velocity */
    st.site = &ib_emlrtRSI;
    if (a_min < 0.0) {
      b_st.site = &lb_emlrtRSI;
      c_st.site = &lb_emlrtRSI;
      error(&c_st);
    }

    err = 1.0 / inn2 / muDoubleScalarSqrt(a_min) * ((2.0 * Lambda * a_min -
      Lambda) - x1 * inn2);
    inn1 = muDoubleScalarSin(dth / 2.0);
    st.site = &jb_emlrtRSI;
    b_st.site = &nb_emlrtRSI;
    st.site = &jb_emlrtRSI;
    x1 = mr2vec / a_min / tof * (inn1 * inn1);
    if (x1 < 0.0) {
      b_st.site = &lb_emlrtRSI;
      c_st.site = &lb_emlrtRSI;
      error(&c_st);
    }

    inn2 = muDoubleScalarSqrt(x1);

    /*  radial and tangential directions for arrival velocity */
    inn1 = inn2 / mr2vec;
    tof = (inn2 - inn1) / muDoubleScalarTan(dth / 2.0) - err;

    /*  terminal velocities */
    Vt1[0] = inn2 * (crossprd[1] * r1vec[2] - crossprd[2] * r1vec[1]);
    Vt1[1] = inn2 * (crossprd[2] * r1vec[0] - crossprd[0] * r1vec[2]);
    Vt1[2] = inn2 * (crossprd[0] * r1vec[1] - crossprd[1] * r1vec[0]);
    Vt2[0] = inn1 * (crossprd[1] * r2n[2] - crossprd[2] * r2n[1]);
    Vt2[1] = inn1 * (crossprd[2] * r2n[0] - crossprd[0] * r2n[2]);
    Vt2[2] = inn1 * (crossprd[0] * r2n[1] - crossprd[1] * r2n[0]);

    /*  exitflag */
    *exitflag = 1.0;

    /*  (success) */
    /*  also compute minimum distance to central body */
    /*  NOTE: use un-transformed vectors again! */
    for (iterations = 0; iterations < 3; iterations++) {
      V1[iterations] = (err * r1vec[iterations] + Vt1[iterations]) * V;
      V2[iterations] = (tof * r2n[iterations] + Vt2[iterations]) * V;
      crossprd[iterations] = r1vec[iterations] * r1;
      b_r2vec[iterations] = r2vec[iterations] * r1;
    }

    st.site = &kb_emlrtRSI;
    minmax_distances(&st, crossprd, r1, b_r2vec, mr2vec * r1, dth, a * r1, V1,
                     V2, m, muC, extremal_distances);
  }
}

void sigmax_init(void)
{
  static const real_T dv2[25] = { 0.4, 0.2142857142857143, 0.0462962962962963,
    0.006628787878787879, 0.00072115384615384609, 6.36574074074074E-5,
    4.7414799253034548E-6, 3.0594063283208018E-7, 1.74283640925506E-8,
    8.8924773311095776E-10, 4.1101115319865317E-11, 1.7367093848414581E-12,
    6.7597672400414259E-14, 2.4391233866140258E-15, 8.2034116145380068E-17,
    2.583771576869575E-18, 7.6523313279767163E-20, 2.138860629743989E-21,
    5.6599594511655524E-23, 1.4221048338173659E-24, 3.4013984832723061E-26,
    7.7625443047741554E-28, 1.693916882090479E-29, 3.54129500676686E-31,
    7.1053361878044024E-33 };

  memcpy(&an[0], &dv2[0], 25U * sizeof(real_T));
}

/* End of code generation (lambert.c) */
