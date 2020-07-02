#include "program.h"
#include <string.h>
#include <time.h>

// Function definitions.
// -----------------------------------------------------------------
// Copy a C-style string (a null-terminated character array) to a
// non-C-style string (a simple character array). The length of the
// destination character array is given by "ndest". If the source is
// shorter than the destination, the destination is padded with blank
// characters.
void copyCStrToCharArray (const char* source, char* dest, int ndest) {
  
  // Get the length of the source C string.
  int nsource = (int)strlen(source);
  
  // Only perform the copy if the source can fit into the destination.
  if (nsource < ndest) {

    // Copy the string.
    strcpy(dest,source);

    // Fill in the rest of the string with blanks.
    for (int i = nsource; i < ndest; i++)
      dest[i] = ' ';
  }
}

// Return true if the two strings are the same. The second input
// argument must be a C-style string (a null-terminated character
// array), but the first input argument need not be one. We only
// compare the two strings up to the length of "cstr".
bool strIsEqualToCStr (const char* str, const char* cstr) {

  // Get the length of the C string.
  int n = (int)strlen(cstr);

  return !strncmp(str,cstr,n);
}

// Function definitions for class Program.
// -----------------------------------------------------------------
Program::Program (int n, double* x, double* lb, double* ub, int* btype, 
		  int m, int maxiter, int maxfeval, double maxtime, double factr, double pgtol) {
  this->n       = n;
  this->x       = x;
  this->lb      = lb;
  this->ub      = ub;
  this->btype   = btype;
  this->m       = m;
  this->maxiter = maxiter;
  this->maxfeval= maxfeval;
  this->maxtime = maxtime;
  this->factr   = factr;
  this->pgtol   = pgtol;
  this->iprint  = defaultprintlevel;
  this->owner   = false;

  initStructures();
}

Program::Program (int n, int m, int maxiter, double factr, double pgtol) {
  this->n       = n;
  this->x       = new double[n];
  this->lb      = new double[n];
  this->ub      = new double[n];
  this->btype   = new int[n];
  this->m       = m;
  this->maxiter = maxiter;
  this->factr   = factr;
  this->pgtol   = pgtol;
  this->iprint  = defaultprintlevel;
  this->owner   = true;

  initStructures();
}

Program::~Program() { 
  if (owner) {
    delete[] x;
    delete[] lb;
    delete[] ub;
    delete[] btype;
  }

  delete[] g;
  delete[] wa;
  delete[] iwa;
}

SolverExitStatus Program::runSolver(int &iter, double &fval, double &evaltime) 
{
  SolverExitStatus status = success;  // The return value.
  //Start Timer
  clock_t start = clock();
  double etime;
  int nfeval = 0;
  
  // Initialize the objective function and gradient to zero.
  f = 0;
  for (int i = 0; i < n; i++)
    g[i] = 0;
  
 

  // This initial call sets up the structures for L-BFGS.
  callLBFGS("START");

  // Repeat until we've reached the maximum number of iterations.
  int t = 0;
  while (true) {
    //Get current execution time
    etime = ((double)(clock()-start))/CLOCKS_PER_SEC;
    
    // Do something according to the "task" from the previous call to
    // L-BFGS.
    if (strIsEqualToCStr(task,"FG")) 
    {
        //Check for maxfeval 
        if(nfeval >= maxfeval) {
            callLBFGS("STOP");
            status = exceededMaxFeval;
            break;
        }
        else {        
            // Evaluate the objective function and the gradient of the objective at the current point.
            f = computeObjective(n,x); nfeval++;
            computeGradient(n,x,g);
        }
    } 
    else if (strIsEqualToCStr(task,"NEW_X")) 
    {
        // Go to the next iteration and call the iterative callback routine.
        t++;
        if(iterCallback(t,etime,x,f))
        {
            callLBFGS("STOP");
            status = userExit;
            break;
        }
        // If we've reached the maximum number of iterations, terminate the optimization.
        if (t >= maxiter) {
            callLBFGS("STOP");
            status = exceededIterations;
            break;
        }
        // If we've reached the maximum time, terminate the optimization       
        if(etime > maxtime) {
            callLBFGS("STOP");
            status = exceededMaxTime;
            break;
        }
    } 
    else if (strIsEqualToCStr(task,"CONV"))
      break;
    else if (strIsEqualToCStr(task,"ABNO")) 
    {
      status = abnormalTermination;
      break;
    } 
    else if (strIsEqualToCStr(task,"ERROR")) 
    {
      status = errorOnInput;
      break;
    }

    // Call L-BFGS again.
    callLBFGS();
  }

  //Save no iterations + final fval + eval time
  iter = t;
  fval = f;
  evaltime = ((double)(clock()-start))/CLOCKS_PER_SEC;
  //Return solver status
  return status;
}

void Program::callLBFGS (const char* cmd) {
  if (cmd)
    copyCStrToCharArray(cmd,task,60);
  SETULB(&n,&m,x,lb,ub,btype,&f,g,&factr,&pgtol,wa,iwa,task,&iprint,csave,lsave,isave,dsave);
}

void Program::initStructures() {
  f   = 0;
  g   = new double[n];
  wa  = new double[(2*m + 5)*n + 11*m*11*m + 8*m];
  iwa = new int[3*n];
}
