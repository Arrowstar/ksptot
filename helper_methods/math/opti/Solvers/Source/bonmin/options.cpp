// Copyright (C) 2008 Peter Carbonetto. All Rights Reserved.
// This code is published under the Eclipse Public License.
//
// Author: Peter Carbonetto
//         Dept. of Computer Science
//         University of British Columbia
//         September 25, 2008

// Modified J.Currie September 2011 + Jan 2013 to suit BONMIN

#include "options.hpp"
#include "matlabexception.hpp"

// Function definitions for class Options.
// -----------------------------------------------------------------
Options::Options (const Iterate& x, BonminSetup& app, 
		  const mxArray* ptr) 
  : n(numvars(x)), m(0), nsos(0), lb(0), ub(0), cl(0), cu(0), zl(0), zu(0),
    lambda(0), var_type(0), var_lin(0), cons_lin(0), auxdata(0),

    // Process the BONMIN and IPOPT options.
    bonmin(app,ptr) { 

  double neginfty = bonmin.getNegInfty();  // Negative infinity.
  double posinfty = bonmin.getPosInfty();  // Positive infinity.

  // Load the bounds on the variables.
  lb = loadLowerBounds(n,ptr,neginfty);
  ub = loadUpperBounds(n,ptr,posinfty);

  // Load the bounds on the constraints.
  m = loadConstraintBounds(ptr,cl,cu,neginfty,posinfty,nlin,nnlin);

  // Load the Lagrange multipliers.
  loadMultipliers(n,m,ptr,zl,zu,lambda);
  
  // Load the MINLP Info
  var_type = loadVariableTypes(n,ptr);
  var_lin  = loadVariableLinearity(n,ptr);
  cons_lin = loadConstraintLinearity(m,nlin,nnlin,ptr);
  
  // Load the SOS constraints
  nsos = loadSOSConstraints(&sos_info,ptr);

  // Load the auxiliary data.
  auxdata = mxGetField(ptr,0,"auxdata");
}

Options::~Options() {
  if (lb) delete[] lb;
  if (ub) delete[] ub;
  if (cl) delete[] cl;
  if (cu) delete[] cu;
  if (var_type) delete[] var_type;
  if (var_lin) delete[] var_lin;
  if (cons_lin) delete[] cons_lin;
}

// Function definitions for static members of class Options.
// ----------------------------------------------------------------- 
double* Options::loadLowerBounds(int n, const mxArray* ptr, double neginfty) {
  double*        lb;  // The return value.
  const mxArray* p  = mxGetField(ptr,0,"lb");

  if (p) {

    // Load the upper bounds and check to make sure they are valid.
    int N = Iterate::getMatlabData(p,lb);
    if (N != n)
      throw MatlabException("Lower bounds array must have one element for each optimization variable");

    // Convert MATLAB's convention of infinity to BONMIN's convention
    // of infinity.
    for (int i = 0; i < n; i++)
      if (mxIsInf(lb[i]))
	lb[i] = neginfty;
  } else {
    
    // If the lower bounds have not been specified, set them to
    // negative infinity.
    lb = new double[n];
    for (int i = 0; i < n; i++)
      lb[i] = neginfty;
  }

  return lb;
}

double* Options::loadUpperBounds(int n, const mxArray* ptr, double posinfty) {
  double* ub;  // The return value.

  // Load the upper bounds on the variables.
  const mxArray* p = mxGetField(ptr,0,"ub");
  if (p) {

    // Load the upper bounds and check to make sure they are valid.
    int N = Iterate::getMatlabData(p,ub);
    if (N != n)
      throw MatlabException("Upper bounds array must have one element for each optimization variable");

    // Convert MATLAB's convention of infinity to BONMIN's convention
    // of infinity.
    for (int i = 0; i < n; i++)
      if (mxIsInf(ub[i]))
	ub[i] = posinfty;
  } else {

    // If the upper bounds have not been specified, set them to
    // positive infinity.
    ub = new double[n];
    for (int i = 0; i < n; i++)
      ub[i] = posinfty;
  }

  return ub;
}

