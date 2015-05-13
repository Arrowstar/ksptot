/*
 * dotARH_types.h
 *
 * Code generation for function 'dotARH'
 *
 * C source code generated on: Sun Feb 02 16:40:17 2014
 *
 */

#ifndef __DOTARH_TYPES_H__
#define __DOTARH_TYPES_H__

/* Include files */
#include "rtwtypes.h"

/* Type Definitions */
#ifndef typedef_ResolvedFunctionInfo
#define typedef_ResolvedFunctionInfo
typedef struct
{
    const char * context;
    const char * name;
    const char * dominantType;
    const char * resolved;
    uint32_T fileTimeLo;
    uint32_T fileTimeHi;
    uint32_T mFileTimeLo;
    uint32_T mFileTimeHi;
} ResolvedFunctionInfo;
#endif /*typedef_ResolvedFunctionInfo*/

#endif
/* End of code generation (dotARH_types.h) */
