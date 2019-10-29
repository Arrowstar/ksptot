function [x,fval,exitflag,info] = mosekmilp(f,A,rl,ru,lb,ub,xint,x0,opts)
%MOSEKMILP Solve a MILP using MOSEK
%
%   min f'*x      subject to:     rl <= A*x <= ru
%    x                            lb <= x <= ub
%                                 for i = 1..n: xi in Z
%                                 for j = 1..m: xj in {0,1}                             
%
%   x = mosekmilp(f,A,rl,ru,lb,ub,xint) solves a MILP where f is the 
%   objective vector, A,rl,ru are the linear constraints, lb,ub are the 
%   bounds and xint is a string of integer variables ('C', 'I', 'B')
%
%   x = mosekmilp(f,...,xint,x0) uses x0 as the initial solution guess.
%
%   x = mosekmilp(f,...,x0,opts) uses opts to pass mosekset options to the
%   MOSEK solver.
%
%   [x,fval,exitflag,info] = mosekmilp(...) returns the objective value at
%   the solution, together with the solver exitflag, and an information
%   structure.

%   This function is based in parts on examples from the MOSEK Toolbox, 
%   Copyright (c) 1998-2011 MOSEK ApS, Denmark.

%   Copyright (C) 2012 Jonathan Currie (IPL)

t = tic;

% Handle missing arguments
if nargin < 9, opts = mosekset('warnings','off'); else opts = mosekset(opts); end 
if nargin < 8, x0 = []; end
if nargin < 7, xint = repmat('C',size(f)); end
if nargin < 6, ub = []; end
if nargin < 5, lb = []; end
if nargin < 4, error('You must supply at least 4 arguments to mosekmilp'); end

%Build MOSEK Command
[cmd,param] = mosekBuild(opts);

%Create Problem Structure
prob = mosekProb([],f,A,rl,ru,[],[],[],[],lb,ub,xint,[],x0,opts);
    
%Call MOSEK
[rcode,res] = mosekopt(cmd,prob,param);

%Extract Results
[x,fval,exitflag,info] = mosekRes(prob,rcode,res,t);