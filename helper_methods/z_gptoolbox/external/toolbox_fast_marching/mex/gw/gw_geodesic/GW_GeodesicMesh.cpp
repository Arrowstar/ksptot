/*------------------------------------------------------------------------------*/
/** 
 *  \file   GW_GeodesicMesh.cpp
 *  \brief  Definition of class \c GW_GeodesicMesh
 *  \author Gabriel Peyr�
 *  \date   4-9-2003
 */ 
/*------------------------------------------------------------------------------*/


#ifdef GW_SCCSID
    static const char* sccsid = "@(#) GW_GeodesicMesh.cpp(c) Gabriel Peyr�2003";
#endif // GW_SCCSID

#include "stdafx.h"
#include "GW_GeodesicMesh.h"

#ifndef GW_USE_INLINE
    #include "GW_GeodesicMesh.inl"
#endif

using namespace GW;

GW_Bool GW_GeodesicMesh::bUseUnfolding_ = GW_True;

/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::ResetGeodesicMesh
/**
 *  \author Gabriel Peyr�
 *  \date   4-10-2003
 * 
 *  Reset the flags of all vertex for a new fast marching 
 *  computation.
 */
/*------------------------------------------------------------------------------*/
void GW_GeodesicMesh::ResetGeodesicMesh()
{
	for( IT_VertexVector it=VertexVector_.begin(); it!=VertexVector_.end(); ++it )
	{
		GW_GeodesicVertex* pVert = (GW_GeodesicVertex*) *it;
		pVert->ResetGeodesicVertex();
	}
	ActiveVertex_.clear();
}

/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::ResetParametrizationData
/**
 *  \author Gabriel Peyr�
 *  \date   4-27-2003
 * 
 *  Reset only the parametrization data of each vertex.
 */
/*------------------------------------------------------------------------------*/
void GW_GeodesicMesh::ResetParametrizationData()
{
	for( IT_VertexVector it=VertexVector_.begin(); it!=VertexVector_.end(); ++it )
	{
		GW_GeodesicVertex* pVert = (GW_GeodesicVertex*) *it;
		pVert->ResetParametrizationData();
	}
}



/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::PerformFastMarching
/**
 *  \param  StartVertex [GW_GeodesicVertex&] The starting point.
 *  \author Gabriel Peyr�
 *  \date   4-10-2003
 * 
 *  Compute geodesic distance from a vertex to other one.
 */
/*------------------------------------------------------------------------------*/
void GW_GeodesicMesh::PerformFastMarching( GW_GeodesicVertex* pStartVertex )
{	
	
	this->SetUpFastMarching( pStartVertex );

	// first time : set up the heap
	std::make_heap( ActiveVertex_.begin(), ActiveVertex_.end(), GW_GeodesicVertex::CompareVertex );
	/* main loop */
	while( !this->PerformFastMarchingOneStep() )
	{ }
}

/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::SetUpFastMarching
/**
 *  \param  pStartVertex=NULL [GW_GeodesicVertex*] A start vertex to add.
 *  \author Gabriel Peyr�
 *  \date   4-13-2003
 * 
 *  Just initialize the fast marching process.
 */
/*------------------------------------------------------------------------------*/
void GW_GeodesicMesh::SetUpFastMarching( GW_GeodesicVertex* pStartVertex )
{
	GW_ASSERT( WeightCallback_!=NULL );

	if( pStartVertex!=NULL )
		this->AddStartVertex( *pStartVertex );

	std::make_heap( ActiveVertex_.begin(), ActiveVertex_.end(), GW_GeodesicVertex::CompareVertex );

	bIsMarchingBegin_ = GW_True;
	bIsMarchingEnd_ = GW_False;
}

/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::PerformFastMarchingFlush
/**
 *  \author Gabriel Peyr�
 *  \date   4-13-2003
 * 
 *  Continue the algorithm until it termins.
 */
/*------------------------------------------------------------------------------*/
void GW_GeodesicMesh::PerformFastMarchingFlush()
{
	if( !bIsMarchingBegin_ )
		this->SetUpFastMarching();

	/* main loop */
	while( !this->PerformFastMarchingOneStep() )
	{ }
}



/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::IsFastMarchingFinished
/**
 *  \return [GW_Bool] Response.
 *  \author Gabriel Peyr�
 *  \date   4-13-2003
 * 
 *  Is the algorhm finished ?
 */
/*------------------------------------------------------------------------------*/
GW_Bool GW_GeodesicMesh::IsFastMarchingFinished()
{
	return bIsMarchingEnd_;
}


/*------------------------------------------------------------------------------*/
// Name : GW_GeodesicMesh::GetRandomVertex
/**
*  \return [GW_Vertex*] The vertex. NULL if it was impossible.
*  \author Gabriel Peyr�
*  \date   4-14-2003
* 
*  Get Return a vertex at random.
*/
/*------------------------------------------------------------------------------*/
GW_Vertex* GW_GeodesicMesh::GetRandomVertex(GW_Bool bForceFar)
{
	GW_U32 nNumber = 0;
	GW_GeodesicVertex* pStartVertex = NULL;
	while( pStartVertex==NULL )
	{
		if( nNumber>=this->GetNbrVertex()/10 )
			return NULL;
		GW_U32 nNumVert = (GW_U32) floor(GW_RAND*this->GetNbrVertex());
		pStartVertex = (GW_GeodesicVertex*) this->GetVertex( nNumVert );
		if( bForceFar==GW_True && pStartVertex->GetState()!=GW_GeodesicVertex::kFar )
			pStartVertex = NULL;
		if( pStartVertex!=NULL && pStartVertex->GetFace()==NULL )
			pStartVertex = NULL;
		nNumber++;
	}
	return pStartVertex;
}

///////////////////////////////////////////////////////////////////////////////
//  Copyright (c) Gabriel Peyr�
///////////////////////////////////////////////////////////////////////////////
//                               END OF FILE                                 //
///////////////////////////////////////////////////////////////////////////////
