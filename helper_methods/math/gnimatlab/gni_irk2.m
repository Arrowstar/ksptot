function [tout,qout,pout,teout,qeout,peout,ieout,term] = gni_irk2(odefile,tspan,y0,options,varargin)
%GNI_IRK2  Solves second-order differential equations with an implicit Runge-Kutta method.
%   [T,Q,P] = GNI_IRK2('F',TSPAN,[Q0;P0]) with TSPAN = [T0 TFINAL] integrates the
%   system of differential equations q'' = F(t,q) from time T0 to TFINAL with
%   initial conditions q = Q0, q' = P0.  'F' is a string containing the name of
%   a GNI problem file.  Function F(t,q) must return a column vector.  Each row in
%   solution arrays Q, P corresponds to a time returned in column vector T.
%   
%   [T,Q,P] = GNI_IRK2('F',TSPAN,[Q0;P0],OPTIONS) solves as above with default
%   integration parameters replaced by values in OPTIONS, an argument
%   created with the GNISET function.  See GNISET for details. Additional
%   parameters can be passed to the GNI problem file as in the ODE suite.
%   
%   It is also possible to specify TSPAN, Y0 and/or OPTIONS in the GNI problem 
%   file. In this case, the corresponding arguments should be empty.
%   
%   As an example, the command
%   
%       gni_irk2('kepler',[],[],[],0.5);
%   
%   solves the two-body Kepler problem with default parameters defined in 
%   kepler.m and eccentricity equal to 0.5.
%
%   [T,Q,P,TE,PE,QE,IE] = GNI_IRK2('F',TSPAN,[Q0;P0],OPTIONS) with the Events 
%   property in OPTIONS set to 'on', solves as above while also locating zero 
%   crossings of event function(s) defined in the GNI problem file. As an example,
%   the sequence of commands
%
%       [T,Q,P,TE,QE,PE] = gni_irk2('henon');
%       plot3(QE(:,2),PE(:,1),PE(:,2),'o');
%
%   draws the Poincare section of the standard Henon-Heiles problem.
%
%   GNI_IRK2 implements symmetric symplectic Gauss methods of order 4, 8, and 12.
%
%   Details are to be found in the article "GniCodes - Matlab Programs for Geometric
%   Numerical Integration", available from http://www.unige.ch/math/folks/hairer/
%   under item software
%
%   Copyright by Ernst Hairer and Martin Hairer, 10.10.2002.

true = logical(1);
false = ~true;

term = false;
nstps = 0;

if nargin == 0
  error('Not enough input arguments.  See GNI_IRK2.');
elseif ~isstr(odefile) & ~isa(odefile, 'inline')
  error('First argument must be a single-quoted string.  See GNI_IRK2.');
end

if nargin == 1
  tspan = []; y0 = []; options = [];
elseif nargin == 2
  y0 = []; options = [];
elseif nargin == 3
  options = [];
elseif ~isempty(options) & ~isa(options,'struct')
  if (length(tspan) == 1) & (length(y0) == 1) & (min(size(options)) == 1)
    msg = sprintf('Use gni_irk2(''%s'',tspan,y0,...) instead.',odefile);
    error(['Obsolete syntax.  ' msg]);
  else
    error('Correct syntax is gni_irk2(''odefile'',tspan,y0,options).');
  end
end

if isstr(odefile) & (exist(odefile) == 4) % a SIMULINK model
	error('Use the SIM command directly for SIMULINK models.');
	return;
end

% Get default tspan and y0 from odefile if none are specified.
if isempty(tspan) | isempty(y0)
  if (nargout(odefile) < 3) & (nargout(odefile) ~= -1)
    msg = sprintf('Use gni_irk2(''%s'',tspan,y0,...) instead.',odefile);
    error(['No default parameters in ' upper(odefile) '.  ' msg]);
  end
  [def_tspan,def_y0,def_options] = feval(odefile,[],[],'init',varargin{:});
  if isempty(tspan)
    tspan = def_tspan;
  end
  if isempty(y0)
    y0 = def_y0;
  end
  if isempty(options)
    options = def_options;
  else
    options = gniset(def_options,options);
  end
end

% Test that tspan is internally consistent.
if size(y0,2) ~= 1
	y0 = y0';
