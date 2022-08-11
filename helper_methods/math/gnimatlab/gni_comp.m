function [tout,qout,pout,teout,qeout,peout,ieout] = gni_comp(odefile,tspan,y0,options,varargin)
%GNI_COMP  Solves ordinary differential equations with a composition method.
%   The calling sequence is identical to GNI_IRK2, see HELP GNI_IRK2 for details.
%
%   The standard call uses a Stoermer/Verlet scheme and applies to second order
%   differential equations, but the basic mathod can be changed with the
%   'PartialFlow' option, so that general problems can be solved.
%
%   Details are to be found in the article "GniCodes - Matlab Programs for Geometric
%   Numerical Integration", available from http://www.unige.ch/math/folks/hairer/
%   under item software
%
%   Copyright by Ernst Hairer and Martin Hairer, 10.10.2002.

true = logical(1);
false = ~true;

nsteps = 0;                             % stats
nfailed = 0;                            % stats
nfevals = 0;                            % stats
npds = 0;                               % stats
ndecomps = 0;                           % stats
nsolves = 0;                            % stats

if nargin == 0
  error('Not enough input arguments.  See GNI_COMP.');
elseif ~isstr(odefile) & ~isa(odefile, 'inline')
  error('First argument must be a single-quoted string.  See GNI_COMP.');
end

if nargin == 1
  tspan = []; y0 = []; options = [];
elseif nargin == 2
  y0 = []; options = [];
elseif nargin == 3
  options = [];
elseif ~isempty(options) & ~isa(options,'struct')
  if (length(tspan) == 1) & (length(y0) == 1) & (min(size(options)) == 1)
    msg = sprintf('Use gni_comp(''%s'',tspan,y0,...) instead.',odefile);
    error(['Obsolete syntax.  ' msg]);
  else
    error('Correct syntax is gni_comp(''odefile'',tspan,y0,options).');
  end
end

if isstr(odefile) & (exist(odefile) == 4) % a SIMULINK model
	error('Use the SIM command directly for SIMULINK models.');
	return;
end

% Get default tspan and y0 from odefile if none are specified.
if isempty(tspan) | isempty(y0)
  if (nargout(odefile) < 3) & (nargout(odefile) ~= -1)
    msg = sprintf('Use gni_comp(''%s'',tspan,y0,...) instead.',odefile);
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

locateevents = strcmp(gniget(options,'Events','off'),'on');
teout = [];
qeout = [];
peout = [];
ieout = [];
if locateevents
	[V,terminal,direction] = feval(odefile,t,[Q;P],'events',varargin{:});
end

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

% Initialize the output function.
if haveoutfun
	QP = [Q;P];
  feval(outfun,[t tfinal],QP(outputs),'init');
end

% Initialize the IRK method

basic = gniget(options,'PartialFlow','stverl');

if isempty(varargin)
	args = {};
else
	args = [{[]} varargin];
end
feval(basic,t,0,0,odefile,0,0,0,false,false,'init',args{:});

method = gniget(options,'Method','817');
gamma = coeff_comp(method);
ng = size(gamma);
ng = max(ng);

% THE MAIN LOOP

done = false;
outpoint = false;
addpoint = false;

HG = h*gamma;
HA = HG(1) / 2;
HGP = (HG(1:(ng-1)) + HG(2:ng))/2;
HC = HG(ng) / 2;
HGP = [HA;HGP;HC];

HFL = HA + HC;

steppos = 0;

first = true;
last = false;

nsteps = round((tfinal - t0)/h);
for iter = 1:nsteps
	tnew = t+h;
	
	addpoint = false;
	outpoint = outpoint + 1;
	if (outpoint >= outstep)
		outpoint = 0;
		addpoint = true;
	end
	if locateevents
		QOld = Q;
		POld = P;
 		VOld = V;
	end
	
% Start of actual step ynew = y + h*...
	
	for i = 1:(ng-1)
		[P,Q] = feval(basic,t,P,Q,odefile,HGP(i),HG(i),HGP(i+1),first,last,[],args{:});
		first = false;
	end
	if (haveoutfun | addpoint | locateevents)
		last = true;
		[P,Q] = feval(basic,t,P,Q,odefile,HGP(ng),HG(ng),HGP(ng+1),first,last,[],args{:});
		first = true;
		last = false;
	else
		if done
			last = true;
			[P,Q] = feval(basic,t,P,Q,odefile,HGP(ng),HG(ng),HGP(ng+1),first,last,[],args{:});
		else	
			[P,Q] = feval(basic,t,P,Q,odefile,HGP(ng),HG(ng),HFL,first,last,[],args{:});
			first = false;
		end
	end
		
	steppos = steppos+1;
	t = t0+steppos*h;
	
  if nargout > 0
    if addpoint & outflag == 1
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
			QP = [Q;P];
      if feval(outfun,t,QP(outputs),'') == 1
        return;
			end
    end
    
  elseif haveoutfun & addpoint
		QP = [Q;P];
		if feval(outfun,t,QP(outputs),'') == 1
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
  
  % If there were no failures compute a new h.
  % Advance the integration one step.
end

feval(basic,t,0,0,odefile,0,0,0,false,false,'done',args{:});

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
  qout = qout(1:nout,:);
  pout = pout(1:nout,:);
end