int Options::loadConstraintBounds (const mxArray* ptr, double*& cl, 
				   double*& cu, double neginfty,
				   double posinfty, int &lin, int &nlin) {
  int m = 0;  // The return value is the number of constraints.
  int tm;
  //Defaults
  lin = 0; nlin = 0;

  // LOAD CONSTRAINT BOUNDS.
  // If the user has specified constraints bounds, then she must
  // specify *both* the lower and upper bounds.
  const mxArray* pl = mxGetField(ptr,0,"cl");
  const mxArray* pu = mxGetField(ptr,0,"cu");
  const mxArray* prl = mxGetField(ptr,0,"rl"); //linear constraint bounds
  const mxArray* pru = mxGetField(ptr,0,"ru");
  if (pl || pu || prl || pru) {

    // Check to make sure the constraint bounds are valid.
    if ((!pl ^ !pu) || (!prl ^ !pru))
      throw MatlabException("You must specify both lower and upper bounds on the constraints");
    if (pl && (!mxIsDouble(pl) || !mxIsDouble(pu) || (mxGetNumberOfElements(pl) != mxGetNumberOfElements(pu))))
      throw MatlabException("The nonlinear constraints lower and upper bounds must both be double-precision arrays with the same number of elements");
    if (prl && (!mxIsDouble(prl) || !mxIsDouble(pru) || (mxGetNumberOfElements(prl) != mxGetNumberOfElements(pru))))
      throw MatlabException("The linear constraints lower and upper bounds must both be double-precision arrays with the same number of elements");
    // Get the number of constraints.
    if(pl && prl) {
        lin = (int)mxGetNumberOfElements(prl);
        nlin = (int)mxGetNumberOfElements(pl);
        m = lin+nlin;
    }
    else if(pl) {
        lin = 0;
        nlin = (int)mxGetNumberOfElements(pl);
        m = nlin;        
    }
    else {
        lin = (int)mxGetNumberOfElements(prl);
        nlin = 0;
        m = lin;
    }

    // Load the lower bounds on the constraints and convert MATLAB's
    // convention of infinity to IPOPT's convention of infinity.
    cl = new double[m];
    cu = new double[m];
    if(pl && prl) {
        tm = (int)mxGetNumberOfElements(pl);
        copymemory(mxGetPr(pl),cl,tm);
        copymemory(mxGetPr(pu),cu,tm);
        copymemory(mxGetPr(prl),&cl[tm],(int)mxGetNumberOfElements(prl));
        copymemory(mxGetPr(pru),&cu[tm],(int)mxGetNumberOfElements(pru));
    }
    else if(pl) {
        copymemory(mxGetPr(pl),cl,m);
        copymemory(mxGetPr(pu),cu,m);
    }
    else {
        copymemory(mxGetPr(prl),cl,m);
        copymemory(mxGetPr(pru),cu,m);
    }

    // Convert MATLAB's convention of infinity to IPOPT's convention
    // of infinity.
    for (int i = 0; i < m; i++) {
      if (mxIsInf(cl[i])) cl[i] = neginfty;
      if (mxIsInf(cu[i])) cu[i] = posinfty;
    }
  }

  return m;
}

void Options::loadMultipliers (int n, int m, const mxArray* ptr, 
			       double*& zl, double*& zu, double*& lambda) {
  const mxArray* p;
  
  // Load the Lagrange multipliers associated with the lower bounds.
  p = mxGetField(ptr,0,"zl");
  if (p) {
    if (!mxIsDouble(p) || (int) mxGetNumberOfElements(p) != n)
      throw MatlabException("The initial point for the Lagrange multipliers associated with the lower bounds must be a double-precision array with one element for each optimization variable");
    zl = mxGetPr(p);
  } else
    zl = 0;

  // Load the Lagrange multipliers associated with the upper bounds.
  p = mxGetField(ptr,0,"zu");
  if (p) {
    if (!mxIsDouble(p) || (int) mxGetNumberOfElements(p) != n)
      throw MatlabException("The initial point for the Lagrange multipliers associated with the upper bounds must be a double-precision array with one element for each optimization variable");
    zu = mxGetPr(p);
  } else
    zu = 0;

  // Load the Lagrange multipliers associated with the equality and
  // inequality constraints.
  p = mxGetField(ptr,0,"lambda");
  if (p) {
    if (m>0 && (!mxIsDouble(p) || (int) mxGetNumberOfElements(p) != m) )
      throw MatlabException("The initial point for the Lagrange multipliers associated with the constraints must be a double-precision array with one element for each constraint");
    lambda = mxGetPr(p);
  } else
    lambda = 0;
}

