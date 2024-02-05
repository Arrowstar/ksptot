function [Problem,fun,grd,optsao,TR,userxarg] = saocrkargin( varargin )
% Crack input argument list for SAO function slp_trust and sqp_trust
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:        11/9/19
%  Last modified: 10/11/20
%
%--Modifcations
%  2/12/20 - Algorithm to determine MPEA and QMEA fields
%  5/24/20 - PlotFcns
%   6/7/20 - psd
%  7/20/20 - TypicalX (for 'center' in trust_region.m)
% 10/11/20 - optimset for empty optsao
%
numarg = length( varargin );
userxarg = {};
if numarg==1 % Problem structure argument input
   Problem = varargin{1};
   if isstruct(Problem)
      x0   = Problem.x0;
      if isfield(Problem,'options')
         options=Problem.options;
      else
         options=[];
      end
      if isfield(Problem,'lb'),     vlb = Problem.lb;      else vlb=[];end
      if isfield(Problem,'ub'),     vub = Problem.ub;      else vub=[];end
      if isfield(Problem,'nonlcon'),Con  = Problem.nonlcon;else Con=[];end
      if isfield(Problem,'Aineq'),  A    = Problem.Aineq;  else A=[];  end
      if isfield(Problem,'bineq'),  b    = Problem.bineq;  else b=[];  end
      if isfield(Problem,'Aeq'),    Aeq  = Problem.Aeq;    else Aeq=[];end
      if isfield(Problem,'beq'),    beq  = Problem.beq;    else beq=[];end
      if isfield(Problem,'objective')
         Obj  = Problem.objective;
         fun = @(x) fun2(x,Obj,Con);
         grd = @(x) grd2(x,Obj,Con);
      elseif isfield(Problem,'fun')
         fun  = Problem.fun;
         if isfield(Problem,'grd')
            grd = Problem.grd;
         else
            grd=[];
         end
      else
         error('saocrkargin:Obj','Funcion for Objective not defined')
      end
   else
      error('saocrkargin:notstruc',...
         'Single input must be fmincon problem data structure')
   end
else % numarg>1: positional input arguments
   fun = varargin{1};
   x0  = varargin{2};
   if numarg<3, options=[]; else options=varargin{3}; end %#ok<*SEPEX>
   if numarg<4, vlb=[];     else vlb =   varargin{4}; end
   if numarg<5, vub=[];     else vub =   varargin{5}; end
   if numarg<6, grd=[];     else grd =   varargin{6}; end
   if numarg<7, A  =[];     else A   =   varargin{7}; end
   if numarg<8, b  =[];     else b   =   varargin{8}; end
   if numarg<9, Aeq=[];     else Aeq =   varargin{9}; end
   if numarg<10,beq=[];     else beq =   varargin{10}; end
   if numarg>10 % user extra arguments to pass to fcn and grd
      userxarg = varargin{11:numarg};
   end
   Problem = struct('x0',x0,'options',options);
end
Problem.X0 = x0; % Preserve user x0 even if a matrix

%% Process options
% Standard optim toolbox options
if  isempty(options)
   optsao = optimset(optimset('fmincon'),'Display','iter');
elseif isstruct(options)
   if isempty(options)
      optsao = optimset('fmincon');
   else
      optsao = options;
   end
elseif isa(options,'optim.optsao.Fmincon')
   warning('off','MATLAB:structOnObject');
   optsao = struct(options);
   optsao.TolFun = optsao.OptimalityTolerance;
   optsao.TolOpt = optsao.OptimalityTolerance;
   optsao.TolCon = optsao.ConstraintTolerance;
   optsao.TolX   = optsao.ConstraintTolerance;
elseif isreal(options)
   opts = foptions(options);
   optsao = optimset('fmincon');
   switch opts(1)
      case 0
         optsao.Display = 'off';
      case 1
         optsao.Display = 'final';
      otherwise
         optsao.Display = 'iter';
   end
   optsao = optimset( optsao, 'TolX',          opts(2) );
   optsao = optimset( optsao, 'TolFun',        opts(3) );
   optsao = optimset( optsao, 'TolCon',        opts(4) );
   optsao = optimset( optsao, 'MaxFunEvals',   opts(14) );
   optsao = optimset( optsao, 'DiffMinChange', opts(16) );
   optsao = optimset( optsao, 'DiffMaxChange', opts(17) );
   if opts(9)==1      
      optsao = optimset( optsao, 'DerivativeCheck', 'on' );
   end
