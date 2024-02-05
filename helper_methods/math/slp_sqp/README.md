# SLP_SQP MATLAB / OCTAVE optimization functions
`slp_trust.m`, `sqp_trust.m`, and `sqp.m` 

* Copyright (c) 2015, 2020, Robert A. Canfield. All rights reserved. 
* bob.canfield@vt.edu
* <http://www.aoe.vt.edu/people/faculty/canfield.html>
* See accompanying LICENSE.txt file for conditions.

## Features
* *Optim Toolbox* Version 1.0 calling sequence and backward compatibility
	* Single user function to define both objective and constraint functions
	* Second optional user function to supply objective and constraint gradients
	* Alternative input: `fmincon` problem data structure for objective and constraint user functions
* Complex-step derivative option for machine precision numerical derivatives
* OCTAVE compatible <[www.octave.org](http:www.octave.org)>

## m-Files
-  `slp_trust` -- Sequential Linear Programming (SLP) with Trust Region Strategy
-  `sqp_trust` -- Sequential Quadratic multipoint approximation Programming (SQP) with Trust Region Strategy
-  `sqp`       -- Schittkowski's Sequential Quadratic Programming method, written with Mark Spillman
-  `foptions`   -- Default parameters used by sqp (optim toolbox v1.0, written by Andy Grace, 1990)
-  `initOctave` -- Initialize for Octave by loading packages
-  `isOctave`	   -- function to detect [Octave](https://www.gnu.org/software/octave/) environment, written by Blake M. Van Winkle, 2017
-  `Contents`   -- Text document describing files

## Documentation
-  `README.md`   - ReadMe text file (markdown format)
-  `LICENSE.txt` - Open Source License notice
-  `sqp.pdf`     - User's Guide for `sqp` and `slp_trust` (Adobe portable document format) in *doc* folder

## Examples
-  `run*.m`    -- Scripts to run example problems
-  `f*.m`      -- Functions to evaluate objective, f, and constraints, g
-  `g*.m`      -- Functions to evaluate gradients of f and g

## Private folder
Utility functions called by `sqp.m`, `slp_trust.m`, and `sqp_trust.m`

## OCTAVE installation
To run in Octave instead of MATLAB, install the following Octave packages and set the *Octave Current Directory* to slp_sqp.

	pkg install -forge io
	pkg install -forge statistics
	pkg install -forge struct
	pkg install -forge optim
	# cd slp_sqp
	# add sub-directories to path before calling sqp, slqp_trust
	addpath('examples:private:private/Octave')
	
The supporting Mathworks `optimplot*.m` function m-files for `options.PlotFcns`, found in `toolbox/matlab/optimfun` folder of the MATLAB distribution, are not distributed. Alternatively, the supplied `private/plotFcns.m` m-file may be modified, or an `options.OutputFcn` may be written, to create the desired plots.

## Description
Sequential Linear Programming (SLP) with Trust Region (TR) and Sequential Quadratic Programming (SQP) with Line Search or TR Strategy

Solve constrained, nonlinear, parameter optimization problems using sequential linear programming with trust region strategy (`slp_trust`), sequential quadratic programming with trust region strategy (`sqp_trust`), or sequential quadratic programming with line search (`sqp`), similar to fmincon in the Optimization Toolbox. SQP is a second-order method, following Schittkowski's NLPQL Fortran algorithm. SLP is a first-order method, but may be more efficient for large numbers of design variables. 

These functions are implemented using the original calling sequence of the obsolete MATLAB `constr.m` function in Version 1 of the *optim toolbox*, but may alternatively accept the problem data structure used by fmincon as an input argument. The original calling sequence had the advantage that one user function computed the objective and constraint values together, with a separate function for their gradients when finite differences were not used. 

Complex-step derivatives, which can be accurate to machine precision, are a feature of `sqp`, `slp_trust`, and `sqp_trust`, in place of finite difference derivatives, when the user does not supply a function that computes the derivatives.

Compatible with Octave (MATLAB-compatible GNU Scientific Programming Language) <[www.octave.org](http:www.octave.org)>. 

## Open Source License
Copyright (c) 2020, Robert A. Canfield. All rights reserved.

`sqp.m, slp_trust.m, sqp_trust.m `

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal with the Software without restriction, including without 
limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons 
to whom the Software is furnished to do so, subject to the following 
conditions:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimers.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimers in the
  documentation and/or other materials provided with the distribution.

* Neither the names of Robert A. Canfield, Virginia Tech, Mark Spillman,
  Air Force Institute of Technology, nor the names of its contributors 
  may be used to endorse or promote products derived from this Software 
  without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE SOFTWARE.