/*------------------------------------------------------------------------------*/
/** 
 *  \file   Stdafx.h
 *  \brief  Include for precompiled header.
 *  \author Gabriel Peyr�
 *  \date   10-26-2002
 */ 
/*------------------------------------------------------------------------------*/
#ifndef _GW_TOOLKIT_STDAFX_H_
#define _GW_TOOLKIT_STDAFX_H_

#pragma once

/* 'identifier' : identifier was truncated to 'number' characters in the debug information */
#pragma warning( disable : 4786 )

//-------------------------------------------------------------------------
/** \name C++ STL */
//-------------------------------------------------------------------------
//@{
#include <algorithm>
#include <map>
#include <vector>
#include <list>
#include <string>
#include <iostream>
#include <fstream>
using std::string;
using std::cerr;
using std::cout;
using std::endl;
//@}

//-------------------------------------------------------------------------
/** \name classical ANSI c libraries */
//-------------------------------------------------------------------------
//@{
#include <stdio.h>			
#include <math.h>
#include <float.h>
#include <stdlib.h>
#include <fcntl.h>
#include <time.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <fstream>
#include <iostream>
//#include <ios>
#include <stdarg.h>
#include <conio.h>
#include <crtdbg.h>
//@}



/*----------------------------------------------------------------------*/
/* win32 #include                                                       */
/*----------------------------------------------------------------------*/

#ifdef WIN32
	#define WIN32_LEAN_AND_MEAN
	/** main win32 header */
	#include <windows.h>
#endif // _USE_WIN32_

#include "../gw_core/GW_MathsWrapper.h"

#endif // _STDAFX_H_


///////////////////////////////////////////////////////////////////////////////
//  Copyright (c) Gabriel Peyr�
///////////////////////////////////////////////////////////////////////////////
//                               END OF FILE                                 //
///////////////////////////////////////////////////////////////////////////////