else
   error('slp_trust:optsao','options is not viable structure')
end
if isfield(options,'PlotFcns') && ~isempty(options.PlotFcns)
   if isOctave
      optsao.PlotFcns = options.PlotFcns;
   else
      optsao.PlotFcns = createCellArrayOfFunctions(options.PlotFcns,'PlotFcns');
   end
end

%% Set missing options
if ~isfield(optsao,'TolFun') || isempty(optsao.TolFun)
   optsao.TolFun = optimget(optimset('fmincon'),'TolFun');
end
if ~isfield(optsao,'MaxIter') || isempty(optsao.MaxIter)
   optsao.MaxIter = 50*length(x0);
end
if ~isfield(optsao,'MaxFunEvals') || isempty(optsao.MaxFunEvals)
   optsao.MaxFunEvals = optimget(optimset('fmincon'),'MaxFunEvals');
end
if ~isfield(optsao,'HessFun') &&  isfield(optsao,'HessianFcn') ...
                              && ~isempty(optsao.HessianFcn)
   optsao.HessFun = optsao.HessianFcn; % used in sqp
end
if ~isfield(optsao,'HessianFcn') &&  isfield(optsao,'HessFun') ...
                                 && ~isempty(optsao.HessFun)
   % sao_trust passes lambda structure instead of real vector
   HessFun = @(x,lm) optsao.HessFun( x, [lm.eqnonlin(:); ...
                                         lm.ineqnonlin(:)] );
   optsao.HessianFcn = HessFun; % use sqp HessFun for s*p_trust
end
if isOctave
   if ~isfield(optsao,'TolCon') || isempty(optsao.TolCon)
      optsao.TolCon = optimget(optimset('fmincon'),'TolFun');
   end
   if ~isfield(optsao,'DiffMinChange') || isempty(optsao.DiffMinChange)
      optsao.DiffMinChange = 1e-8;
   end
   if ~isfield(optsao,'DiffMaxChange') || isempty(optsao.DiffMaxChange)
      optsao.DiffMaxChange = 1e-8;
   end
else
   if ~isfield(optsao,'TolCon') || isempty(optsao.TolCon)
      optsao.TolCon = optimget(optimset('fmincon'),'TolCon');
   end
   if ~isfield(optsao,'DiffMinChange') || isempty(optsao.DiffMinChange)
      optsao.DiffMinChange = optimget(optimset('fmincon'),'DiffMinChange');
   end
   if ~isfield(optsao,'DiffMaxChange') || isempty(optsao.DiffMaxChange)
      optsao.DiffMaxChange = optimget(optimset('fmincon'),'DiffMaxChange');
   end
end
if ~isfield(optsao,'TolX') || isempty(optsao.TolX)
   optsao.TolX=optsao.TolCon;
end

%% Supplemental optsao for slp_trust & sqp_trust
if ~isfield(optsao,'TolOpt') || isempty(optsao.TolOpt)
   if isfield(options,'OptimalityTolerance')
      optsao.TolOpt = options.OptimalityTolerance;
   else
      optsao.TolOpt = optsao.TolFun / min(1,optsao.TolX);
   end
end
if isfield(options,'ComplexStep') && strcmpi(options.ComplexStep,'on')
   optsao.FinDiffType = 'complex';
elseif ~isfield(options,'FinDiffType')
   optsao.FinDiffType = [];
end
if isOctave % tolerance for active DV
   optsao.Tolvb = 1e-6;
else
   optsao.Tolvb  = optimget(optimset('fmincon'),'TolCon');
end
optsao.debug = isfield(optsao,'Debug') && ~strcmpi(optsao.Debug,'off') ...
             ||isfield(optsao,'debug') && ~strcmpi(optsao.debug,'off');
if ~isfield(optsao,'cutg')   || isempty(optsao.cutg),   optsao.cutg=0.1; end
if ~isfield(optsao,'manyDV') || isempty(optsao.manyDV), optsao.manyDV=50; end
if ~isfield(optsao,'manyCon')|| isempty(optsao.manyCon),optsao.manyCon=50;end

%% Check lower and upper bounds: vlb and vub
ndv = length(x0(:)); % number of design variables
[x0,vlb,vub,msg] = checkbounds(x0,vlb,vub,ndv); % Optimization toolbox routine
if ~isempty(msg), error(msg), end
lenvlb=length(vlb); ilb=(1:lenvlb)';
lenvub=length(vub); iub=(1:lenvub)';
if lenvlb && any(x0(ilb)<vlb)
   x0(ilb)=max(x0(ilb),vlb);
   warning('Initial x vector was not within lower bounds.');
   disp('Reset x to '), disp(x0)
