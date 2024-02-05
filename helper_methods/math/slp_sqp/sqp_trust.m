function [x,f,status,output,lambda]=sqp_trust(varargin)
% Sequential Quadratic Programming (SQP) with Trust Region Strategy
% finds the constrained minimum of a function of several variables.
%
% Version 1.4
%
% Copyright (c) 2020, Robert A. Canfield. All rights reserved.
%                     See accompanying LICENSE.txt file for conditions.
%
%  fmincon-compatible problem structure input argument
%          optimtool GUI option "Export to Workspace" dialog box 
%          sends problem information to the MATLAB workspace as a structure
%
%          usage: [x,f,status,output,lambda]=sqp_trust( problem )
%
%          input: problem   - Data structure with fields:
%                 objective - Objective function
%                 x0        - Initial point for x
%                 Aineq     - Matrix for linear inequality constraints
%                 bineq     - Vector for linear inequality constraints
%                 Aeq       - Matrix for linear equality constraints
%                 beq       - Vector for linear equality constraints
%                 lb	       - Vector of lower bounds
%                 ub        - Vector of upper bounds
%                 nonlcon   - Nonlinear constraint function 
%                 options   - Options created with optimset
%
%  Optimization Toolbox version 1 compatible input arguments
%
%  usage: [x,f,status,output,lambda]=sqp_trust(Fun,X0,Opts,vlb,vub,Grd,...
%                                              A,b,Aeq,beq,P1,P2,...)
%
%  input:   Fun     - function handle (or string) which returns the
%                     value of the objective function and a vector of
%                     constraints, i.e., [f,g]=fun(x,active,P1,P2,...) 
%                     where x is the design variable vector and active is
%                     an index/boolean vector pointing to active constraints.
%                     f is minimized such that g<=zeros(g).
%           X0      - initial vector of design variables
%           Options - (optional) a structure according to optimset & fields
%                     TrustRegion: on, off, simple, merit, TRAM (string)
%                     ComplexStep: off, on (string)
%                     cutg:        active constraint cutoff value (real)
%           vlb     - (optional) vector of lower bounds on design variables
%           vub     - (optional) vector of upper bounds on design variables
%           Grd     - (optional) function handle that returns a vector of 
%                     function gradients and a matrix of constraint gradients
%                     i.e. [fp,gp]=grd(x,active,P1,P2,...) where
%                     active is an index (or boolean) vector to active g.
%           A       - Matrix for linear inequality constraints
%           b       - Vector for linear inequality constraints
%           Aeq     - Matrix for linear equality constraints
%           beq     - Vector for linear equality constraints
%           Pn      - (optional) variables directly passed to Fun and Grd
%
%           Note: optional inputs can be skipped by inputing []
%
%  output: x        - vector of design variables at the optimal solution
%          f        - final value of objective function
%          status   - Convegence flag
%          output   - Structure of output results (iteration history)
%          lambda   - Structure of Lagrange multipliers
%
% This function signature is based on the MATLAB function constr.m written
% by Andy Grace of MathWorks, 7/90, supplemented with 
% Optimization Toolbox version 2 data structures for options and output.
%
% Trust Region (TR) algorithm and filter based on: 
% Nocedal and Wright, Numerical Optimization. New York: Springer, 2006 
% Algorithms 4.1 for TR & 15.1 for filter; Equation (15.4) for simple merit
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:        2/8/18
%  Last modified: 1/10/20
%--------------------------------------------------------------------------
% Copyright (c) 2019, Robert A. Canfield. All rights reserved.
%                     Virginia Tech
%                     bob.canfield@vt.edu
%                    <http://www.aoe.vt.edu/people/faculty/canfield.html>
% 
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"),
% to deal with the Software without restriction, including without 
% limitation the rights to use, copy, modify, merge, publish, distribute, 
% sublicense, and/or sell copies of the Software, and to permit persons 
% to whom the Software is furnished to do so, subject to the following 
% conditions:
% 
% * Redistributions of source code must retain the above copyright notice,
%   this list of conditions and the following disclaimers.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimers in the
%   documentation and/or other materials provided with the distribution.
% 
% * Neither the names of Robert A. Canfield, Virginia Tech, 
%   Air Force Institute of Technology, nor the names of its contributors 
%   may be used to endorse or promote products derived from this Software 
%   without specific prior written permission.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
% OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
% THE USE OR OTHER DEALINGS WITH THE SOFTWARE. 
%--------------------------------------------------------------------------

%--Modifications
%   2/ 8/18 - refactored as sqp_trust and sao_trust
%   4/ 6/19 - fix varargin passed
%  11/ 8/19 - process input with saocrkargin
%   1/10/20 - Pass Problem structure

%% Check inputs
if nargin<1
   disp('usage: [x,f,exitflag,output,lambda]=sqp_trust(fun,x0,options,vlb,vub,grd)')
   return
end

[Problem,fun,grd,options,TR,userxarg] = saocrkargin(varargin{:});

if isfield(TR,'QMEA') && ~isempty(TR.QMEA)
   if strcmpi(TR.QMEA,'off')
      warning('sqp_trust:QMEA','sqp_trust: Turning on options.QMEA')
      TR.QMEA = 'on';
   elseif strcmpi(TR.QMEA,'fmincon')
      error('sqp_trust:fmicon','QMEA sub-space with fmincon TBD')
   end
   options.BFGS=false;
else
   if isfield(TR,'MPEA') && ~strcmpi(TR.MPEA,'off')
      error('sqp_trust:MPEA','MPEA w/o QMEA: BFGS TBD, use slp_trust')
   end
   TR.QMEA = [];
   options.BFGS = isfield(options,'HessianApproximation') && ...
                   strcmpi(options.HessianApproximation,'bfgs');
   options.lBFGS= isfield(options,'HessianApproximation') && ...
                   strcmpi(options.HessianApproximation,'lbfgs');
   if isfield(options,'HessianFcn') && ~isempty(options.HessianFcn)
      disp('sqp_trust: user Hessian function detected')
   elseif options.BFGS
      disp('sqp_trust: using BFGS')
   elseif options.lBFGS
      %disp('sqp_trust: using lBFGS')
      error('sqp_trust:lBFGS','Limited memory BFGS implentation TBD')
   else
      TR.MPEA='off';
      TR.QMEA='on';
   end
end
if ~isempty(TR.QMEA) && isOctave
   %    Octaver = OCTAVE_VERSION;
   %    if str2double(Octaver(1)) < 5
   disp('Octave does not support nested sub-functions use in sqp_trust.')
   x=[];
   f=[];
   status=-1;
   output=[];
   lambda=[];
   return
   %    end
end

[x,f,status,output,lambda]=sao_trust(Problem,fun,grd,TR,options,userxarg{:});

end