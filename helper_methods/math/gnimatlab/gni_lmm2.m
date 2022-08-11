function [tout,qout,pout,teout,qeout,peout,ieout] = gni_lmm2(odefile,tspan,y0,options,varargin)
%GNI_LMM2  Solves second-order differential equations with a multistep method.
%   The calling sequence is identical to GNI_IRK2, see HELP GNI_IRK2 for details.
%
%   Details are to be found in the article "GniCodes - Matlab Programs for Geometric
%   Numerical Integration", available from http://www.unige.ch/math/folks/hairer/
%   under item software
%
%   Copyright by Ernst Hairer and Martin Hairer, 10.10.2002.

true = logical(1);
false = ~true;

if nargin == 0
  error('Not enough input arguments.  See GNI_LMM2.');
elseif ~isstr(odefile) & ~isa(odefile, 'inline')
  error('First argument must be a single-quoted string.  See GNI_LMM2.');
end

if nargin == 1
  tspan = []; y0 = []; options = [];
elseif nargin == 2
  y0 = []; options = [];
elseif nargin == 3
  options = [];
elseif ~isempty(options) & ~isa(options,'struct')
  if (length(tspan) == 1) & (length(y0) == 1) & (min(size(options)) == 1)
    msg = sprintf('Use gni_lmm2(''%s'',tspan,y0,...) instead.',odefile);
    error(['Obsolete syntax.  ' msg]);
  else
    error('Correct syntax is gni_lmm2(''odefile'',tspan,y0,options).');
  end
end

if isstr(odefile) & (exist(odefile) == 4) % a SIMULINK model
	error('Use the SIM command directly for SIMULINK models.');
	return;
end

% Get default tspan and y0 from odefile if none are specified.
if isempty(tspan) | isempty(y0)
  if (nargout(odefile) < 3) & (nargout(odefile) ~= -1)
    msg = sprintf('Use gni_lmm2(''%s'',tspan,y0,...) instead.',odefile);
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
if t0 == tfinal
  error('The final time must be different from the starting time.');
end
tdir = sign(tfinal - t0);

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

% By default, hmax is 1/10 of the interval.

canvector = strcmp(gniget(options,'Vectorized','off'),'on');
locateevents = strcmp(gniget(options,'Events','off'),'on');
teout = [];
qeout = [];
peout = [];
ieout = [];
if locateevents
	[V,terminal,direction] = feval(odefile,t,[Q;P],'events',varargin{:});
end

method = gniget(options,'Method','803');

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
	QP = [Q;P];
  feval(outfun,[t tfinal],QP(outputs),'init');
end

% Initialize the IRK method

QE = zeros(neq,10);
KK = 8;

[A,B,C] = coeff_lmm2(method);
B=B*h;
C=C/h;

tdend = t0 + (KK-0.99)*h;
stopit = false;
if (tdend >= tfinal)
	stopit = true;
	tdend = tfinal;
end
myoptions = gniset(options,'OutputFcn',[],'StepSize',h,...
    'OutputSteps',1,'Method','G8');

outpoint = 0;
if locateevents
	[GT,QE,PE,nteout,nqeout,npeout,nieout,term] = gni_irk2(odefile,[t0 tdend],y0,myoptions,varargin{:});
	indices = find(nteout < t0+KK/2*h);
	teout = nteout(indices);
	qeout = nqeout(indices,:);
	peout = npeout(indices,:);
	ieout = nieout(indices);
	if term
		stopit = true;
	end
else
	[GT,QE,PE] = gni_irk2(odefile,[t0 tdend],y0,myoptions,varargin{:});
end
if stopit
	tout = GT;
	qout = QE;
	pout = PE;
  if haveoutfun
		QP = [QE';PE'];
%    feval(outfun,GT,[PE(:,outputs)';QE(:,outputs)'],'');
    feval(outfun,GT,QP(outputs,:),'');
		feval(outfun,[],[],'done');
	end
	return;
end

% Generate output for the single-step method.

outpoint = 0;

