#include "mex.h"
#include "anisotropic-fm/AnisotropicTensorDistance.h"
#include "anisotropic-fm/AnisotropicTensorDistanceConfidence.h"

using namespace std;
using namespace FastLevelSet;

#define start_points_(i,j) start_points[i+j*3]

// D = perform_front_propagation_anisotropic(tensor_data, mask, alpha, start_points);

void mexFunction(int nlhs, mxArray *plhs[], 
				 int nrhs, const mxArray*prhs[] ) 
{ 
	if( nrhs!=4 )
		mexErrMsgTxt("4 needed input : tensor, mask, alpha, start_points");
	if( nlhs!=1 ) 
		mexErrMsgTxt("1 output argument is required.");
		
	if( mxGetNumberOfDimensions(prhs[0])!= 4 )
		mexErrMsgTxt("tensor_data must be a 4D array.");
	if( mxGetNumberOfDimensions(prhs[1])!= 3 )
		mexErrMsgTxt("tensor must be a 3D array.");

	// input
	double *tensor_data = mxGetPr(prhs[0]); // tensor field
	double *mask_data = mxGetPr(prhs[1]); 	// mask field
	double alpha = mxGetScalar(prhs[2]); 	// alpha
	double* start_points = mxGetPr(prhs[3]);	// starting points
	int nstart = mxGetN(prhs[3]); // number of starting points

	if( mxGetM(prhs[3])!=3 )
		mexErrMsgTxt("start_points should be of size (3,p).");
	
    // width, height, depth
    int w = mxGetDimensions(prhs[0])[0];
	int h = mxGetDimensions(prhs[0])[1];
	int d = mxGetDimensions(prhs[0])[2];

	// number of dimensions for tensor field
    const int ndims = 6;

	// output
	int dims[3] = {w, h, d};
	plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
	double *dist_data = mxGetPr(plhs[0]);
    
    int size = w*h*d;
    
    for(int i=0; i<size; i++)
        dist_data[i] = FLT_MAX;
		
#if 0
	double *tensor_power_data;
    tensor_power_data = reinterpret_cast<double*> (malloc(size*ndims*sizeof(double)));
    for(int i=0; i<size*ndims; i++)
		tensor_power_data[i] = tensor_data[i];
#endif
    
    // Fast marching initialization
    AnisotropicTensorDistanceConfidence<double> march(dist_data,
													 w,h,d,
													 mask_data,
													 tensor_data,
													 NULL, // tensor_power_data,
													 alpha);    
	// set up starting points
	for( int i=0; i<nstart; ++i )
	{
		int x0 = start_points_(0,i);
		int y0 = start_points_(1,i);
		int z0 = start_points_(2,i);
		dist_data[z0*w*h + y0*h + x0] = 0;
	    march.AddTrialPoint(x0,y0,z0);	
	}

    // Compute the distance function, the optimal dynamics and confidence statistics, within the mask
    march.Run();
}
