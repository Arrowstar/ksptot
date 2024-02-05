function [opts,v,H,ComplexStep] = sqpcrkopts( options, numberofvariables )
% Cracks optimization options - converts optimset structure options to old foptions vector.
% Also sets default Lagrange multipliers, v, and Hessian, H if present in structure.
%
%  Modified
%  11/4/19 - Octave-compatible code from Blake van Winkle
%   6/4/20 - ComplexStep if options(9)<0
% 10/10/20 - Display='debug'
%
opts=foptions;
v=[];
H=[];
if isstruct(options)
   % Extract non-Optimization Toolbox options first
   ComplexStep=isfield(options,'ComplexStep') && ~isempty(options.ComplexStep) ...
            && strcmpi(options.ComplexStep,'on');
   if isfield(options,'LagrangeMultipliers'), v=options.LagrangeMultipliers; end
   if isfield(options,'HessMatrix'), H=options.HessMatrix; end
   if isfield(options,'foptions')
      opts=foptions(options.foptions);
   else
      if isOctave
         Options=optimset('fminsearch');
%        Display = notify
%        FunValCheck = off
%        MaxFunEvals =  400
%        MaxIter =  400
%        OutputFcn = [](0x0)
%        TolFun =  0.00000010000
%        TolX =  0.00010000
      else
         Options=optimset(optimset('fmincon'),options);
         opts(4)=optimget(Options,'TolCon');
         opts(9)=strcmpi(optimget(Options,'DerivativeCheck'),'on');
         opts(16)=optimget(Options,'DiffMinChange');
         opts(17)=optimget(Options,'DiffMaxChange');
      end
      if ~isfield(options,'Display') || isempty(options.Display)
         options.Display = Options.Display;
      end
      TolX = optimget(Options,'TolX');
      if ~isempty(TolX)
         opts(2)=TolX;
      end
      opts(3) = optimget(Options,'TolFun');
      MaxFun  = optimget(Options,'MaxFunEvals');
      if ischar(MaxFun)
         opts(14)=eval(MaxFun);
      elseif  ~isempty(MaxFun)
         opts(14)=MaxFun;
      end
      MaxIter = optimget(Options,'MaxIter');
      if ischar(MaxIter)
         opts(15)=eval(MaxIter);
      elseif  ~isempty(MaxIter)
         opts(15)=MaxIter;
      end
      opts=foptions(opts);
   end
   switch options.Display
      case 'off'
         opts(1)=0;
      case 'final'
         opts(1)=1;
      case 'iter'
         opts(1)=2;
      case 'Iter'
         opts(1)=3;
      case 'debug'
         opts(1)=4;
      otherwise
         opts(1)=1;
   end
   if isfield(options,'TolX') && ~isempty(options.TolX)
      opts(2)=options.TolX;
   end
   if isfield(options,'TolFun') && ~isempty(options.TolFun)
      opts(3)=options.TolFun;
   elseif isfield(options,'TolOpt') && ~isempty(options.TolOpt)
      opts(3)=options.TolOpt;
   end
   if isfield(options,'TolCon') && ~isempty(options.TolCon)
      opts(4)=options.TolCon;
   end
   if isfield(options,'Scale'),       opts(5)=options.Scale; end
   if isfield(options,'Termination'), opts(6)=options.Termination; end
   if isfield(options,'MaxLineSearchFun')  && ~isempty(options.MaxLineSearchFun)
      opts(7)=options.MaxLineSearchFun;
   end
   if isfield(options,'DerivativeCheck')
      opts(9)=strcmpi(options.DerivativeCheck,'on');
   end
   if isfield(options,'nec') && ~isempty(options.nec)
      opts(13)=options.nec;
   end
   if isfield(options,'MaxFunEvals')
      if ischar(options.MaxFunEvals)
         opts(14)=eval(options.MaxFunEvals);
      elseif ~isempty(options.MaxFunEvals)
         opts(14)=options.MaxFunEvals;
      end
   end
   if isfield(options,'MaxIter')
      if ischar(options.MaxIter)
         opts(15)=eval(options.MaxIter);
      elseif ~isempty(options.MaxIter)
         opts(15)=options.MaxIter;
      end
   end
   if isfield(options,'DiffMinChange') && ~isempty(options.DiffMinChange)
      opts(16)=options.DiffMinChange;
   end
   if isfield(options,'DiffMaxChange') && ~isempty(options.DiffMaxChange)
      opts(17)=options.DiffMaxChange;
   end
else
   opts=foptions(options);
   ComplexStep = opts(9)<0;
end
if opts(14)==0; opts(14)=100*min(10,numberofvariables); end
if opts(15)==0; opts(15)=10*numberofvariables; end
end