t = t0;
KK2 = KK/2;
for position=2:KK2
	addpoint = false;
	outpoint = outpoint + 1;
	t = t+h;
	if (outpoint >= outstep)
		outpoint = 0;
		addpoint = true;
	end
	
	if nargout > 0
  	if outflag == 1 & addpoint
	    nout = nout + 1;
	    if nout > length(tout)
	      tout = [tout; zeros(chunk,1)];
	      qout = [qout; zeros(chunk,neq)];
	      pout = [pout; zeros(chunk,neq)];
			end
	 		tout(nout) = t;
			qout(nout,:) = QE(position,:);
			pout(nout,:) = PE(position,:);
		end
	  if haveoutfun & addpoint
			QP = [QE(position,:)';PE(position,:)'];
	    if feval(outfun,t,QP(outputs),'') == 1
  			feval(outfun,[],[],'done');
	      return;
			end
	  end
	elseif haveoutfun & addpoint
		QP = [QE(position,:)';PE(position,:)'];
		if feval(outfun,t,QP(outputs),'') == 1
  		feval(outfun,[],[],'done');
			return;
		end
	end
end

if locateevents
	Q = QE(KK2+1,:)';
	P = PE(KK2+1,:)';
  V = feval(odefile,t0+KK2*h,[Q;P],'events',varargin{:});
end

QE = QE';

Z = (QE(:,2:KK) - QE(:,1:(KK-1)))/h;
Z = [Z,zeros(neq,1)];
QE = [QE,zeros(neq,1)];
F = zeros(neq,KK-1);
if (canvector)
	F = feval(odefile,t0+(1:(KK-1))*h,QE(:,2:KK),args{:});
else
	for i=1:(KK-1)
		F(:,i) = feval(odefile,t0+i*h,QE(:,i+1),args{:});
	end
end
steppos = KK;
t = t0 + steppos*h;
U = (Z(:,1:KK2) + Z(:,(KK-1):-1:KK2))*A;

% THE MAIN LOOP

done = false;
addpoint = false;
nsteps = round((tfinal - t0)/h)-KK2+1;
for iter = 1:nsteps
	if locateevents
		QOld = Q;
		POld = P;
 		VOld = V;
	end

	tnew = t+h;
	
	addpoint = false;
	outpoint = outpoint + 1;
	if (outpoint >= outstep)
		outpoint = 0;
		addpoint = true;
	end
	% Start of actual step ynew = y + h*...
  	
	
	F(:,KK-1) = feval(odefile,t,QE(:,KK),args{:});
	U = U + (F(:,1:KK2) + F(:,(KK-1):-1:KK2))*B;
	Z(:,KK) = zeros(neq,1);
	SUM = (Z(:,2:(KK2+1)) + Z(:,KK:-1:(KK2+1)))*A;
	Z(:,KK) = U - SUM;
	QE(:,KK+1) = QE(:,KK)+h*Z(:,KK);
	
	Q = QE(:,KK2+1);
	P = (QE(:,(KK2+2):(KK+1)) - QE(:,KK2:-1:1))*C;
	
	F(:,1:(KK-2)) = F(:,2:(KK-1));
	Z(:,2:(KK-1)) = Z(:,3:KK);
	QE(:,1:KK) = QE(:,2:(KK+1));
	
  % LOOP FOR ADVANCING ONE STEP.
  if nargout > 0 & outflag == 1
    if addpoint
      nout = nout + 1;
      if nout > length(tout)
        tout = [tout; zeros(chunk,1)];
        qout = [qout; zeros(chunk,neq)];
        pout = [pout; zeros(chunk,neq)];
			end
   		tout(nout) = t-KK2*h;
			qout(nout,:) = Q.';
			pout(nout,:) = P.';
		end

    if haveoutfun & addpoint
    	QP = [Q;P];
      if feval(outfun,t-KK2*h,QP(outputs),'') == 1
        done = true;
			end
    end
    
  elseif haveoutfun & addpoint
    QP = [Q;P];
		if feval(outfun,t-KK2*h,QP(outputs),'') == 1
       done = true;
		end
	end
		
	if locateevents
 	  V = feval(odefile,t-KK2*h,[Q;P],'events',varargin{:});
		[nteo,nieo,nqeo,npeo,stop] = gnievents(odefile,VOld,V,POld,P,QOld,Q,[t-(KK2+1)*h,t-KK2*h],direction,terminal,varargin{:});
		teout = [teout;nteo];
		ieout = [ieout;nieo];
		qeout = [qeout;nqeo];
		peout = [peout;npeo];
		if stop
			break;
		end
	end
	
	steppos = steppos+1;	
	t = t0+steppos*h;
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
  qout = qout(1:nout,:);
  pout = pout(1:nout,:);
end