TMINLP::VariableType* Options::loadVariableTypes(int n, const mxArray *ptr)
{
    TMINLP::VariableType*   vartype = new TMINLP::VariableType[n];    //The return value
    const mxArray*          p = mxGetField(ptr,0,"var_type");
    double*                 types;
    
    if(p) {
        if (!mxIsDouble(p) || (mxGetNumberOfElements(p) != n))
            throw MatlabException("The var_type array must be a double-precision array with n elements");
        
        //Get The Variable Types
        types = mxGetPr(p);
        //Assign them to TMINLP types
        for(int i = 0; i < n; i++) {
            switch((int)types[i])
            {
                case -1:
                    vartype[i] = TMINLP::BINARY; //doesn't seem to work?
                    break;
                case 0:
                    vartype[i] = TMINLP::CONTINUOUS;
                    break;
                case 1:
                    vartype[i] = TMINLP::INTEGER;
                    break;
                default:
                    throw MatlabException("The var_type array must only contain -1 (binary), 0 (continous) or 1 (integer)!");
                    break;
            }
        } 
    }
    else {
        for(int i = 0; i < n; i++)
            vartype[i] = TMINLP::CONTINUOUS; //assume all continuous
    }
        
    return vartype;
}

TNLP::LinearityType* Options::loadVariableLinearity(int n, const mxArray *ptr)
{
    TNLP::LinearityType*   varlin = new TNLP::LinearityType[n];    //The return value
    const mxArray*         p = mxGetField(ptr,0,"var_lin");
    double*                types;
    
    if(p) {
        if (!mxIsDouble(p) || (mxGetNumberOfElements(p) != n))
            throw MatlabException("The var_lin array must be a double-precision array with n elements");
        
        //Get The Variable Types
        types = mxGetPr(p);
        //Assign them to TMINLP types
        for(int i = 0; i < n; i++) {
            switch((int)types[i])
            {
                case 0:
                    varlin[i] = TNLP::NON_LINEAR;
                    break;
                case 1:
                    varlin[i] = TNLP::LINEAR;
                    break;
                default:
                    throw MatlabException("The var_lin array must only contain 0 (nonlinear), or 1 (linear)!");
                    break;
            }
        } 
    }
    else {
        for(int i = 0; i < n; i++)
            varlin[i] = TNLP::NON_LINEAR; //assume all nonlinear
    }
        
    return varlin;
}

TNLP::LinearityType* Options::loadConstraintLinearity(int m, int nlin, int nnlin, const mxArray *ptr)
{
    TNLP::LinearityType*   conslin = new TNLP::LinearityType[m];    //The return value
    const mxArray*         p = mxGetField(ptr,0,"cons_lin");
    double*                types;
    
    if(m != (nlin+nnlin))
        throw MatlabException("The total number of constraints does not equal #lin + #nlin");
    
    if(p) {
        if (!mxIsDouble(p) || (mxGetNumberOfElements(p) != m))
            throw MatlabException("The cons_lin array must be a double-precision array with m elements");
        
        //Get The Variable Types
        types = mxGetPr(p);
        //Assign them to TMINLP types
        for(int i = 0; i < m; i++) {
            //Let the user decide for callback constraints what is nonlinear and linear
            if(i < nnlin) {
                switch((int)types[i])
                {
                    case 0:
                        conslin[i] = TNLP::NON_LINEAR;
                        break;
                    case 1:
                        conslin[i] = TNLP::LINEAR;
                        break;
                    default:
                        throw MatlabException("The cons_lin array must only contain 0 (nonlinear), or 1 (linear)!");
                        break;
                }
            }
            else
                conslin[i] = TNLP::LINEAR; //force linear constraints (via A) to be identified as linear
        } 
    }
    else {
        //Fill in based on nlin and nnlin (noting nonlinear constraints come first based on our concatenation)
        for(int i = 0; i < nnlin; i++)
            conslin[i] = TNLP::NON_LINEAR; 
        for(int i = nnlin; i < (nnlin + nlin); i++)
            conslin[i] = TNLP::LINEAR;
    }
        
    return conslin;
}

