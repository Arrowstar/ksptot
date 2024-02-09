function [x,out,v,H,status]=sqp(Fun,x0,Opts,vlb,vub,Grd,varargin)
% SQP    Schittkowski's Sequential Quadratic Programming method
%        to find the constrained minimum of a function of several variables
%
% Copyright (c) 2020, Robert A. Canfield, Mark Spillman. All rights reserved.
%                     See accompanying LICENSE.txt file for conditions.
%
% Schittkowski (1985) "NLPQL: A FORTRAN Subroutine Solving Constrained
% Nonlinear Programming Problems," Annals Ops. Research, 5:485-500.
%
%          Optimization Toolbox Version 1-compatible input arguments:
%
%  usage: [x,out,v,H,status]=sqp(Fun,x0,opts,vlb,vub,Grd,P1,P2,...)
%
%  input: Fun    - string name of a function file which returns the
%                  value of the objective function and a vector of
%                  constraints (i.e. [f,g]=fun(x)).  f is minimized
%                  such that g<zeros(g). Set g=[] for unconstrained.
%
%         x0     - initial vector of design variables
%
%         opts   - (optional) vector of parameters, or optimset structure
%
%                opts(1)-Display parameter (Default: 0, none)
%                opts(2)-Termination tolerance for X. (Default: 1e-4).
%                opts(3)-Termination tolerance on F.  (Default: 1e-4).
%                opts(4)-Termination criterion on constraint violation. (Default: 1e-6)
%                opts(5)-scale design variables if <0  (or opts.Scale)
%                        scale functions if f,g>abs(opts(5))
%                opts(6)-change termination criteria
%                        (or opts.Termination)
%                opts(7)-maximum function evaluations in line search
%                        (or opts.MaxLineSearchFun)
%                opts(9)-Derivative Check (Default 0, off)
%                opts(14)-max number of function evaluations
%                opts(15)-max iterations
%                Type help foptions for more details.
%
%            Or, structure of fmincon options (optimset)
%                opts.Display         = opts(1)
%                opts.TolX            = opts(2)
%                opts.TolFun          = opts(3)
%                opts.TolCon          = opts(4)
%                opts.DerivativeCheck = opts(9)
%                opts.MaxFunEvals     = opts(14)
%                opts.MaxIter         = opts(15)
%                opts.DiffMinChange   = opts(16)
%                opts.DiffMaxChange   = opts(17)
%                opts.OutputFcn = function handle for user output/plot
%
%                In addition to optimset options, opts may contain:
%                opts.foptions    - vector (<=18 length) of old style foptions
%                opts.Scale       - opts(5) variable/function scaling
%                opts.Termination - opts(6) convergence criteria
%                opts.nec         - opts(13) number equality constraints
%                opts.LagrangeMultipliers - initial Lagrange multiplier estimate
%                opts.HessMatrix          - initial positive-definite Hessian estimate
%                opts.HessFun     - user-supplied Hessian function handle
%                     H=Hessian(x,LagrangeMultipliers)
%
%         vlb    - (optional) vector of lower bounds on the design
%                  variables
%         vub    - (optional) vector of upper bounds on the design
%                  variables
%         Grd    - (optional) string name of a function file which
%                  returns a vector of function gradients and a
%                  matrix of constraint gradients
%                  (i.e. [fp,gp]=grd(x)).
%         Pn     - (optional) variables directly passed to fun and grd
%                  optional inputs Pn can be skipped by inputing []
%
%  output: x      - vector of design variables at the optimal solution
%          out    - final program parameters, vector if opts was vector:
%                   out(8)  = value of the function at the solution
%                   out(10) = number of function evaluations
%                   out(11) = number of gradient evaluations
%                   out(15) = number of iterations
%                   fields same as fmincon output, if opts was structure
%          v      - vector of Lagrange multipliers at the solution
%          H      - Hessian at the solution
%          status - Termination status: 1=converged
%
%  fmincon-compatible problem structure input argument
%          optimtool GUI option "Export to Workspace" dialog box
%          sends problem information to the MATLAB workspace as a structure
%
%          usage: [x,opts,v,H,status]=sqp( problem )
%
%          input: problem - Data structure with fields:
%                 objective - Objective function
%                 x0        - Initial point for x
%                 Aineq     - Matrix for linear inequality constraints
%                 bineq     - Vector for linear inequality constraints
%                 Aeq       - Matrix for linear equality constraints
%                 beq       - Vector for linear equality constraints
%                 lb        - Vector of lower bounds
%                 ub        - Vector of upper bounds
%                 nonlcon   - Nonlinear constraint function
%                 options   - Options created with optimset
%
%  Written by:   Capt Mark Spillman and Maj Robert A. Canfield
%                Air Force Institute of Technology, Virginia Tech
%                Octave-compatiby functions by Blake van Winkle
%  e-mail:       bob.canfield@vt.edu
%
%  Created:       12/5/94
%  Modified:     10/10/20
%
% The function format is based on the MATLAB function constr.m written
% by Andy Grace of MathWorks, 7/90.  The algorithm is based the FORTRAN
% routine NLPQL written by Klaus Schittkowski, 6/91.
%
%---------------------------------------------------------------------
% Explain the different possible termination criteria
%
% Three different termination criterias can be selected with opts(6):
%
% 1.  If opts(6)=(-1), Schittkowski's criteria is used:
%        KTO=abs(s'*fp)+sum(abs(u.*gv))  <=  opts(3)
%                       SCV=sum(g(g>0))  <=  sqrt(opts(3))
%
% 2.  If opts(6)=1, Andy Grace's criteria is used:
%                     ms=.5*max(abs(s))  <   opts(2)
%                      AG=.5*abs(fp'*s)  <   opts(3)
%                                max(g)  <   opts(4)
%
% 3.  If opts(6)~=(-1) & opts(6)~=1, the default criteria is used:
%                          max(abs(dx))  <=  opts(2)
%                                   KTO  <=  opts(3)
%                                max(g)  <=  opts(4)
%
% 4.  If opts(6)==2, add Slowed convergence criterion to (3) above.
%                    NLG = norm(Lagrangian gradient) instead of KTO
%---------------------------------------------------------------------
% Explain trouble shooting information
%
% If opts(1)=2 the following information will also be displayed
% when applicable:
%
%     'dH' - Hessian has been perturbed for improved conditioning
%     'aS' - The augmented Lagrangian type Search direction was used
%     'mS' - The modified Search direction problem was used
%     'sx' - Design variables are being scaled
%     'sf' - Objective function is being scaled
%     'sg' - One or more constraint functions scaled
%     'L1' - L1 merit (exterior penalty)
%--------------------------------------------------------------------------
% Copyright (c) 2015, Robert A. Canfield, Mark Spillman. All rights reserved.
%                     Virginia Tech and Air Force Institute of Technology
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
% * Neither the names of Robert A. Canfield, Virginia Tech, Mark Spillman,
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

%--------------------------------------------------------------------------
% Internal sub-function interfaces
%
% MERIT       Merit Function for one-dimensional search
% usage:      [z0,z0p1,z0p2,z0p3]=merit(v,r,nec,f,g,fp,gp,u,s)
% inputs:     v     - Estimates of the optimal Lagrange multipliers
%             r     - scalar penalty parameter
%             nec   - number of equality constraints
%             f     - function value
%             g     - constraint values
%             fp    - (required for z0p1-3) function gradient
%             gp    - (required for z0p1-3) constraint gradients
%             u     - (required for z0p1-3) Lagrange multipliers
%                     for QP search direction problem
%             s     - (required for z0p1-3) search direction
% outputs:    z0    - value of the merit function at alpha
%             z0p1  - derivative of the merit function wrt alpha
%             z0p2  - derivative of the merit function wrt x
%             z0p3  - derivative of the merit function wrt v
%
% SQPFDGRD    SQP Finite Difference Gradients
% usage:      [df,dg]=sqpfdgrd(fcnstr, x0, f0, g0, xmin, xmax, x1,P1,...,P15)
% inputs:     fcnstr     - function evaluation call in string form for 'eval'
%             x0         - current design variable vector
%             f0         - objective value at x0
%             g0         - constraint values at x0
%             xmin       - minimum finite difference step
%             xmax       - maximum finite difference step
%             x1         - scale factor for design variables
%             Pn         - optional variables directly passed to fcnstr
% outputs:    df         - finite difference objective gradient vector
%             dg         - finite difference constraint gradients matrix
%
% GRADERR     Gradient Error print routine (MATLAB optim Toolobox)
% usage:      graderr( FDgrad, grad, str )
% inputs:     FDgrad    - Finite Difference gradient(s)
%             grad      - Analytic gradient(s)
%             str       - String used to evaluate FDgrad
%
% QP          Quadratic Programming solver (MATLAB optim Toolbox)
% usage:      [s,u,status]=qp(H,fp,A,b,vlb,vub,x0,neq,nomsg)
% inputs:     H        - Quadratic coefficient matrix (Hessian)
%             fp       - Linear constant vector (function gradient)
%             A        - Constraint coefficient matrix
%             b        - Constraint constants
%             vlb,vub  - Variable lower and upper bounds
%             neq      - Number of equality constraints
%             n0msg    - Flag to turn off messages
% outputs:    s        - Optimal search direction
%             u        - Lagrange multipliers
%             status   - Termination status
%--------------------------------------------------------------------------
%
% Modifications
%
% 2/4/95  - Fixed check of x0 against vlb and vub (RAC).
% 2/5/95  - Fixed ill-conditioned H.
%           Added trouble shooting info (MSS).
% 2/7/95  - Sig figures on function increased to 5 for display (MSS).
% 2/18/95 - Option to scale design variables.
%           Adjust Hessian perturbation to avoid eigenvectors (RAC).
% 2/20/95 - Eliminated variables gpv and gpvnew.
%           Changed default dX termination.
%           Added finite difference gradients (RAC).
% 2/21/95 - Fixed bug for >1,<ndv subset of unscaled variables (RAC).
% 2/22/95 - Modified alpha termination criteria in line search (MSS).
% 2/23/95 - Limited print when opts(1)==0 (RAC).
% 2/28/95 - Design variables 'x' can be stored as a matrix (RAC).
% 3/10/95 - 'x' can be any combination of row/column/matrix (RAC).
% 3/13/95 - Checks z0p1>=0 now z0p1>eps. 'while r<rub' added (RAC).
% 3/14/95 - 'status' is for error processing by user (RAC).
% 3/24/95 - Scale functions. nlinmax=opts(7). More debug prints.
%           Remove equality constraint sign change.
%           Indicate max vlb,vub violation in print w/'-,+' (RAC).
% 3/25/95 - Adjust mg,SCV for equality constraints (RAC).
% 3/26/95 - Terminate line search for nlin=nlinmax<16 (RAC).
% 3/27/95 - Trap singular Hessian update (RAC).
% 4/28/95 - Rewrote entire search direction path (MSS).
%           Modified troubleshooting output (MSS).
%           Modified gv for scaled gradients (MSS).
%           Modified NLG calculation (MSS).
% 4/30/95 - Added additional termination criteria (MSS).
% 5/1/95  - Add usage display & adjust status return (RAC).
% 5/2/95  - Use sqacc instead of opts(4) for error checks (RAC).
% 7/10/95 - Move scaling of v to end (RAC).
% 8/18/95 - Print Lagrange Multipliers (RAC).
% 8/12/99 - Remove MatLab 5.2 compilation warnings
% 9/21/00 - Fix NLG termination criterion and range error
% 9/26/00 - Use string comparison function (RAC).
% 3/5/04  - Change calling sequence to match constr
% 5/5/04  - Use feval and varargin instead of eval w/ P1,P2,...
%           Implement active constraint strategy
% 6/24/04 - Fix NAC for equality constraints
% 7/15/04 - Add bounds to modified qp call
% 7/26/04 - Avoid singular (zero gradients) point
% 8/13/04 - Allow for null or zero constraint gradients
% 7/27/05 - Fix uub
% 4/13/06 - Allow null vlb or vub. Clean up M-lint warnings.
% 5/12/06 - Fix to qp stub where LAMBDA formed. Allow empty g.
%  6/3/06 - output opts can be a structure
% 6/21/06 - Check user Hessian is positive definite
% 7/16/06 - Check Y to avoid singular Hessian update and reset H
% 3/22/07 - Improve perturbed Hessian. Increase minalspha. leastmg
% 3/29/07 - Better ALSD & line search; exterior penalty for infeasible
%  4/2/07 - Max function evals in opts(14), iters in opts(15)
%  4/4/07 - Fixed Augmented Lagrangian multiplier update
% 7/31/07 - Slowed convergence
%  8/7/07 - Fix ACTIVE_CONSTRAINTS for u=0
%  8/8/07 - Option for user supplied Hessian
% 10/26/07- Fix vlm in 2nd ALSD line search & remove H reset
% 12/14/07- Don't reset User Hessian. Track best design.
%  3/4/08 - Extra user-supplied Hessian checks
% 4/11/08 - Non-zero initial Lagrange multiplier guess
%  5/8/08 - Abort last-ditch L1 reduction if z0=0
% 5/20/08 - fix guessLM and scalefg for unconstrained
% 5/30/08 - Bounds and returned gradients error checks
% 4/17/09 - Introduce ilb,iub to correctly index x (for scalar x)
% 4/22/09 - Default for empty MaxFunEvals, MaxIter, TolX in sqpcrkopts
% 4/27/11 - Add complex step derivatives
% 7/16/11 - Track Best.nit
%  5/6/13 - Fix neq in qp to handle null g,h in aS option
% 7/12/13 - Fix grdcs for multiple constraints (AR)
% 9/29/15 - fmincon compatibility with single input: problem structure
% 11/12/15- Exit if checkbounds detects error
% 11/25/16- Remove uneeded if-condition punctuation
%  4/9/17 - Longer print banner line, more NAC
% 4/20/17 - Warning for unused ComplexStep; handle empty s from qp
% 1/25/18 - Suppress negative LM warning for opts(1)<3
%  3/1/18 - Initialize vold before loop
% 11/3/19 - isOctave, checkbounds, sqpcrkopts, and qp Octave compatibility
% 1/10/20 - check real value of sqpcsgrd for consistency with fun
% 2/12/20 - f0last updated; more status codes; status flag message
% 5/22/20 - Opts.OutputFcn added for user call back (e.g., to plot)
%  6/4/20 - fix opts(5)=opts.Scale
% 7/12/20 - remove lb,ub padding; free variables in guessLM
% 7/21/20 - augfail~=1 for unbound aS; flag for best point
% 9/15/20 - guessLM revised; null gradg handled in sqpcsgrd
% 10/10/20- return Best for all termination criteria
%--------------------------------------------------------------------------

global ACTIVE_CONSTRAINTS

%% Setup and check error conditions
%
% Check inputs
if nargin<1
    disp('usage: [x,out,u,H,status]=sqp(fun,x0,opts,vlb,vub,grd,P1,P2,...)')
    return
end
if nargin>1
    if nargin<3, Opts=[];end
    if nargin<4, vlb=[]; end
    if nargin<5, vub=[]; end
    if nargin<6, Grd=[]; end; fd_gradients = isempty(Grd);
    if nargin>21,error('Too many input arguments.'); end
else
    Problem = Fun;
    [Obj,x0,A,b,Aeq,beq,vlb,vub,Con,Opts]=sqpcrkfmincon(Problem);
    Fun = @(x) fun2(x,Obj,Con,A,b,Aeq,beq);
    Grd = @(x) grd2(x,Obj,Con,A,Aeq);

    if(isfield(Opts,'SpecifyObjectiveGradient'))
        fd_gradients = not(Opts.SpecifyObjectiveGradient);
    else
        fd_gradients = nargout(Obj)<2 || nargout(Con)<3;
    end
end
% Check if user turned off active constraint set strategy
if length(ACTIVE_CONSTRAINTS)>1 && ~ischar(ACTIVE_CONSTRAINTS)
    ACTIVE_CONSTRAINTS = []; % turn off prior use left as global
end
%
% Process options
%
ndv=length(x0(:));
% Check lower and upper bounds: vlb and vub
lenvlb=length(vlb); ilb=(1:lenvlb)';
lenvub=length(vub); iub=(1:lenvub)';
[x,vlb,vub,msg] = checkbounds(x0,vlb,vub,ndv);
if ~isempty(msg), error(msg), end
if ~isOctave
    vlb=vlb(ilb); % remove unnecessary +/-inf padding
    vub=vub(iub);
    warning('off','optimlib:checkbounds:PadLbWithMinusInf');
    warning('off','optimlib:checkbounds:PadUbWithInf');
else % reset for padded bounds
    lenvlb=length(vlb); ilb=(1:lenvlb)';
    lenvub=length(vub); iub=(1:lenvub)';
end

% Read input options vector or structure
[opts,v,H,ComplexStep]=sqpcrkopts(Opts,ndv);
[~,~,nec] = Fun(x);
% nec=opts(13);
scdv=opts(5)<0; scbou=abs(opts(5));
if opts(7)>0, nlinmax=opts(7); else, nlinmax=30; end
UserHessian=isfield(Opts,'HessFun') && ~isempty(Opts.HessFun);
OutputFcn=isfield(Opts,'OutputFcn') && isa(Opts.OutputFcn,'function_handle');
PlotFcn  =isfield(Opts,'PlotFcns');
trouble=''; UpdHess=[];

if(not(isempty(Opts.UseParallel)) && Opts.UseParallel == true && not(isempty(gcp('nocreate'))))
    pp = gcp();
    ParallelM = pp.NumWorkers;
else
    ParallelM = 0;
end

%% Scale design variables and bounds
if scdv
    x1=x;
    x=ones(size(x));
    for i=find(abs(x1)<max(opts(2),sqrt(eps)))
        x1(i)=ones(size(i));
        x(i)=x0(i);
    end
    if lenvlb, vlb(ilb)=vlb(ilb)./x1(ilb); end
    if lenvub, vub(iub)=vub(iub)./x1(iub); end
    if opts(1)>=2, trouble=' sx'; end
else
    x1=1;
end

%% Set up function and gradient calls with design variable scaling for x.
if all(size(x)==size(x0))
    if scdv
        xshape = @(x) x.*x1;
    else
        xshape = @(x) x;
    end
else
    if scdv
        xshape = @(x) reshape(x(:).*x1,size(x0,1),size(x0,2));
    else
        xshape = @(x) reshape(x(:),size(x0,1),size(x0,2));
    end
end
fun = @(x) feval(Fun,xshape(x),varargin{:});
grd = @(x) feval(Grd,xshape(x),varargin{:});
fdstr = 'sqpfdgrd(fun,x,f0,gs,opts(16),opts(17),x1)';
grdstr = 'sqpcsgrd(fun,x,ncs)';
if ComplexStep && ~isempty(Grd)
    warning('Complex step ignored, since user supplied Grd function')
    ComplexStep = false;
end

%% Initial function evaluation
%
[f0,g0] = fun(x); nfcn=1;
if isempty(f0) || ~isreal(f0) || ~isfinite(f0)
    error('Objective function value must be real')
elseif length(f0)~=1
    error('Objective function value must be scalar')
elseif any( ~isreal(g0) | ~isfinite(g0) )
    error('Constraint values must be real')
end
unconstrained=isempty(g0);
if unconstrained
    if isOctave
        g0=-1; % Octave dn handle inf
    else
        g0=-inf;
    end
else
    g0=g0(:);
end
ncs=length(g0);lenv=ncs+lenvlb+lenvub;
[mg,mj]=max([abs(g0(1:nec));g0(nec+1:ncs)]);
lb=(ncs+1:ncs+lenvlb)'; ub=(lenv-lenvub+1:lenv)';
if OutputFcn || PlotFcn
    out=sqpstructout(opts,[],[],[],mg,0,f0,1,0,0);
end
if OutputFcn,           Opts.OutputFcn(x0,out,'init');  end
if PlotFcn,   plotFcns( Opts.PlotFcns, x0,out,'init' ); end

%% Scale functions
%
lscf = abs(f0)>scbou & scbou;
lscg = any( abs(g0)>scbou ) & scbou & isfinite(scbou);
if lscf
    if opts(6)==-1 % Schittkowski scale factor
        scf = 1/sqrt(abs(f0));
    else
        scf = 1/abs(f0);
    end
    v  = scf*v;
    if opts(1)>=2, trouble=[trouble ' sf']; end
else
    scf=1;
end
if lscg
    j=find(abs(g0)>scbou);
    scg = ones(size(g0));
    if opts(6)==-1 % Schittkowski scale factor
        scg(j) = 1./sqrt(abs(g0(j)));
    else
        scg(j) = 1./abs(g0(j));
    end
    if opts(1)>=2, trouble=[trouble ' sg']; end
else
    scg=1;
end
[f,g,gv,Best]=scalefg(f0,g0,scf,scg,lscg,nec, x,vlb,vub,ilb,iub,v);
gs = gv(1:ncs); % scaled g w/o side constraints

%% Check initial gradients
%
ACTIVE_CONSTRAINTS=1:ncs; % Evaluate all gradients initially
if ComplexStep % Check validity of complex step with user code
    ngrd=1;
    % if isOctave
    %    [fp,gp] = eval('sqpcsgrd(fun,x,ncs,f,gs)');
    % else
    ff = @(x) funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, [], [], opts(4), Best);
    [fp,gp] = sqpcsgrd(ff,x,ncs,f,gs); % [fp,gp] = sqpcsgrd(@funeval,x,ncs,f,gs);
    % end
    grdhdl = @sqpcsgrd;
    [fp,gp,gpv]=scalefgp(fp,gp,[],[],[],[],false,[],lenvlb,lenvub);
else
    ngrd=0;
    u = 0;
    nit = 0;
    [fp,gp,gpv] = grdeval(x);
    grdhdl = Grd;
    clear u nit; %these are cleared because they were never meant to be set here
end
if length(fp)~=ndv || (~(isempty(g0)&&isempty(gp)) && size(gp,1)~=ndv)
    error('User gradient routine returned vectors non-conformal with # design variables')
elseif opts(9) && (~fd_gradients || ComplexStep)
    ff = @(x) funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, [], [], opts(4), Best);
    [fpFD,gpFD]=sqpfdgrd(ff,x,f,gs,opts(16),opts(17),ParallelM);
    disp('Function gradient')
    graderr(fpFD, fp, grdhdl);
    disp('Constraint gradients')
    graderr(gpFD, gp, grdhdl);