end
ntspan = length(tspan);
if ntspan > 2
	error('The timespan must consist of one or two numbers.');
end
if ntspan == 1
	tspan = [0;tspan];
  t0 = 0;
else
	t0 = tspan(1);
end

tfinal = tspan(2);
if t0 >= tfinal
  error('The final time must greater than the starting time.');
end

outstep = gniget(options,'OutputSteps',1);
if (size(outstep) ~= [1 1])
	error('The option ''OutputSteps'' must contain a single number');
end
outflag = 0;
if (outstep > 0)
	outflag = 1;
else
	outstep = 1;
end

t = t0;

if (mod(length(y0),2) ~= 0)
	error('The initial value must have 2*N components, where N is the dimension of the system.');
end
neq = length(y0)/2;
Q = y0(1:neq);
P = y0((neq+1):(2*neq));

if nargout > 0
  outfun = gniget(options,'OutputFcn');
else
  outfun = gniget(options,'OutputFcn','odeplot');
end
if isempty(outfun)
  haveoutfun = false;
else
  haveoutfun = true;
  outputs = gniget(options,'OutputSel',1:(2*neq));
end

canvector = strcmp(gniget(options,'Vectorized','off'),'on');
locateevents = strcmp(gniget(options,'Events','off'),'on');
teout = [];
qeout = [];
peout = [];
ieout = [];
if locateevents
	[V,terminal,direction] = feval(odefile,t,[Q;P],'events',varargin{:});
end

maxiter = gniget(options,'MaxIter',50);

h = gniget(options,'StepSize');
if (isempty(h))
	nsteps = gniget(options,'NumSteps');
	if (isempty(nsteps))
		h = 1e-2;
		fprintf('Warning: No initial step size provided, using h=1e-2 instead.\n');
	else
		h = (tfinal - t0)/nsteps;
	end
end
if ((~isa(h,'double')) | (size(h) ~= [1 1]))
	error('The option ''StepSize'' must contain a single number');
end

% Allocate memory if we're generating output.
chunk = 1;
if nargout > 0
  chunk = max(ceil(128 / neq),1);
  tout = zeros(chunk,1);
  pout = zeros(chunk,neq);
  qout = zeros(chunk,neq);
	
  nout = 1;
  tout(nout) = t;
  qout(nout,:) = Q.';
  pout(nout,:) = P.';
end

if isempty(varargin)
  args = {};
else
  args = [{[]} varargin];
end

FS = feval(odefile,t,Q,args{:});
[m,n] = size(FS);
if n > 1
  error([upper(odefile) ' must return a column vector.'])
elseif m ~= neq
  msg = sprintf('an initial condition vector of length 2*%d.',m);
  error(['Solving ' upper(odefile) ' requires ' msg]);
end

% Initialize the output function.
if haveoutfun
	PQ = [Q;P];
  feval(outfun,[t tfinal],PQ(outputs),'init');
end

% Initialize the IRK method

method = gniget(options,'Method','G12');
[ns,nm,C,B,BC,AA,E,SM,AM] = coeff_irk2(method);

uround = 2.221e-16;

B = B * h;
BC = BC * h^2;
C = C * h;
AA = AA * h^2;
E(1:ns,1:ns) = E(1:ns,1:ns) * h^2;
E(1:ns,(ns+1):(ns+nm)) = E(1:ns,(ns+1):(ns+nm)) * h^2; % ns x ns+nm
AM((ns+1):(ns+nm)) = AM((ns+1):(ns+nm)) * h; % 

ZQ = P * C' + 0.5 * FS * C'.^2; % neq x ns
PS = P;
EQ = zeros(neq,1);
EP = zeros(neq,1);

F = zeros(neq,ns);

% THE MAIN LOOP

done = false;
outpoint = 0;
addpoint = false;
steppos = 0;
%while ~done
nsteps = round((tfinal - t0)/h);
for iter = 1:nsteps
	if locateevents
		QOld = Q;
		POld = P;
 		VOld = V;
	end

	tnew = t+h;
