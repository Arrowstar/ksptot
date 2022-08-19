
/*------------------------------------------------------------------------------*/
/** 
 *  \file   GW_VertexIterator.h
 *  \brief  Definition of class \c GW_VertexIterator
 *  \author Gabriel Peyr�
 *  \date   4-2-2003
 */ 
/*------------------------------------------------------------------------------*/

#ifndef _GW_VERTEXITERATOR_H_
#define _GW_VERTEXITERATOR_H_

#include "GW_Config.h"

namespace GW {

class GW_Face; 
class GW_Vertex;

/*------------------------------------------------------------------------------*/
/** 
 *  \class  GW_VertexIterator
 *  \brief  An iterator on the vertex around a given vertex.
 *  \author Gabriel Peyr�
 *  \date   4-2-2003
 *
 *  To iterate on vertex.
 */ 
/*------------------------------------------------------------------------------*/

class GW_VertexIterator
{

public:

	GW_VertexIterator(  GW_Face* pFace, GW_Vertex* pOrigin, GW_Vertex* pDirection, GW_Face* pPrevFace, GW_U32 nNbrIncrement = 0 );

	/* assignement */
	GW_VertexIterator& operator=( const GW_VertexIterator& it);

	/* evaluation */
	GW_Bool operator==( const GW_VertexIterator& it);
	GW_Bool operator!=( const GW_VertexIterator& it);

	/* indirection */
	GW_Vertex* operator*(  );

	/* progression */
	void operator++();

	GW_Face* GetLeftFace();
	GW_Face* GetRightFace();

	GW_Vertex* GetLeftVertex();
	GW_Vertex* GetRightVertex();

private:

	GW_Face* pFace_;
	GW_Vertex* pOrigin_;
	GW_Vertex* pDirection_;
	/* this is needed only for saving time on border edge */
	GW_Face* pPrevFace_;

	/** just for debug purpose */
	GW_U32 nNbrIncrement_;

};

} // End namespace GW

#endif // _GW_VERTEXITERATOR_H_


///////////////////////////////////////////////////////////////////////////////
//  Copyright (c) Gabriel Peyr�
///////////////////////////////////////////////////////////////////////////////
//                               END OF FILE                                 //
///////////////////////////////////////////////////////////////////////////////