end
ALL_CONSTRAINT_GRADIENTS=gp;
ACTIVE_CONSTRAINTS=[];

%% Check Hessian of Lagrangian: H
%
if UserHessian
    if isempty(v), v=guessLM(fp,gp,g,ncs,nec); end
    H=feval(Opts.HessFun,xshape(x),v,varargin{:});
elseif isempty(H)
    H=eye(ndv);
else
    try
        chol(H); % gives error if H not positive definite
    catch
        disp('sqp: Non-positive-definite initial Hessian reset to identity')
        H=eye(ndv);
    end
end
if any(size(H)~=ndv)
    error(['H must be a ' int2str(ndv) ' by ' int2str(ndv) ' matrix.'])
end
if scdv, H=diag(x1)*H*diag(x1); end

%% Check Lagrange multipliers: v
%
if isempty(v)
    v=zeros(lenv,1);
    if abs(opts(6))~=1
        v(1:ncs)=guessLM(fp,gp,gs,ncs,nec);
    end
elseif ncs<lenv && length(v)==ncs
    v=[v(:); zeros(lenv-ncs,1)];
else
    v=v(:);
    if length(v)~=lenv
        error(['The vector v must have ' int2str(lenv) ' elements.'])
    end
end

%%--------------------------------------------------------------------
% Initialize variables
%
nit=0;
flag=[];
mu=1e-4;
beta=0.7; %1e-1;
r=1e-2*ones(lenv,1);rub=1e9;rstep=10;s=[];vold=v;
rholb=1;rhoub=1e6;rhostep=100;rho=1;
deltaub=.9;alpha=0;min_alpha=sqrt(eps);dx=0;ext_pen=0;aug='f';f0=inf;
aeps=1.8*eps;pert=0;nopt=0;sqacc=sqrt(opts(3));xzero=min(sqrt(eps),opts(2));
fs='%4.0f %5.0f %12.5g %9.3g %4.0f %10.3g %4.0f  %9.3g %9.3g';
%---------------------------------------------------------------------
% Display appropriate banner if opts(1)>0
%
if opts(1)>0
    b5=blanks(5);
    ban1s='Termination Criteria';
    ban2s=['Iter f-CNT' b5  '    f(x)' b5 ' STEP  NAC' b5 'max(g)    j  ' b5];
    disp(' ');
    if opts(6)==-1
        disp([blanks(55) ban1s]);
        disp(sprintf('%65.3g %9.3g',sqacc,opts(3))); %#ok<*DSPS>
        disp([blanks(55) '--------------------']);
        ban3s=[' SCV' b5 '  KTO'];
    else
        disp([blanks(45) ban1s]);
        disp(sprintf('%49.3g  %14.3g %9.3g',opts(4),opts(3),opts(2)));
        disp([blanks(39) '------------------------------------']);
        switch opts(6)
            case 1
                ban3s='  AG  max{S/2}';
            case 2
                ban3s=[' NLG' b5 '   DX'];
            otherwise
                ban3s=' KTO    max(S)';
        end
    end
    disp([ban2s ban3s]);