%	if (tnew >= tfinal)
%		done = true;
%	end
	
	addpoint = false;
	outpoint = outpoint + 1;
	if (outpoint >= outstep)
		outpoint = 0;
		addpoint = true;
	end
	% Start of actual step ynew = y + h*...
  	
	
	%% CALL STARTB
	if (nstps > 0)
		YH = ZQ * AM(1:ns) + AM(ns+1)*PS + AM(ns+2)*P + Q;
		ZQ = F * E(:,1:ns)' + FS * E(:,ns+1)';
		FS = feval(odefile,t+h,Q,args{:});
		F(:,1) = feval(odefile,t+h*SM(nm),YH,args{:});
		PS = P;
		ZQ = ZQ + FS * E(:,ns+2)' + F(:,1) * E(:,ns+nm)' + P * C';
	end
	%% End of STARTB
	
	%% Solve nonlinear system
	dynold = 0;
	dyno = 1;
	niter = 0;
	while (dyno > uround)
		%% CALL RKNITE
		QQ = Q * ones(1,ns) + ZQ;
		if (canvector)
			F = feval(odefile,t*ones(1,ns) + C',QQ,args{:});
		else
			for i=1:ns
				F(:,i) = feval(odefile,t + C(i),QQ(:,i),args{:});
			end
		end
		dyno = 0;
		NewZQ = P * C' + F * AA';
		dyno = sqrt(sum(sum(((ZQ - NewZQ)./max(0.1,abs(Q)*ones(1,ns))).^2)) / (ns*neq));
		ZQ = NewZQ;
		%% END RKNITE
		niter = niter + 1;
		if (dynold < dyno) & (dyno < 10*uround)
			break;
		end
		if (niter > maxiter)
			if (dyno < 1e5*uround)
 				msg = sprintf('Convergence of Gauss-Newton failed after %d iterations.\nObtained error = %0.5g, continuing anyway...',maxiter,dyno);
				warning(msg);
				break;
			else
 				msg = sprintf('Convergence of Gauss-Newton failed after %d iterations.\nObtained error = %0.5g, stopping here.',maxiter,dyno);
				error(msg);
			end
		end
		dynold = dyno;
	end
	%% System solved
	
  % LOOP FOR ADVANCING ONE STEP.
  nstps = nstps + 1;                  % stats
	
	steppos = steppos+1;
	t = t0+steppos*h;
	
	AY = Q;
	EQ = EQ + h*P + F*BC;
	Q = AY + EQ;
	EQ = EQ + (AY - Q);
	
	AY = P;
	EP = EP + F*B;
	P = AY + EP;
	EP = EP + (AY - P);
	  
  if nargout > 0
    if outflag == 1 & addpoint
      nout = nout + 1;
      if nout > length(tout)
        tout = [tout; zeros(chunk,1)];
        pout = [pout; zeros(chunk,neq)];
        qout = [qout; zeros(chunk,neq)];
			end
   		tout(nout) = t;
			qout(nout,:) = Q.';
			pout(nout,:) = P.';
		end

    if haveoutfun & addpoint
  		PQ = [Q;P];
      if feval(outfun,t,PQ(outputs),'') == 1
        return;
			end
    end
    
  elseif haveoutfun & addpoint
  	PQ = [Q;P];
		if feval(outfun,t,PQ(outputs),'') == 1
    	return;
		end
	end

	if locateevents
 	  V = feval(odefile,t,[Q;P],'events',varargin{:});
		[nteo,nieo,nqeo,npeo,stop] = gnievents(odefile,VOld,V,POld,P,QOld,Q,[t-h,t],direction,terminal,varargin{:});
		teout = [teout;nteo];
		ieout = [ieout;nieo];
		qeout = [qeout;nqeo];
		peout = [peout;npeo];
		if stop
			term = true;
			break;
		end
	end
end

if (nargout > 0 & outflag == 0)
  nout = nout + 1;
  if nout > length(tout)
    tout = [tout; zeros(1,1)];
    pout = [pout; zeros(1,neq)];
    qout = [qout; zeros(1,neq)];
	end
	tout(nout) = t;
	qout(nout,:) = Q.';
	pout(nout,:) = P.';
end	

if haveoutfun
  feval(outfun,[],[],'done');
end

if nargout > 0
  tout = tout(1:nout);
  pout = pout(1:nout,:);
  qout = qout(1:nout,:);
end
