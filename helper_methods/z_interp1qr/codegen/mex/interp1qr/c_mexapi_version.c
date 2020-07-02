#include <mex.h>
#if defined(MX_COMPAT_32) || defined(MX_COMPAT_64) || !defined(USE_MEX_CMD) || TARGET_API_VERSION >= 800
#define MX_TMP_TARGET_API_VER MX_TARGET_API_VER
#else
#define MX_TMP_TARGET_API_VER 0
#endif
MEXFUNCTION_LINKAGE
void mexfilerequiredapiversion(unsigned int* built_by_rel, unsigned int* target_api_ver)
{
  *built_by_rel = 0x2017b;
  *target_api_ver = MX_TMP_TARGET_API_VER;
} 