end
    function [mj,lubstr] = marklub(mj,ncs,lenv,lenvlb,lenvub)
        if mj>lenv-lenvub
            mj=mj-ncs-lenvlb;
            lubstr='+';
        elseif mj>ncs
            mj=mj-ncs;
            lubstr='-';
        else
            lubstr=' ';
        end
    end

%%--------------------------------------------------------------------
% Start Main Loop
%
while nit<=opts(15)
    nit=nit+1; minalpha=min_alpha; status=0;
    %------------------------------------------------------------------
    % Solve QP problem for search direction
    %
    %  [s,u,statusqp]=qp(H,fp,gpv',-gv,[],[],s,nec,-1);
    [s,u,statusqp]=qp(H,fp,gp', -gv(1:ncs),vlb-x(ilb),vub-x(iub),s,nec,-1);
    delta=0;sHsfail=0;z0p1fail=0;augfail=0;if aug=='f',nAS=0;end;aug='f';
    SCV=sum(abs(gv(1:nec)))+sum(max(0,gv(nec+1:ncs)));
    %
    % Check status of QP problem
    %
    statusok = strcmp(statusqp(1:2),'ok') || strcmp(statusqp(1:3),'max');
    violated = (SCV>=sqacc && opts(6)==-1)|| mg>opts(4);
    if statusok
        if SCV==0 && fp'*s>=0 % not a descent direction
            warning('sqp:fcd','qp search direction is not a descent direction')
            I=eye(ndv);
            [s1,u,statusqp]=qp(I,fp,gp', -gv(1:ncs),vlb-x(ilb),vub-x(iub),s,nec,-1);
            if strcmp(statusqp(1:2),'ok') && fp'*s1 < fp'*s
                s = s1;
                fprintf('         reset to CSD direction\n')
            end
        end
        if isempty(u)
            warning('sqp:uv','qp trap: empty u=v')
            u=v;
        end % Octave >maxiter dn return u
        if violated && ~UserHessian && s'*H*s<eps
            sHsfail=1;
        else
            sigma=min(r,nit*sqrt(r));
            r=min(rub,2*ncs*(u-v).^2/((s'*H*s)+(1-delta)));
            r=max(sigma,r);
        end
        %
        [z0,z0p1]=merit(v,r,nec,f,gv,fp,gpv,u,s);
        while z0p1>0 && max(r)<rub
            [z0,z0p1]=merit(v,r,nec,f,gv,fp,gpv,u,s);
            if z0p1>0;r=r*rstep;end
        end
        z0p1fail=z0p1>0; % && (fp+gpv*u)'*s>0;
        if z0p1fail && SCV==0 && fp'*s>0
            warning('sqp:z0p1fail', '%s\n%4ssqp: %s\n',...
                'quadprog failed to find descent direction for a feasible design.')
        end
    else
        if opts(1) && ~strcmp(statusqp(1:2),'in')
            disp(['QP problem is ' statusqp '.']);
        end
        if nit~=1
            if isempty(s)
                rho=rholb;
            else
                rho=(2*s'*H*s*(fp'*s)^2);
                rho=max(rholb,rho);
            end
        end
        delta=1;
        if isempty(u), u=v; end % 2/9/20 (RAC)
    end
    slb=[-inf*ones(ndv,1);0]; if lenvlb, slb(ilb)=vlb-x(ilb); end
    sub=[ inf*ones(ndv,1);1]; if lenvub, sub(iub)=vub-x(iub); end
    %
    % Modified QP problem if the previous problem is infeasible
    %
    mod='f';
    rho=min(rho,rhoub);
    while aug=='f' && (delta>=deltaub || z0p1fail || sHsfail)
        while delta>=deltaub && rho<=rhoub
            mod='t'; sHsfail=0; b0=-gv(1:ncs);
            [sdelta,udelta,statusqp]=qp([H zeros(ndv,1);zeros(1,ndv) rho],...
                [fp;0],[gp', b0],b0,slb,sub,[zeros(ndv,1);1],nec,-1);
            s=sdelta(1:ndv);
            delta=sdelta(ndv+1);
            statusok = strcmp(statusqp(1:2),'ok');
            if statusok
                u=udelta(1:lenv);
                if violated && s'*H*s<eps
                    sHsfail=1; break
                end
            else
                flag=['Modified QP problem is ' statusqp '.'];
                break
            end
            rho=rho*rhostep;
        end
        %
        % Try augmented Lagrangian search direction if all else fails
        %
        if aug=='f' && (sHsfail || delta>deltaub || ~statusok)
            aug='t'; nAS=nAS+1; sHsfail=0; delta=0;
            [z0,z0p1,z0p2,z0p3]=merit(v,r,nec,f,gv,fp,gpv,u,s);
            [s,u1,statusqp]=qp(H,z0p2,[],[],slb(ilb),sub(iub),s,nec,-1);
            if ~(strcmp(statusqp(1:2),'ok') || strcmp(statusqp(1:3),'max'))
                flag=['Augmented Lagrangian QP problem is ' statusqp '.'];
                augfail=1; break
            elseif (SCV>=sqacc && opts(6)==-1 || mg>opts(4))
                if s'*H*s<eps
                    flag='Underflow in s''*H*s and infeasible iterate x.';
                    augfail=1; break
                end
            elseif isempty(u1) && (~isempty(ilb)||~isempty(iub))
                flag=strcat('sqp: ',statusqp);
                augfail=1; break
            elseif max(abs(s))<eps
                augfail=1; break
            end
            u=v+z0p3; u([lb ub])=u1;
        end
        if aug=='f' && mod=='t'
            sigma=min(r,nit*sqrt(r));
            r=min(rub,2*ncs*(u-v).^2/((s'*H*s)+(1-delta)));
            r=max(sigma,r);
        end
        [z0,z0p1]=merit(v,r,nec,f,gv,fp,gpv,u,s);
        z0p1fail=z0p1>=0;
        while z0p1fail && max(r)<=rub
            r=r*rstep;
            [z0,z0p1]=merit(v,r,nec,f,gv,fp,gpv,u,s);
            z0p1fail=z0p1>=0;
        end
        if z0p1fail
            if mod=='t' && rho<rhoub
                delta=1; rho=rho*rhostep;
            else
                statusok = 0;
            end
        end
    end
    %------------------------------------------------------------------
    % Display results and check termination criteria
    %
    if scdv, ms=max(abs(s.*x1)); else, ms=max(abs(s)); end
    umin = 1e-10*min(1,max(abs(u)));
    AG=abs(fp'*s)/scf; j=find(abs(u)>umin&isfinite(gv));
    KTO=AG+sum(abs(u(j).*gv(j)));
    NAC=length(find(gv>=-opts(4)|abs(u)>umin|((1:lenv)'<=nec)));
    if aug=='t'
        LG=z0p2;
        if any(isfinite(vlb));LG(ilb)=LG(ilb)-u(lb);end
        if any(isfinite(vub));LG(iub)=LG(iub)-u(ub);end
    else
        av = gv(lb)<=0 & gv(lb)>-xzero; ua=u; ua(lb(av))= fp(ilb(av));
        av = gv(ub)<=0 & gv(ub)>-xzero;       ua(ub(av))=-fp(iub(av));
        av = gv>-opts(4) | (1:lenv)'<=nec;
        LG = fp+gpv(:,av)*ua(av);
    end
    NLG = norm(LG,inf);
    %
    % Add some trouble shooting info to display if opts(1)>1;
    %
    if opts(1)>1
        if mod=='t', trouble=[trouble ' mS'];end %#ok<*AGROW>
        if aug=='t', trouble=[trouble ' aS'];end
        if ext_pen,  trouble=[trouble ' L1'];end
        if pert>0,   trouble=[trouble ' dH=' num2str(pert)];end
        if ischar(UpdHess), trouble=[trouble UpdHess];end; UpdHess=[];
    end
    if opts(1)>2,NLGs=num2str(NLG,4);DBDs=num2str(s'*H*s,4);end
    %
    % Display iteration info
    %
    if opts(1)
        [mj,fs(44)] = marklub(mj,ncs,lenv,lenvlb,lenvub);
        if opts(1)>3 && nit~=1
            disp(['ITERATION ' int2str(nit-1)]);% -1 to match Sch.
            disp([ban2s ban3s]);
        end
        it=nit-1;
        uf=f/scf;
        if opts(6)==(-1)
            disp([sprintf(fs,it,nfcn,uf,alpha,NAC,mg,mj,SCV,KTO),trouble]);
        elseif opts(6)==1
            disp([sprintf(fs,it,nfcn,uf,alpha,NAC,mg,mj,AG/2,ms/2),trouble]);
        elseif opts(6)==2
            disp([sprintf(fs,it,nfcn,uf,alpha,NAC,mg,mj,NLG,norm(dx,inf)),trouble]);
        else
            disp([sprintf(fs,it,nfcn,uf,alpha,NAC,mg,mj,KTO,ms),trouble]);
        end
        trouble='';
    end
    % Call user defined outputfunction
    if OutputFcn || PlotFcn
        out=sqpstructout(opts,u(1:ncs),u(lb),u(ub),mg,nit-1,f,nfcn,ngrd,...
            alpha,NLG);
    end
    if OutputFcn
        stop = Opts.OutputFcn(x,out,'iter');
        % out
        if stop
            out.status = 'Stopped by user output function.';
            return
        end
    end
    if PlotFcn, plotFcns(Opts.PlotFcns,x,out,'iter'); end
    %
    % Check termination criteria
    %
    feasible = mg<opts(4);
    if opts(6)==(-1) % Schittkowski criteria
        feasible = SCV<=sqacc;
        if KTO<=opts(3) && SCV<=sqacc; v=u; break; end
    elseif opts(6)==1
        if ms/2<opts(2) && AG/2<opts(3) && feasible;v=u;break;end
    elseif opts(6)==2
        [z0,z0p1,z0p2]=merit(v,r,nec,f,gv,fp,gpv,u,s);
        Slowed     = abs(f-f0)    < opts(3) && nit > 1 && ...
            max(abs(dx)) < opts(2); % && ...
        %                  abs(f-z0)    < opts(3);
        if (Slowed || NLG < opts(3)) && feasible; v=u;break;end
    else
        if ms<opts(2) && KTO<opts(3) && feasible;v=u;break;end
    end
    if NLG<sqacc && s'*H*s<opts(3)
        nopt=nopt+1;
        if nopt==3
            if feasible
                flag='Merit gradient is zero for 3 iterations & feasible.';
                status=2;
            else
                flag='Termination criteria not met, but merit gradient is zero for 3 iterations.';
                status=-7;
            end
            v=u; break
        end
    else
        nopt=0;
    end
    if ~isempty(lenvlb), s(ilb)=max(s(ilb),slb(ilb)); end
    if ~isempty(lenvub), s(iub)=min(s(iub),sub(iub)); end
    if max(abs(s))<eps
        flag='Adequate search direction could not be found.';
        status=-1;
        break
    elseif ~all(isfinite(u)) || ~all(isfinite(v))
        flag=('Lagrange Multipliers not finite');
        status=-2; v=vold;
        break
    elseif pert>1
        flag='Hessian no longer positive definite';
        status=-3;
        break
    else
        pert=0;
    end
    if any(u(nec+1:ncs)<0)
        if aug~='t' && opts(1)>2, disp('sqp: Negative Lagrange Multipliers corrected'), end
        neg = u(nec+1:ncs)<0;
        u(neg) = abs(u(neg)).*(g(neg)>=0|gp(:,neg)'*s>0);
    end
    %
    %------------------------------------------------------------------
    % Perform line search using Schittkowski's L2 merit function
    %
    % Evaluate the merit function at alpha=1
    xold=x;vold=v;v=u;leastmg=mg;mg0=mg;f0=f;g0=g;
    ext_pen=0;best=0;nlin=0;alpha=1;
    if ~(augfail || z0p1fail)
        x=xold+alpha*s;
        [f,g,gv] = funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, u, nit, opts(4), Best);
        % [f,g,gv]=funeval(x);
        %
        % Establish the termination criteria
        %
        z=merit(v,r,nec,f,gv);
        minalpha = min( opts(2)/max(abs(s)), minalpha );
        while z>z0+mu*alpha*z0p1 && nlin<nlinmax && alpha>minalpha
            nlin=nlin+1;
            %
            % Use 2pt quadradic approx to minimize the merit function
            %
            a2=((z-z0)/alpha-z0p1)/alpha;
            alpha=max([beta*alpha,-z0p1/2/a2,minalpha]);
            x=xold+alpha*s;v=vold+alpha*(u-vold);
            [f,g,gv] = funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, u, nit, opts(4), Best);
            % [f,g,gv]=funeval(x);
            mg=max([abs(g(1:nec)); g(nec+1:ncs); gv(ncs+1:lenv)]);
            z=merit(v,r,nec,f,gv);
        end
        z0p1fail = z>z0+mu*alpha*z0p1; best=alpha;
    end
    %
    % Else L1-merit-function line search to find least infeasible point
    %
    if (z0p1fail && mg>=max(mg0,opts(4))) && opts(6)==0
        ext_pen=1;
        vlm = guessLM(fp,gp,g,ncs,nec,x,ndv,lb,ub,ilb,iub);
        minalpha = min( 1, max( opts(2)/max(abs(s)), alpha ) );
        %     s = qp([],gp*vlm,[],[],slb(1:lenvlb),sub(1:lenvub),s,nec,-1);
        [s,u1] = qp(eye(ndv)/minalpha,gp*vlm,[],[],slb(ilb),sub(iub),s,nec,-1);
        [z0,z0p1] = merit(vlm,[],nec,[],g0,[],gp,[],s); % exterior penalty
        if max(abs(s))>eps && z0>eps
            u=[vlm; u1];
        else
            flag=('No feasible direction to reduce L1 penalty');
            status=-4;
            break
        end
        alpha=1;
        x=xold+alpha*s;
        [f,g,gv] = funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, u, nit, opts(4), Best);
        % [f,g,gv]=funeval(x);
        mg=max([abs(g(1:nec)); g(nec+1:ncs); gv(ncs+1:lenv)]);
        if mg<leastmg && mg>(-eps)
            leastmg=mg; best=alpha; bestf=f; bestgv=gv; bestx=x;
        end
        z = merit(vlm,[],nec,[],g);
        z0p1fail = mg>leastmg || mg<(-opts(4)) || z>z0+mu*alpha*z0p1;
        nlinmax2 = nlin + nlinmax;
        if max(abs(s))>opts(2)/2
            minalpha = min( opts(2)/max(abs(s)), min_alpha );
        else
            alpha=0;
        end
        while z0p1fail && nlin<nlinmax2 && alpha>minalpha
            nlin=nlin+1;
            a2=((z-z0)/alpha-z0p1)/(alpha);
            alpha=max([beta*alpha,-z0p1/2/a2,minalpha]);
            x=xold+alpha*s; v=vold+alpha*(u-vold);
            [f,g,gv] = funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, u, nit, opts(4), Best);
            % [f,g,gv]=funeval(x);
            mg=max([abs(g(1:nec)); g(nec+1:ncs); gv(ncs+1:lenv)]);
            z = merit(vlm,[],nec,[],g);
            z0p1fail = mg>leastmg || mg<(-opts(4)) || z>z0+mu*alpha*z0p1;
            if mg<leastmg && mg>(-opts(4))
                leastmg=mg; best=alpha; bestf=f; bestgv=gv; bestx=x;
            end
        end
    end
    if nAS>=3 && leastmg>Best.mg
        flag='Augmented Search direction failed after 3 tries.';
        status=-5;
        break
    elseif z0p1fail
        if leastmg < mg0
            alpha=best; f=bestf; gv=bestgv; g=bestgv(1:ncs); x=bestx; s=x-xold;
            v=vold+alpha*(u-vold);
            if opts(1)>2
                disp(['sqp: Line search: mg0= ' num2str(mg0) ' leastmg=' num2str(leastmg)])
            end
        elseif alpha==0 || best==0
            flag='No significant improvement found in line search.';
            status=-6;
            break
        end
    end
    [mg,mj]=max([abs(g(1:nec)); g(nec+1:ncs); gv(ncs+1:lenv)]);
    if nfcn>opts(14)
        flag='Maximum # function evaluations exceeded. Increase opts(14).';
        status=0;
        break
    elseif nit>opts(15)
        flag='Maximum iterations exceeded. Increase opts(15).';
        status=0;
        break
    end

    %------------------------------------------------------------------
    % Evaluate gradients using active set strategy
    %
    active = find(u(1:ncs)>umin|gs>-opts(4)|(1:ncs)'<=nec);
    ACTIVE_CONSTRAINTS=union(active,ACTIVE_CONSTRAINTS);
    [fpnew,gpnew,gpv]=grdeval(x);
    if isOctave
        ACTIVE_CONSTRAINTS=active; % Octave forgets?!
    end
    if aug=='t'
        qq=z0p2;
        if ~isempty(vlb);slb=zeros(ndv,1);slb(ilb)=u(lb);qq=qq+slb;end
        if ~isempty(vub);sub=zeros(ndv,1);sub(iub)=u(ub);qq=qq+sub;end
    elseif isempty(ACTIVE_CONSTRAINTS)
        qq=fpnew-fp;
    else
        qq=(fpnew-fp)+(gpnew(:,ACTIVE_CONSTRAINTS)-gp(:,ACTIVE_CONSTRAINTS))*u(ACTIVE_CONSTRAINTS);
    end
    dx=alpha*s;
    %------------------------------------------------------------------
    %
    % Update the Hessian using Powell's modified BFGS method
    %
    if UserHessian
        H=feval(Opts.HessFun,xshape(x),v,varargin{:});
        if scdv, H=diag(x1)*H*diag(x1); end
    elseif any(abs(dx)>eps)
        Hdx=H*dx;
        Y=dx'*Hdx;
        if dx'*qq>=.2*Y
            q=qq;
        else
            theta=.8*Y/(Y-dx'*qq);
            q=theta*qq+(1-theta)*Hdx;
        end
        if q'*dx<eps % Try nlconst perturbation
            factor = gpnew*g - gp*g0;
            [q,UpdHess] = nlconst_HessUpd( qq, dx, H, factor, alpha );
        end
        H = H + (q*q')/(q'*dx)-(Hdx*Hdx')/Y;
        Hnonsym = norm(H-H',inf);
        if Hnonsym > eps
            H = (H+H')/2;
            if Hnonsym/norm(H,inf) > 1e-4
                disp('sqp: Warning: H was not symmetric')
            end
        end
        if max(Y,q'*dx) < eps %&& rcond(H)<eps
            try
                chol(H);
            catch
                % Increase the diagonal elements of H if H is ill-conditioned
                dE=abs(eig(H,'nobalance'));
                pert=(min(dE)+aeps*max(dE))/(1-aeps);
                H=H+pert*eye(ndv);
            end
        end
    else
        warning('sqp:skipHess','Hessian update skipped, dx too small.')
    end
    fp=fpnew;gp=gpnew;
    %------------------------------------------------------------------
    % Display additional trouble shooting information if opts(1)>2
    %
    if opts(1)>2
        DLPs=num2str(z0p1,4);MFs=num2str(z,4);
        disp(['NLG=' NLGs blanks(12-length(NLGs)) 'DBD=' DBDs,...
            blanks(12-length(DBDs)) 'DLP=' DLPs blanks(12-length(DLPs)),...
            'MERIT FCN=' MFs]);disp(' ');
    end
    if opts(1)>3
        vold=vold/scf; if lscg,vold(1:ncs)=vold(1:ncs).*scg;end
        disp('VARIABLE:  X=');disp(xold(:)');
        disp('MULTIPLIERS:  U=');disp(vold(:)');
        disp('PENALTY PARAMETER:  R=');disp(r(:)');
        disp(' ');disp(' ');
    end
end
%---------------------------------------------------------------------

%% Display final results and return information in "out" variable
%
if length(v)~=lenv
    v=vold;
end
if lscf, f=f/scf; end
if opts(1)>2 && isempty(flag) && nargout<3
    disp('Active Constraints')
    disp(find(v(1:ncs))')
    if any(v(lb)), disp('Active Lower Bounds'), disp(find(v(lb))'), end
    if any(v(ub)), disp('Active Upper Bounds'), disp(find(v(ub))'), end
    if any(v)
        disp('Lagrange Multipliers')
        disp(sprintf('%12.4g   %12.4g   %12.4g   %12.4g   %12.4g\n',v(v~=0)))
    end
end
if isempty(flag)
    if nit>opts(15)
        status = 0;
    elseif status==0
        status = 1;
    end
end
if status<=0 && nargout<5 && nec>0
    error(flag)
else
    mgtol = opts(4)/10;
    %  if status<=0 % (Not implemented for equality constraints in scalefg)
    if Best.nit>0 && nec==0 && ( (~feasible  && mg > Best.mg) ...
            || (f>Best.Obj && max(mg,mgtol) >= Best.mg) )
        x=Best.X;
        f=Best.Obj;
        v=Best.LM;
        mg=Best.mg;
        if mg>opts(4)
            feastr = 'least infeasible';
        else
            feastr = 'best feasible';
        end
        if opts(1)
            [mj,fs(44)] = marklub(Best.mj,ncs,lenv,lenvlb,lenvub);
            disp(sprintf(fs,Best.nit,nfcn,f,0,NAC,mg,mj));
            disp(['Returning ',feastr,' solution.'])
        end
        if isempty(flag)
            flag = feastr;
        else
            flag = [flag,' Returning ',feastr];
        end
    end
end
if opts(1)
    if status==1
        disp('Optimization Terminated Successfully from sqp')
    else
        disp('Optimum not found in sqp.')
        disp(flag)
    end
    disp(' ')
end

opts(8)=f;opts(10)=nfcn;opts(11)=ngrd;
if OutputFcn
    out=sqpstructout(opts,v(1:ncs),v(lb),v(ub),mg,nit);
    if(not(isfield(out,'stepsize')))
        out.stepsize = 0;
    end
    if(not(isfield(out,'firstorderopt')))
        out.firstorderopt = 0;
    end

    Opts.OutputFcn(x,out,'iter');
    Opts.OutputFcn(x,out,'done');
end
if PlotFcn
    out=sqpstructout(opts,v(1:ncs),v(lb),v(ub),mg,nit);
    plotFcns(Opts.PlotFcns,x,out,'iter');
    plotFcns(Opts.PlotFcns,x,out,'done');
end
if scdv
    x=reshape(x1.*x,size(x0,1),size(x0,2));
    if nargout>3, H=diag(1./x1)*H*diag(1./x1); end
elseif size(x)~=size(x0)
    x=reshape(x,size(x0,1),size(x0,2));
end
if nargout>1
    opts(8)=f;opts(10)=nfcn;opts(11)=ngrd;
    opts(12)=opts(10);opts(14)=nit-1;
    v=v/scf; if lscg,v(1:ncs)=v(1:ncs).*scg;end % Scale Lagrange Multipliers
    if isstruct(Opts) && ~isfield(Opts,'foptions')
        [out,v]=sqpstructout(opts,v(1:ncs),v(lb),v(ub),mg);
        out.status=flag;
    else
        out = opts;
    end
end


%% Nested sub-functions
% function [f,g,gv] = funeval( x )
%    [f,g] = fun(x);
%    nfcn=nfcn+1;
%
%    if nargout<3 % scale g for fd and cs
%       [f,g] = scalefg( f,g, scf, scg, lscg );
%    else % g unscaled, gv is scaled
%       [f,g,gv,Best]=scalefg( f, g, scf, scg, lscg, nec, ...
%                              x, vlb, vub, ilb, iub, u, ...
%                              nit, opts(4), Best );
%    end
% end

    function [fp,gp,gpv] = grdeval( x )
        ngrd=ngrd+1;
        if ComplexStep
            [fp,gp] = sqpcsgrd(@funeval,x,ncs);
        elseif fd_gradients
            gs=gv(1:ncs);
            ff = @(x) funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, u, nit, opts(4), Best);
            [fp,gp] = sqpfdgrd(ff,x,f,gs,opts(16),opts(17),ParallelM);

            %this adds the correct number of function evaluations if we run the gradient in parallel.
            if(ParallelM > 0)
                nfcn = nfcn + numel(x);
            end
        else
            [fp,gp] = grd(x);
        end
        nac=length(ACTIVE_CONSTRAINTS);
        ng=size(gp,2);
        if ng<ncs
            if ng==nac % update only active constraint gradients
                ALL_CONSTRAINT_GRADIENTS(:,ACTIVE_CONSTRAINTS)=gp;
                gp=ALL_CONSTRAINT_GRADIENTS; % use old & new gradients
            elseif isempty(gp) && unconstrained
                gp=zeros(ndv,1);
            else
                error(['User supplied number of gradients = ' num2str(ng) ' ~= #active = ' num2str(nac)])
            end
        else
            if nac==ncs
                ALL_CONSTRAINT_GRADIENTS=gp;
            else
                ALL_CONSTRAINT_GRADIENTS=[];
            end
        end
        % if nargout>2 && ...             % get gpv
        %         (fd_gradients || ComplexStep) % but do not scale gradients for dv
            [fp,gp,gpv]=scalefgp(fp,gp,[],[],[],[],false,[],lenvlb,lenvub);
        % else % scale user-supplied analytic gradients
        %     [fp,gp,gpv]=scalefgp(fp,gp,scf,scg,lscf,lscg,scdv,x1,lenvlb,lenvub);
        % end
    end

end
% ------------ End of sqp main routine ------------
function [f,g,gv] = funeval(x, fun, scf, scg, lscg, nec, vlb, vub, ilb, iub, u, nit, opts4, Best)
[f,g] = fun(x);
% nfcn=nfcn+1;

if nargout<3 % scale g for fd and cs
    [f,g] = scalefg( f,g, scf, scg, lscg );
else % g unscaled, gv is scaled
    [f,g,gv,Best]=scalefg( f, g, scf, scg, lscg, nec, ...
        x, vlb, vub, ilb, iub, u, ...
        nit, opts4, Best );
end
end


%% Sub-function to evaluate the descent merit function
function [psi,psip1,psip2,psip3]=merit(v,r,nec,f,g,fp,gp,u,s)
%
% MERIT     Evaluates the merit function associated with the line
%           search in sqp.m.
%
% usage:    [psi,psip1,psip2,psip3]=merit(v,r,nec,f,g,fp,gp,u,s)
%
% inputs:   v     - Estimates of the optimal Lagrange multipliers
%           r     - scalar penalty parameter
%           nec   - number of equality constraints
%           f     - function value
%           g     - constraint values
%           fp    - (required for psip1-3) function gradient
%           gp    - (required for psip1-3) constraint gradients
%           u     - (required for psip1-3) Lagrange multipliers
%                   for QP search direction problem
%           s     - (required for psip1-3) search direction
%
% outputs:  psi   - value of the merit function at alpha
%           psip1 - derivative of the merit function wrt alpha
%           psip2 - derivative of the merit function wrt x
%           psip3 - derivative of the merit function wrt v
%
%
% Created by:    Capt Mark Spillman
%                AFIT/ENY
%                Created:       12/5/94
%                Last modified: 3/27/07

% Modifications
% 1/12/95 - (MSS)
% 3/13/95 - Transpose 'a' to handle nec>0 & ncs>nec+1 (RAC)
% 8/12/99 - Fix MatLab 5.2 compilation warnings (RAC)
% 3/27/07 - Null r is for L1 exterior penalty

if nargin<9 && nargout>1
    error('merit - 9 input arguments must be provided to compute psip1-3.')
end
if nargin<5;error('merit - 5 input arguments must be provided.'); end

% L1 Exterior penalty for infeasible designs
if isempty(r)
    ncs = length(v);
    v = v.*(g(1:ncs)>0&v>0 | (1:ncs)'<=nec); % positive multipliers for ineq.
    psi = abs(v)'*[abs(g(1:nec)); max(0,g(nec+1:ncs))];
    if nargout>1
        psip1 = s'*gp*v;
    end
    return
end

% Switch signs on g and gp to match Schittkowski's conventions
g=-g;
if nargin>5;gp=-gp; end

% Determine the active(a) and inactive(i) constraints
ncs=size(v,1);
a=find(g(nec+1:ncs)<=v(nec+1:ncs)./r(nec+1:ncs));a=[1:nec a'+nec];
i=find(g(nec+1:ncs)>v(nec+1:ncs)./r(nec+1:ncs));i=i+nec;

% Evaluate the merit function
if isempty(a) && isempty(i)
    psi=f;
elseif isempty(a)
    psi=f-sum(.5*(v.^2)./r);
elseif isempty(i)
    psi=f-(v'*g-.5*r'*g.^2);
else
    psi=f-sum(.5*(v(i).^2)./r(i))-(v(a)'*g(a)-.5*r(a)'*g(a).^2);
end

% Evaluate psip1, psip2 and psip3
if nargout>1
    psip3=zeros(ncs,1);
    if isempty(a) && isempty(i)
        psip2=fp;
        psip1=fp'*s;
    elseif isempty(a)
        psip3=-(v./r);
        psip2=fp;
        psip1=psip2'*s+psip3'*(u-v);
    elseif isempty(i)
        psip3=-g;
        psip2=fp-gp*(v-r.*g);
        psip1=psip2'*s+psip3'*(u-v);
    else
        psip3(i)=-v(i)./r(i);psip3(a)=-g(a);
        psip2=fp-gp(:,a)*(v(a)-r(a).*g(a));
        psip1=psip2'*s-(v(i)./r(i))'*(u(i)-v(i))-g(a)'*(u(a)-v(a));
    end
end
end



%% Sub-function to scale objective, f0, and constraints, g0
function [f,g,gv,Best]=scalefg(f0, g0, scf, scg, lscg, nec, ...
    x, vlb, vub, ilb, iub, v, it, tolcon, Best)
% Modified:  5/12/06 - allow empty g
%           12/11/07 - Track best design
%             6/1/20 - Best.mj accounts for l/ub; nec is input arg.
if nargin<13,   it=0;    end
if isempty(g0), g0=-inf; end
f=scf*f0;
g=g0(:);
mg=max(g);                          % unscaled
if lscg, gv=scg.*g; else, gv=g; end % scaled
if nargin>5
    if ~isempty(vlb);gv=[gv;vlb-x(ilb)];end
    if ~isempty(vub);gv=[gv;x(iub)-vub];end
elseif nargout<3
    g = gv;   % scale g for finite difference or complex step
end
if nargout>3 && ...
        (nargin<15 || Best.mg>tolcon && mg<Best.mg || mg<=tolcon && f0<Best.Obj)
    ncs=length(g);
    [mg,mj]=max([abs(g(1:nec)); g(nec+1:ncs); gv(ncs+1:end)]);
    Best.Obj = f0;
    Best.LM  = v;
    Best.X   = x;
    Best.mg  = mg;
    Best.mj  = mj;
    Best.nit = it;
end
end



%% Sub-function to scale objective gradient, fp, and constraint gradients, gp
function [fp,gp,gpv]=scalefgp( fp, gp, scf, scg, lscf, lscg, scdv, x1, lenvlb, lenvub )
ndv=length(fp);
fp = fp(:);
if isempty(gp) || (length(gp)==1 && gp==0) % unconstrained problem
    gp=zeros(ndv,1);
end
if ~isempty(lscf) && ~isempty(lscg)
    if lscf, fp=scf*fp; end
    if lscg, gp=(ones(ndv,1)*scg') .* gp; end
    if scdv
        fp=x1.*fp;
        gp=diag(x1)*gp;
    end
end
if lenvlb, gpv=[gp -eye(ndv,lenvlb)]; else, gpv=gp; end
if lenvub, gpv=[gpv eye(ndv,lenvub)]; end
end



%% Sub-function to guess the Lagrange Multipliers
function v = guessLM(fp,gp,cs,ncs,nec,x,ndv,lb,ub,ilb,iub)
if isempty(gp) || (length(gp)==1 && gp==0)
    v=0;
    return
end % unconstrained problem
if nargin>5
    %     cut = min(0,max(cs))-0.1*abs(max(cs));
    cut = -1e-4; tolx = 1e-6;
    active = (cs >= cut) | (1:ncs)'<=nec;
    free   = true(ndv,1);
    free(ilb) = x(ilb) > lb+tolx;
    free(iub) = x(iub) < ub-tolx;
    v = zeros(ncs,1);
    if any(free) && norm(gp(free,active),inf)>0
        v(active) = -gp(free,active) \ fp(free);
    end
end
if nargin < 6 || any(v(nec+1:ncs)<0)
    den = gp'*fp;
    if any(den==0)
        vlm = zeros(ncs,1);
        vlm(den~=0) = -fp'*fp ./ den(den~=0);
    else
        vlm = -fp'*fp ./ den;
    end
    for j = find(vlm'<0 & (1:ncs)>nec) % revise inequality negative LM
        i = abs(gp(:,j)) > eps;
        vlm(j) = max(abs(-fp(i)./gp(i,j)));
    end
    if all(isfinite(cs))
        if max(cs)>eps
            v = vlm .* exp( cs/max(cs) - 1 );
        else
            v = vlm .* exp( cs - max(cs) );
        end
    else
        v = vlm;
    end
    % positive multipliers for ineq. (zero out neg multipliers)
    v( v<0 & (1:ncs)'>nec ) = 0;
end
end



%% Sub-function for Hessian Update with nonlinear constraints
function [YL,how] = nlconst_HessUpd( YL, sdiff, HESS, FACTOR, steplength )
% Make sure Hessian is positive definite in update.
if YL'*sdiff<steplength^2*1e-3
    while YL'*sdiff<-1e-5
        [YMAX,YIND]=min(YL.*sdiff); %#ok<ASGLU>
        YL(YIND)=YL(YIND)/2;
    end
    if YL'*sdiff < (eps*norm(HESS,'fro'))
        how=' Hessian modified twice';
        FACTOR=FACTOR.*(sdiff.*FACTOR>0).*(YL.*sdiff<=eps);
        WT=1e-2;
        if max(abs(FACTOR))==0; FACTOR=1e-5*sign(sdiff); end
        while YL'*sdiff < (eps*norm(HESS,'fro')) && WT < 1/eps
            YL=YL+WT*FACTOR;
            WT=WT*2;
        end
    else
        how=' Hessian modified';
    end
else
    how=[];
end
end



%% SQP's Finite Difference Gradient sub-function
function [df,dg] = sqpfdgrd( fcn, x0, f0, g0, xmin, xmax, ParallelM )
% SQPFDGRD      Calculates first forward finite difference gradients
%               of objective and constraint functions for the
%               Sequential Quadratic Programming (sqp) routine.
%
% usage:        [df,dg]=sqpfdgrd(fcn, x0, f0, g0, xmin, xmax, x1,P1,...,P15)
%
% inputs:       fcn       - function evaluation call
%               x0        - current design variable vector
%               f0        - objective value at x0
%               g0        - constraint values at x0
%               xmin      - minimum finite difference step
%               xmax      - maximum finite difference step
%               x1        - scale factor for design variables
%               ParallelM - Number of parallel workers to run grad with -
%                           set to 0 to run in serial.
%
% outputs:      df       - finite difference objective gradient vector
%               dg       - finite difference constraint gradients matrix
%
% Written by:   Robert A. Canfield
%               AFIT/ENY, Bldg. 640
%               2950 Hobson Way
%               WPAFB, OH  45433-7665
%
% Created:      2/20/95
% Modified:      6/8/20

% Modifications
% 2/21/95 - Shortened name for DOS compatibility.
% 2/28/95 - Compatible with matrix of design variables 'x'.
% 3/25/95 - x1 may be null (RAC).
% 8/23/99 - Fix version 5.1 warnings.
% 2/28/00 - x1 may be absent.
% 6/28/01 - Set dg to null for unconstrainted problem.
%  5/5/04 - Use feval and varargin instead of eval w/ P1,P2,...
%  5/6/13 - Preallocate memory for df,dg
% 9/28/15 - Eliminate sx inline function for scaling by x1
%  6/3/20 - perturb scaled x (i.e., ignore x1)
%  6/7/20 - sub-function for MATLAB or string eval for Octave

% Local variables
%
% dx....... Finite difference step
% f........ Perturbed objective value
% g........ Perturbed constraint values
% i........ Loop variable for current design variable perturbation

%--BEGIN
%
if nargin<5 || isempty(xmin), xmin=1e-8; end
if nargin<6 || isempty(xmax), xmax=1e-1; end
% if nargin<8 || isempty(sx), sx=inline('x','x','x1'); end

% Less stringent relative change in x than 1.e-8 may be
% needed for implicit functions that require numeric evaluation.
dx = min( max(1.e-8*abs(x0(:)),xmin), xmax );
df = zeros(size(x0));
dg = zeros(length(x0),length(g0));

% Forward Finite Difference loop.
numIterations = length(x0(:));

if(ParallelM > 0)
    % parfevalOnAll(@warning,0,'off','all'); %necessary to avoid throwing a bunch of errors on the workers having to do with loading AppDesigner base class for some reason.
    opts = parforOptions(gcp(), "RangePartitionMethod","fixed", "SubrangeSize",1);
else
    opts = ParallelM;
end

parfor(i=1:numIterations, opts) %opts
    x = x0;
    x(i) = x(i) + dx(i);
    [f,g] = fcn(x); %#ok<PFBNS>
    df(i,1) = (f - f0) / dx(i);
    if ~isempty(g)
        dg(i,:) = (g(:) - g0(:))'/ dx(i);
    end
end

if(ParallelM > 0)
    parfevalOnAll(@clear, 0);
end
end



%% SQP's sub-function for Complex Step Gradient
function [gradf,gradg] = sqpcsgrd( fcn, x, ncs, f0, g0 )
if nargin<5, g0=-1; end % unconstrained
ndv=length(x);
gradf=zeros(ndv,1);
gradg=zeros(ndv,ncs);
for n=1:ndv
    xc = x;
    xc(n) = xc(n) + 1i*eps;
    [fc,gc] = fcn(xc);
    if isempty(gc), gc=g0; end % unconstrained
    gradf(n)   = imag(fc)/eps;
    gradg(n,:) = imag(gc(:)).'/eps;
    if nargin>3 % check consistency of function values
        check_cs_fun( f0, real(fc), n );
        check_cs_fun( g0, real(gc), n );
    end
end
end

function check_cs_fun( f0, fr, n )
tol = 1e-9;
[reldif,j]=max(abs(f0-fr(:))./max(1,abs(f0)));
if  reldif > tol
    fprintf('sqpcsgrd design variable n = %6.0f\n', n)
    fprintf('         function value = %16.10g\n', f0(j))
    fprintf('         real part      = %16.10g\n', fr(j))
    if length(f0)>1
        disp('         for constraint vector')
    end
    warning('sqp:csgrd','Complex step generates inconsistent function value')
end
end



%% MATLAB utility sub-function to report discrepancies with finite difference
function graderr(finite_diff_deriv, analytic_deriv, gradfcn)
%GRADERR Checks gradient discrepancy in optimization routines.
%
% This is a helper function.

%   Copyright 1990-2004 The MathWorks, Inc.
%   $Revision: 1.1.4.1 $  $Date: 2004/03/26 13:27:17 $

try
    if isa(gradfcn,'function_handle')
        gradfcnstr = func2str(gradfcn);
    else
        gradfcnstr = char(gradfcn);
    end
catch
    gradfcnstr = '';
end

finite_diff_deriv = full(finite_diff_deriv);
analytic_deriv = full(analytic_deriv);
err=max(max(abs(analytic_deriv-finite_diff_deriv)));
disp(sprintf('Maximum discrepancy between derivatives  = %g',err));
if (err > 1e-6*norm(analytic_deriv) + 1e-5)
    disp('Warning: Derivatives do not match within tolerance')
    disp('Derivative from finite difference calculation:')
    disp(finite_diff_deriv)
    if ~isempty(gradfcnstr)
        disp(['User-supplied derivative, ', gradfcnstr ': '])
    else
        disp( 'User-supplied derivative: ')
    end
    disp(analytic_deriv)
    disp('Difference:')
    disp(analytic_deriv - finite_diff_deriv)
    disp('Strike any key to continue or Ctrl-C to abort')
    pause
end
end



%% Sub-function to transform user's fmincon function evauluation functions
function [f,g,nec] = fun2(x,Obj,Con,A,b,Aeq,beq)
f   = Obj(x);
if isempty(Con)
    g = [];
    h = [];
else
    [g,h] = Con(x);
end
if nargin<4
    A = [];
    b = [];
end
if nargin<6
    Aeq = [];
    beq = [];
end
if ~isempty(A) && ~isempty(b)
    c = A*x(:) - b(:);
    g = [g,c];
end
if ~isempty(Aeq) && ~isempty(beq)
    ceq = Aeq*x(:) - beq(:);
    h   = [h,ceq];
end
nec = length(h);
g = [h(:); g(:)];
end



%% Sub-function to transform user's fmincon gradient evauluation functions
function [gradf,gradg] = grd2(x,Obj,Con,A,Aeq)
if isempty(Con)
    gradg = [];
    gradh = [];
else
    [~,gradf] = Obj(x);
    [~,~,gradg,gradh] = Con(x);
end
if nargin<4
    A = [];
end
if nargin<5
    Aeq = [];
end
if ~isempty(A)
    gradc = A;
    gradg = [gradg,gradc];
end
if ~isempty(Aeq)
    gradceq = Aeq;
    gradh   = [gradh,gradceq];
end
gradg = [gradh, gradg];
end
%---------------------------END OF FILE-------------------------------