int Options::loadSOSConstraints(TMINLP::SosInfo* sos, const mxArray *ptr)
{
    const mxArray *pSOS = mxGetField(ptr,0,"sos");
    
    //If some SOS constraints specified
    if(pSOS)
    {
        //Check user input
        if(!mxIsStruct(pSOS))
            throw MatlabException("The SOS argument must be a structure!");       
        if(mxGetFieldNumber(pSOS,"type") < 0)
            throw MatlabException("The sos structure should contain the field 'type'");
        if(mxGetFieldNumber(pSOS,"index") < 0)
            throw MatlabException("The sos structure should contain the field 'index'");
        if(mxGetFieldNumber(pSOS,"weight") < 0)
            throw MatlabException("The sos structure should contain the field 'weight'");
        
        int no_sets = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"type")); 
        if(no_sets > 1) {
            if(!mxIsCell(mxGetField(pSOS,0,"index")) || mxIsEmpty(mxGetField(pSOS,0,"index")))
                throw MatlabException("sos.index must be a cell array, and not empty!");
            if(!mxIsCell(mxGetField(pSOS,0,"weight")) || mxIsEmpty(mxGetField(pSOS,0,"weight")))
                throw MatlabException("sos.weight must be a cell array, and not empty!");
            if(mxGetNumberOfElements(mxGetField(pSOS,0,"index")) != no_sets)
                throw MatlabException("sos.index cell array is not the same length as sos.type!");
            if(mxGetNumberOfElements(mxGetField(pSOS,0,"weight")) != no_sets)
                throw MatlabException("sos.weight cell array is not the same length as sos.type!");        
        }
        
        //Create SosInfo structure if constraints present
        if(no_sets > 0) {
            //Determine number of nzs, also check lengths as we go
            int numNz = 0, numInd, numWt;
            for(int i = 0; i < no_sets; i++)
            {
                if(mxIsCell(mxGetField(pSOS,0,"index")))
                    numInd = (int)mxGetNumberOfElements(mxGetCell(mxGetField(pSOS,0,"index"),i));
                else 
                    numInd = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"index"));
                
                if(mxIsCell(mxGetField(pSOS,0,"weight"))) 
                    numWt = (int)mxGetNumberOfElements(mxGetCell(mxGetField(pSOS,0,"weight"),i));
                else
                    numWt = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"weight"));
            
                if(numInd != numWt)
                {
                    throw MatlabException("An SOS constraint does not contain the same number of indices as weights!");
                }
                numNz += numInd; 
            }
            
            //Allocate SosInfo memory (automatically cleared by SosInfo destructor)
            sos->num = no_sets;
            sos->types = new char[no_sets];
            sos->priorities = new int[no_sets];
            sos->numNz = numNz;
            sos->starts = new int[no_sets+1];
            sos->indices = new int[numNz];
            sos->weights = new double[numNz];            
            
            //Collect Types
            char *sostype = mxArrayToString(mxGetField(pSOS,0,"type"));
            //Add each set
            int numInSet, setStart = 0;
            double *sosind, *soswt;
            for(int i = 0; i < no_sets; i++)
            {
                //Types
                sos->types[i] = sostype[i] - '0';
                //Priorities (not really sure what these do as we don't specify variable priorities)
                sos->priorities[i] = 10;
                //Set Start
                sos->starts[i] = setStart;
                
                //Collect novars + ind + wt
                if(mxIsCell(mxGetField(pSOS,0,"index"))) {
                    numInSet = (int)mxGetNumberOfElements(mxGetCell(mxGetField(pSOS,0,"index"),i));
                    sosind = mxGetPr(mxGetCell(mxGetField(pSOS,0,"index"),i));
                }
                else {
                    numInSet = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"index"));
                    sosind = mxGetPr(mxGetField(pSOS,0,"index"));
                }
                if(mxIsCell(mxGetField(pSOS,0,"weight"))) 
                    soswt = mxGetPr(mxGetCell(mxGetField(pSOS,0,"weight"),i));
                else
                    soswt = mxGetPr(mxGetField(pSOS,0,"weight"));
                
                //Copy in
                for(int j = 0, k = setStart; j < numInSet; j++, k++)
                {
                    sos->indices[k] = (int)sosind[j]-1; //-1 for matlab index
                }
                memcpy(&sos->weights[setStart],soswt,numInSet*sizeof(double));
                
                //Move start forward
                setStart += numInSet;              
            }
            //End of set?
            sos->starts[no_sets] = setStart;
            
            mxFree(sostype);
            
            #ifdef DEBUG
            mexPrintf("%d SOS Sets with %d NNZ\nIndx: [",sos->num ,sos->numNz);
            for(int i = 0; i < numNz; i++)
            {
                mexPrintf("%d ",sos->indices[i]);
            }
            mexPrintf("]\nWts: [");
            for(int i = 0; i < numNz; i++)
            {
                mexPrintf("%.0f ",sos->weights[i]);
            }
            mexPrintf("]\nStarts: [");
            for(int i = 0; i <= no_sets; i++)
            {
                mexPrintf("%d ",sos->starts[i]);
            }
            mexPrintf("]\nTypes: [");
            for(int i = 0; i < no_sets; i++)
            {
                mexPrintf("'%d' ",sos->types[i]);
            }
            mexPrintf("]\n");
            #endif
        }
        
        return no_sets;
    }
    else
    {
        return 0; //none specified
    }
}