end
if lenvub && any(x0(iub)>vub)
   x0(iub)=min(x0(iub),vub);
   warning('Initial x vector was not within upper bounds.');
   disp('Reset x to '), disp(x0)
end

Problem.x0 = x0(:);
Problem.lb = vlb(:);
Problem.ub = vub(:);
if ~isfield(Problem,'Aineq'), Problem.Aineq = A;   end
if ~isfield(Problem,'bineq'), Problem.bineq = b;   end
if ~isfield(Problem,'Aeq'),   Problem.Aeq   = Aeq; end
if ~isfield(Problem,'beq'),   Problem.beq   = beq; end

%% Process TR inputs and options
TR = struct('TolCon',optsao.TolCon,'TolFun',optsao.TolFun,...
            'TolOpt',optsao.TolOpt,'TolX',  optsao.TolX,...
            'Tolvb', optsao.Tolvb, 'manyDV',optsao.manyDV,...
            'Problem',Problem,     'debug', optsao.debug);
if isfield(optsao,'Algorithm') && ~isempty(optsao.Algorithm)
   switch upper(optsao.Algorithm)
      case 'MPEA'
         TR.MPEA='on';
         TR.QMEA='off';
      case 'QMA'
         TR.MPEA='off';
         TR.QMEA='on';
      case 'QMEA'
         TR.MPEA='on';
         TR.QMEA='on';
      case {'SLP','SLP_TRUST'}
         TR.MPEA='off';
         TR.QMEA='off';
   end
end
if isfield(optsao,'MPEA')
   TR.MPEA=optsao.MPEA;
elseif ~isfield(TR,'MPEA') || isempty(TR.MPEA)
   TR.MPEA='off';
end
if isfield(optsao,'QMEA')
   TR.QMEA=optsao.QMEA;
end
if isfield(optsao,'psd') && ~isempty(optsao.psd)
   if ischar(optsao.psd)
      TR.psd = strcmpi(optsao.psd,'on');
   else
      TR.psd = false;
   end
else
   TR.psd = false;
end
if isfield(optsao,'TypicalX')
   TR.TypicalX=optsao.TypicalX;
end
if optsao.debug
   stack = dbstack;
   TR.dbgfid = fopen( strcat(stack(end).name,'_', ...
                     num2str(stack(end).line),'_debug.txt'), 'wt' );
end
if isfield(options,'TrustRegion')
   TR.TrustRegion=options.TrustRegion; 
else
   TR.TrustRegion='on';
end
TR.trust = ~strcmpi(TR.TrustRegion,'off');
TR.adapt = strncmpi(TR.TrustRegion,'TRAM',4) && exist('trust_adapt','file');
TR.SimpleTrust = contains(lower(TR.TrustRegion),'simple');
TR_list = {'Reject','MoveLimit','Contract','Expand','MoveExpand','MoveRelative'};
TR_value= { 0.10,    0.20,       0.20,      0.75,    2.0,        'off' };
for n=1:length(TR_list)
   TR = TR_default( TR, options, TR_list{n}, TR_value{n} );
end
   function TR = TR_default( TR, options, field, default )
      if ~isfield(options,field) || isempty(getfield(options,field))
         TR = setfield(TR, field, default);
      else
         TR = setfield(TR, field, getfield(options,field)); %#ok<*SFLD,*GFLD>
      end
   end
if isfield(options,'MoveContract')
   TR.MoveContract = options.MoveContract;
elseif isfield(options,'MoveReduce') % backward compatibility
   TR.MoveContract = options.MoveReduce;
elseif isfield(options,'MoveReduction')
   TR.MoveContract = options.MoveReduction;
elseif TR.trust
   TR.MoveContract = 0.5;
else
   TR.MoveContract = 0.9;
end

end



%% Sub-function to transform user's fmincon function evauluation functions
   function [f,g,h] = fun2(x,Obj,Con)
      f   = Obj(x);
      if isempty(Con)
         g = [];
         h = [];
      else
         [g,h] = Con(x);
      end
   end



%% Sub-function to transform user's fmincon gradient evauluation functions
   function [gradf,gradg,gradh] = grd2(x,Obj,Con)
      if isempty(Con)
         gradg = [];
         gradh = [];
      else
         [~,gradf] = Obj(x);
         [~,~,gradg,gradh] = Con(x);
      end
   end