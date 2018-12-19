function [varargout] = dop853(OdeFcn,tspan,y0,options,varargin)
%
%     Numerical solution of a non-stiff system of first order ordinary 
%     differential equations:
%     This is an explicit Runge-Kutta method of order (8)5,3 due to
%     Dormand & Prince (with step size control and dens output).
%
%
%     AUTHORS: E. HAIRER AND G. WANNER
%              UNIVERSITE DE GENEVE, DEPT. DE MATHEMATIQUES
%              CH-1211 GENEVE 24, SWITZERLAND 
%              E-MAIL:  Ernst.Hairer@math.unige.ch
%                       Gerhard.Wanner@math.unige.ch
%     THIS CODE IS DESCRIBED IN:
%         E. HAIRER, S.P. NORSETT AND G. WANNER, SOLVING ORDINARY
%         DIFFERENTIAL EQUATIONS I. NONSTIFF PROBLEMS. 2ND EDITION.
%         SPRINGER SERIES IN COMPUTATIONAL MATHEMATICS,
%         SPRINGER-VERLAG (1993)       
%
%     Matlab version:
%     Denis Bichsel
%     Rue des Deurres 58
%     2000 Neuchâtel
%     Suisse
%     dbichsel@infomaniak.ch
%     Version end of 2015
%
% Case 1)
%    dop853(OdeFcn,tspan,y0) or
%    dop853(OdeFcn,tspan,y0,options) 
%    dop853(OdeFcn,tspan,y0,options,Parameters)
%    solve the system of first order differential equations 
%    y' = OdeFcn(t,y) 
%  Input:
%    tspan, a vector with 2 or more components. The components must be
%    monotonic ordered.
%    If tspan is a two components vector, the output value are only
%    returned at the calculated points if 'Refine' is <= 1. If refine is
%    bigger than 1, say 10, 9 more values are interpolated between two
%    succesive evaluated points.
%    If length(tspan) > 2, dop853 returns the solutions at these t-values
%    only.
%    y0, the initial condition must be a column vector.
%    Options overwrite the default integration parameters (see rdpset).
%    Parameters may be passed to OdeFcn, to MassFcn, and to EventsFcn.
%  Output:
%    In this cas, the default output is odeplot. The option 'outputFcn' may
%    overwrite the default and, for exmaple, write the results in a file.
%   
% Case 2)
%    [tout,yout] = dop853(OdeFcn,tspan,y0) or
%    [tout,yout] = dop853(OdeFcn,tspan,y0,options) 
%    [tout,yout] = dop853(OdeFcn,tspan,y0,options,Parameters)
%  Input:
%    Same as case 1).
%  Output:
%   The solution is returned in [tout,yout].
%  
% Case 3)
%    [tout,yout,Stats] = dop853(OdeFcn,tspan,y0) or
%    [tout,yout,Stats] = dop853(OdeFcn,tspan,y0,options) 
%    [tout,yout,Stats] = dop853(OdeFcn,tspan,y0,options,Parameters)
%  Input:
%    Same as case 1).
%  Output:
%    The solution is returned in [tout,yout].
%    Stats contains some informations on the calculation.
%      Stats.Stat gives the the following global (static) informations. 
%      Stats.Stat.FcnNbr:     The call number to OdeFcn. 
%      Stats.Stat.StepNbr:    The number of main steps. 
%      Stats.Stat.AccptNbr:   The number of accepted steps
%      Stats.Stat.StepRejNbr: The number of rejected steps
%
%    Stats.Dyn gives the following dynamical informations. 
%      Stats.Dyn.haccept_t:      Times of the accepted steps
%      Stats.Dyn.haccepted_Step: Accepted steps' number
%      Stats.Dyn.haccept:        Values of the accepted step sizes
%      Stats.Dyn.hreject_t:      Times of the rejected steps  
%      Stats.Dyn.hreject_Step:   Rejected steps' number
%      Stats.Dyn.hreject:        Rejected steps'value
%
% case 4)
%    The option Events is set, (EventsFcn ~= [] ) and there are five 
%    outputs.     
%    [tout,yout,te,ye,ie] = dop853(OdeFcn,tspan,y0) or
%    [tout,yout,te,ye,ie] = dop853(OdeFcn,tspan,y0,options) 
%    [tout,yout,te,ye,ie] = dop853(OdeFcn,tspan,y0,options,Parameters)
%  Input:
%    Same as case 1).
%  Output:
%    The solution is returned in [tout,yout]. 
%    te is a the t-vector of the events
%    ye contains the value of the evnets
%    ie is the indice of the events function corresponding to te, ye
%
% case 5)
%    The option Events is set, (EventsFcn ~= [] ) and there are five 
%    outputs.     
%    [tout,yout,te,ye,ie,Stats] = dop853(OdeFcn,tspan,y0) or
%    [tout,yout,te,ye,ie,Stats] = dop853(OdeFcn,tspan,y0,options) 
%    [tout,yout,te,ye,ie,Stats] = dop853(OdeFcn,tspan,y0,options,Parameters)
%  Input:
%    Same as case 1).
%  Output: same as case 4) plus Stats as in case 3)
%
% -------------------------------------------------------------------------          
% See DOP54D DOP853 DOP853D RDPGET RDPSET
% ------------------------------------------------------------------------
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS 
% IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR 
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% ------------------------------------------------------------------------  

Solver_Name = 'dop853';

Ny  = length(y0);

% ---------------------------
% Default options values
AbsTolDef           = 1e-6;
RelTolDef           = 1e-3;
InitialStepDef      = 1e-2;                  % WORK(7)
MaxStepDef          = tspan(end) - tspan(1); % WORK(6)
MaxNbrStepDef       = 1e5;                   % IWORK(1)
RefineDef           = 1;
OutputFcnDef        = [];
OutputSelDef        = 1:Ny;
FacLDef             = 1/3;                   % WORK(3)
FacRDef             = 6;                     % WORK(4)
SafeDef             = 0.9;                   % WORK(2)
NormControlDef      = false;
MassFcnDef          = [];
EventsFcnDef        = [];
StiffTestDef        = 1000;                  % IWORK(5)
BetaDef             = 0.00;                  % WORK(5)

OpDefault = {AbsTolDef;       RelTolDef;        InitialStepDef;  ...
             MaxStepDef;      MaxNbrStepDef;    ...
             RefineDef;       OutputFcnDef;     OutputSelDef;    ...
             FacLDef;         FacRDef;          SafeDef;         ...
             NormControlDef;  MassFcnDef;       EventsFcnDef;     ...
             StiffTestDef;    BetaDef}; 

OpNames = ['AbsTol          ';'RelTol          ';'InitialStep     '; ...
           'MaxStep         ';'MaxNbrStep      ';                    ...
           'Refine          ';'OutputFcn       ';'OutputSel       '; ...
           'FacL            ';'FacR            ';'Safe            '; ...
           'NormControl     ';'MassFcn         ';'EventsFcn       ';
           'StiffTest       ';'Beta            ']; ...        
           
% ---------------------------
% Tests on inputs
% ---------------
if (nargin <3 )    %  dopxxxx('odefile',tspan,y0) 
  error ([Solver_Name,': Number of input arguments must be at least equal to 3.']);
end   

% nargin >= 3
if ~isa (OdeFcn, 'function_handle') && ~(exist(OdeFcn,'file') == 2)
  error ([Solver_Name,': First input argument must be a valid function handle or name']);        
end

if (~isvector (tspan) || length (tspan) < 2)
  error ([Solver_Name,': Second input argument must be a valid vector']);
end
% Test of tspan monotony
tspan  = tspan(:);                     % Column vector
PosNeg = sign(tspan(end) - tspan(1));  % Monotony check 
if any(PosNeg*diff(tspan)) <= 0
  error([Solver_Name,': Time vector must be strictly monotonic']);
end

if ~isvector (y0)
  error ([Solver_Name,': Initial conditions argument must be a valid vector or scalar']);
end
y0 = y0(:);           % Column vector

if nargin < 4
  options = [];
end
  
Arg.In = nargin > 4;

% ---------------------------
% Tests on options
% ----------------
Op  = [];
for n = 1:size(OpNames,1)
  Op.(deblank(OpNames(n,:))) =  ...
             rdpget(options,deblank(OpNames(n,:)),OpDefault{n});  
end 

% ------- ABSTOL
if ~isnumeric(Op.AbsTol)
   error([Solver_Name, ': Wrong input "AbsTol must be a positive number" ']) 
end
if any(Op.AbsTol <= 0 )
  error([Solver_Name,': Absolute tolerance are too small.']);
end
if (length(Op.AbsTol) ~= Ny) && (length(Op.AbsTol) ~=1)
  error([Solver_Name, ': AbsTol vector of length 1 or %d.',num2str(Ny)]);
end
Op.AbsTol = Op.AbsTol + zeros(size(y0));
% ------- RELTOL
if ~isnumeric(Op.RelTol)
  error([Solver_Name, ': Wrong input "RelTol" must be a positve number" ']) 
end
if any(Op.RelTol < 10*eps)  
  error([Solver_Name,': Relative tolerance are too small.']);
end
if (length(Op.RelTol) ~= Ny) && (length(Op.RelTol) ~=1)
  error([Solver_Name, ': RelTol vector of length 1 or %d.',num2str(Ny)]);
end
Op.RelTol = Op.RelTol + zeros(size(y0));
% ------- INITIAL STEP SIZE
if ~isnumeric( Op.InitialStep)
  error([Solver_Name, ': Wrong input "InitialStep" must be a number']) 
end 
% ------- MAXIMAL STEP SIZE
if ~isnumeric(Op.MaxStep)
  error([Solver_Name, ': Wrong input "MaxStep" must be a number '])
end
% ------- MAXIMAL NUMBER OF STEPS
if ~isnumeric(Op.MaxNbrStep)
  error([Solver_Name,': Wrong input "MaxNbrStep" must be a positive number']);
elseif Op.MaxNbrStep <= 0
  error([Solver_Name,': Wrong input "MaxNbrStep" ',num2str(Op.MaxNbrStep),', must be > 0'])
end
% ------- REFINE
if ~isempty(Op.Refine)
  if ~isnumeric(Op.Refine)
    error([Solver_Name,': Wrong input "Refine" must empty be or a positive number']);
  end
end
% ------- OUTPUTFCN 
% if ~isempty(Op.OutputFcn)
%   if isa (Op.OutputFcn,'function_handle')
%     Op.OutputFcn = func2str(Op.OutputFcn);
%   end
%   if ~(exist(Op.OutputFcn,'file') == 2)
%     error ([Solver_Name,': OutputFcn must be a valid function handle']);  
%   end  
% end
% ------- OUTPUTSEL  
if ~isempty(Op.OutputSel) 
  if ~isvector (Op.OutputSel)
    error ([Solver_Name,': OutputSel must be a scalar or a vector of positive integer']);  
  end 
  IndComp = 1:1:Ny;
  for n = 1:length(Op.OutputSel)
    if ~ismember(Op.OutputSel(n),IndComp)
      error ([Solver_Name,': OutputSel must be an integer in 1 .. ',num2str(Ny)])
    end
  end    
end
% -------  FACL,FACR     PARAMETERS FOR STEP SIZE SELECTION
if ~isnumeric(Op.FacL)
  error([Solver_Name, ': Wrong input "Facl" must be numeric default 0.2 '])
end
if Op.FacL > 1.0 
   error([Solver_Name, ': Curious input for "FacL" default 0.2 '])
end  
if ~isnumeric(Op.FacR)
  error([Solver_Name, ': Wrong input "FacR" must be numeric default 8 '])  
end
if Op.FacR < 1.0 
   error([Solver_Name, ': Curious input for "FacR" default 8 '])
end  
% --------- SAFE SAFETY FACTOR IN STEP SIZE PREDICTION   
if ~isnumeric(Op.Safe)
   error([Solver_Name, ': Wrong input "Safe" must be a positive number '])  
elseif Op.Safe <= 0.001 || Op.Safe >= 1 
  error([Solver_Name,': Curious input for Safe,' num2str(Op.Safe),' must be in ]0.001 .. 1[ '])
end
% ------- NORMCONTROL
if(strcmpi(Op.NormControl,'on'))
    Op.NormControl = true;
elseif(strcmpi(Op.NormControl,'off'))
    Op.NormControl = false;
end
if ~islogical(Op.NormControl) 
  error ([Solver_Name,': NormControl must be logical']);
end
% ------- MASS  

% ------- EVENTS  
EventsExist = ~isempty(Op.EventsFcn);
% ------- STIFFTEST
if ~isnumeric(Op.StiffTest)
   error([Solver_Name, ': Wrong input "StiffTest" must be a positive number ']) 
   if Op.StiffTest < 1
     error([Solver_Name, ': Wrong input "StiffTest" must be a positive number '])
   end
end
% ------- BETA
if ~isnumeric(Op.Beta)
   error([Solver_Name, ': Wrong input "Beta" must be a positive number 0 - 0.2']) 
elseif Op.Beta > 0.2
   error([Solver_Name, ': Curious input "Beta" must be a positive number 0 - 0.2']) 
elseif Op.Beta <= 0.0 
  Op.Beta = 0; 
end

% ---------------------------
% Tests on outputs
% ---------------
OutputNbr = abs(nargout());
Op.Stats = false;
if OutputNbr == 0 
  if isempty(Op.OutputFcn)
    Op.OutputFcn = rdpget(options,'OutputFcn','odeplot');   
  end  
elseif OutputNbr == 2
  Op.Stats = false;
elseif OutputNbr == 3  
    Op.Stats = true;
elseif OutputNbr == 5  
  Op.Stats = false;
  if ~EventsExist
    error([Solver_Name,': Events not set, too much output']);
  end
elseif OutputNbr == 6
  Op.Stats = true;
  if ~EventsExist 
    error([Solver_Name,': Events must be set ']);    
  end
else
  error([Solver_Name,': Outputs number not correct']);
end
    
solver853 = {'dop853solver',OdeFcn,tspan,y0,Op};
if Arg.In
  solver853 = [solver853, {varargin{:}}];
end 

switch OutputNbr
  case 0
    feval(solver853{:});
  case 2
    [tout,yout] = feval(solver853{:});
    varargout = {tout,yout};
  case 3
    [tout,yout,Stats] = feval(solver853{:});
    varargout = {tout,yout,Stats};
  case 5
    [tout,yout,teout,yeout,ieout] = feval(solver853{:});
    varargout = {tout,yout,teout,yeout,ieout};
  case 6
    [tout,yout,teout,yeout,ieout,Stats] = feval(solver853{:});
    varargout = {tout,yout,teout,yeout,ieout,Stats};
end
return
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
function [varargout] = dop853solver(OdeFcn,tspan,y,Op,varargin)

Solver_Name = 'dop853solver';

% ------- INPUT PARAMETERS
% Time properties
tspan  = tspan(:);                     % Column vector
ntspan = length(tspan);
t      = tspan(1);
tfinal = tspan(end);
PosNeg = sign(tfinal-t);

% Number of equations, y is a column vector
Ny     = length(y);

% General options
AbsTol      = Op.AbsTol;
RelTol      = Op.RelTol;
h           = Op.InitialStep;         % h may be positive or negative
hmax        = abs(Op.MaxStep);        % hmax is positive
MaxNbrStep  = Op.MaxNbrStep;
Refine      = Op.Refine;
OutputFcn   = Op.OutputFcn;
OutputSel   = Op.OutputSel;
FacL        = 1/Op.FacL;
FacR        = 1/Op.FacR;
Safe        = Op.Safe;                % WORK(2)
NormControl = Op.NormControl;
MassFcn     = Op.MassFcn;
StatsExist  = Op.Stats;
EventsFcn   = Op.EventsFcn;
StiffTest   = Op.StiffTest;
Beta        = Op.Beta;
% Initialisation of Stat parameters
Stat.FcnNbr     = 0;
Stat.StepNbr    = 0;
Stat.StepAccNbr = 0;
Stat.StepRejNbr = 0;

% Initialisation of Dyn parameters
StatsExist = false;
if nargout == 3 || nargout == 6
  StatsExist       = true;
  Dyn.haccept_t    = [];
  Dyn.haccept_Step = [];
  Dyn.haccept      = [];
  Dyn.hreject_t    = [];
  Dyn.hreject_Step = [];
  Dyn.hreject      = [];  
end
% -------  ARGUMENTS
Arg.In = nargin > 4;

% ------- ODEFCN arguments or not
% if isa (OdeFcn, 'function_handle')
%   OdeError  = func2str(OdeFcn);
% else
%   OdeError  = OdeFcn;
% end 
Arg.Ode = abs(nargin(OdeFcn)) > 2;
if Arg.Ode && ~Arg.In
  error([Solver_Name,':  ',OdeError,', parameters are missing'])
end

% ------- MASSFCN arguments or not
MassExist  = false;
MassArgNbr = -1;
if ~isempty(MassFcn) 
%   if isa (MassFcn, 'function_handle')
%     MassError  = func2str(MassFcn);
%   else
%     MassError  = MassFcn;
%   end    
  MassExist  = true;
  MassArgNbr = abs(nargin(MassFcn));
  switch MassArgNbr
    case 0      
      Mass    = MassFcn(); 
      detMass = det(Mass);
      if detMass == 0
        error([Solver_Name,':  Mass is singular '])
      end    
    otherwise
      if MassArgNbr >= 3 && ~Arg.In
        error([Solver_Name,':  ',MassError,', parameters are missing'])
      end     
  end  
end

% Set the output flag and output buffer
if ntspan == 2                                               
  if Refine <= 1                       % Computed points only
    OutFlag = 1;     
    nBuffer = 100;
    nout    = 0;
    tout    = zeros(nBuffer,1);
    yout    = zeros(nBuffer,Ny);                  
  else
    OutFlag = 2; 
    nout    = 0;
    nBuffer = 10*Refine;
    tout    = zeros(nBuffer,1);
    yout    = zeros(nBuffer,Ny);% Computed + refined points   
  end
else  % ntspan > 2
  OutFlag = 3;                         % Computed points  
  nout  = 0;
  nout3 = 0;
  tout  = zeros(ntspan,1);
  yout  = zeros(ntspan,Ny); 
  if Refine > 1
    Refine = 1;
    warning([Solver_Name,': Refine set equal 1, because length(tspan) > 2 '])
  end
end

OutputFcnExist = false;
if ~isempty(OutputFcn) 
  OutputFcnExist = true;   
  % Initialize the OutputFcn
  OutputFcnArg = {OutputFcn,[t tfinal],y(OutputSel),'init'};
  feval(OutputFcnArg{:}); 
end
 
% Initialiation of internal parameters
FacOld = 1e-4;
Expo1  = 1/8 - Beta*0.2;             
hLamb  = 0.0;
IaSti  = 0;
K      = zeros(Ny,12);  % For DOP45 a is a matrix(7,7)
y1     = zeros(Ny,12);
% --------------
% h initialisation
if Arg.Ode
  f0 = feval(OdeFcn,t,y,varargin{:});
else
  f0 = feval(OdeFcn,t,y);
end
if any(isnan(f0))
  error([Solver_Name,':  Function ',OdeError,' Some components of are NaN'])
end
Stat.FcnNbr = Stat.FcnNbr+1;
[m,n] = size(f0);
if n > 1
  error([Solver_Name,':  Function ',OdeError,'(t,y) must return a column vector.'])
elseif m ~= Ny
  error([Solver_Name,':  Vector ',OdeError, '(t,y) must be same length as initial conditions.']);
end
if MassExist                % There is a Mass
  if MassArgNbr > 0
    switch MassArgNbr     
      case 1
        MassFcnArg = {MassFcn,t};
      case 2
        MassFcnArg = {MassFcn,t,y};
      otherwise
        MassFcnArg = {MassFcn,t,y,varargin{:}};
    end
    Mass = feval(MassFcnArg{:}); 
    if any(isnan(Mass))
      error([Solver_Name, ': Some components of Mass are NAN'])       
    end
  end
  K(:,1) = Mass \ f0;
else
  K(:,1) = f0;
end
hmax = min(hmax,abs(tspan(end)-tspan(1)));      % hmax positive

% Events initialisation
EventsExist = false;
if ~isempty(EventsFcn) 
  EventsExist = true;
  if nargin(EventsFcn) == 0
    error([Solver_Name,'  EventsFcn needs input arguments'])
  end 
  teout = [];
  yeout = [];
  ieout = [];
  [teout,yeout,ieout] = EventZeroFcn(EventsFcn,t,h,y,[],f0,'init',varargin{:});
end

if abs(h) <= 10*eps 
  h = hInitFcn(OdeFcn,MassFcn,MassArgNbr,Arg,t,y,PosNeg,hmax,K(:,1),RelTol,AbsTol,varargin{:});
  Stat.FcnNbr = Stat.FcnNbr+1;
end

h = PosNeg * min(abs(h),hmax);               % h sign ok 

Reject = false;

% ---------------------------
% Coefficients values for dop54
% See Hairer Université de Genève
% ---------------------------
% c: time increment coefficients
c     = zeros(1,16); 
c(2)  = 0.526001519587677318785587544488e-1;
c(3)  = 0.789002279381515978178381316732e-1;
c(4)  = 0.118350341907227396726757197510;
c(5)  = 0.281649658092772603273242802490;
c(6)  = 0.333333333333333333333333333333;
c(7)  = 0.25;
c(8)  = 0.307692307692307692307692307692;
c(9)  = 0.651282051282051282051282051282;
c(10) = 0.6;
c(11) = 0.857142857142857142857142857142;
c(12) = 1;
c(13) = 1;
c(14) = 0.1;
c(15) = 0.2;
c(16) = 0.777777777777777777777777777778;
% ---------------------------
% a: slope calculation coefficients 
a        =    zeros(12,12);
a(1,1)   =    5.26001519587677318785587544488e-2;
a(2,1)   =    1.97250569845378994544595329183e-2;
a(2,2)   =    5.91751709536136983633785987549e-2;
a(3,1)   =    2.95875854768068491816892993775e-2;
a(3,3)   =    8.87627564304205475450678981324e-2;
a(4,1)   =    2.41365134159266685502369798665e-1;
a(4,3)   =   -8.84549479328286085344864962717e-1;
a(4,4)   =    9.24834003261792003115737966543e-1;
a(5,1)   =    3.7037037037037037037037037037e-2;
a(5,4)   =    1.70828608729473871279604482173e-1;
a(5,5)   =    1.25467687566822425016691814123e-1;
a(6,1)   =    3.7109375e-2;
a(6,4)   =    1.70252211019544039314978060272e-1;
a(6,5)   =    6.02165389804559606850219397283e-2;
a(6,6)   =   -1.7578125e-2;

a(7,1)   =    3.70920001185047927108779319836e-2;
a(7,4)   =    1.70383925712239993810214054705e-1;
a(7,5)   =    1.07262030446373284651809199168e-1;
a(7,6)   =   -1.53194377486244017527936158236e-2;
a(7,7)   =    8.27378916381402288758473766002e-3;
a(8,1)   =    6.24110958716075717114429577812e-1;
a(8,4)   =   -3.36089262944694129406857109825;
a(8,5)   =   -8.68219346841726006818189891453e-1;
a(8,6)   =    2.75920996994467083049415600797e1;
a(8,7)   =    2.01540675504778934086186788979e1;
a(8,8)   =   -4.34898841810699588477366255144e1;
a(9,1)   =    4.77662536438264365890433908527e-1;
a(9,4)   =   -2.48811461997166764192642586468;
a(9,5)   =   -5.90290826836842996371446475743e-1;
a(9,6)   =    2.12300514481811942347288949897e1;
a(9,7)   =    1.52792336328824235832596922938e1;
a(9,8)   =   -3.32882109689848629194453265587e1;
a(9,9)   =   -2.03312017085086261358222928593e-2;

a(10,1)  =  -9.3714243008598732571704021658e-1;
a(10,4)  =   5.18637242884406370830023853209;
a(10,5)  =   1.09143734899672957818500254654;
a(10,6)  =  -8.14978701074692612513997267357;
a(10,7)  =  -1.85200656599969598641566180701e1;
a(10,8)  =   2.27394870993505042818970056734e1;
a(10,9)  =   2.49360555267965238987089396762;
a(10,10) =  -3.0467644718982195003823669022;
a(11,1)  =   2.27331014751653820792359768449;
a(11,4)  =  -1.05344954667372501984066689879e1;
a(11,5)  =  -2.00087205822486249909675718444;
a(11,6)  =  -1.79589318631187989172765950534e1;
a(11,7)  =   2.79488845294199600508499808837e1;
a(11,8)  =  -2.85899827713502369474065508674;
a(11,9)  =  -8.87285693353062954433549289258;
a(11,10) =   1.23605671757943030647266201528e1;
a(11,11) =   6.43392746015763530355970484046e-1;
% ------------------------------------------
a141 =  5.61675022830479523392909219681e-2;
a147 =  2.53500210216624811088794765333e-1;
a148 = -2.46239037470802489917441475441e-1;
a149 = -1.24191423263816360469010140626e-1;
a1410 =  1.5329179827876569731206322685e-1;
a1411 =  8.20105229563468988491666602057e-3;
a1412 =  7.56789766054569976138603589584e-3;
a1413 = -8.298e-3;

a151  =  3.18346481635021405060768473261e-2;
a156  =  2.83009096723667755288322961402e-2;
a157  =  5.35419883074385676223797384372e-2;
a158  = -5.49237485713909884646569340306e-2;
a1511 = -1.08347328697249322858509316994e-4;
a1512 =  3.82571090835658412954920192323e-4;
a1513 = -3.40465008687404560802977114492e-4;
a1514 =  1.41312443674632500278074618366e-1;
a161  = -4.28896301583791923408573538692e-1;
a166  = -4.69762141536116384314449447206;
a167  =  7.68342119606259904184240953878;
a168  =  4.06898981839711007970213554331;
a169  =  3.56727187455281109270669543021e-1;
a1613 = -1.39902416515901462129418009734e-3;
a1614 =  2.9475147891527723389556272149;
a1615 = -9.15095847217987001081870187138;
% ---------------------------
% Final assembly coefficients
b1  =  5.42937341165687622380535766363e-2;
b6  =  4.45031289275240888144113950566;
b7  =  1.89151789931450038304281599044;
b8  = -5.8012039600105847814672114227;
b9  =  3.1116436695781989440891606237e-1;
b10 = -1.52160949662516078556178806805e-1;
b11 =  2.01365400804030348374776537501e-1;
b12 =  4.47106157277725905176885569043e-2;

bhh1 = 0.244094488188976377952755905512;
bhh2 = 0.733846688281611857341361741547;
bhh3 = 0.220588235294117647058823529412e-1;
% ---------------------------
% Dense output coefficients
d41  = -0.84289382761090128651353491142e+1;
d46  =  0.56671495351937776962531783590;
d47  = -0.30689499459498916912797304727e+1;
d48  =  0.23846676565120698287728149680e+1;
d49  =  0.21170345824450282767155149946e+1;
d410 = -0.87139158377797299206789907490;
d411 =  0.22404374302607882758541771650e+1;
d412 =  0.63157877876946881815570249290;
d413 = -0.88990336451333310820698117400e-1;
d414 =  0.18148505520854727256656404962e+2;
d415 = -0.91946323924783554000451984436e+1;
d416 = -0.44360363875948939664310572000e+1;
d51  =  0.10427508642579134603413151009e+2;
d56  =  0.24228349177525818288430175319e+3;
d57  =  0.16520045171727028198505394887e+3;
d58  = -0.37454675472269020279518312152e+3;
d59  = -0.22113666853125306036270938578e+2;
d510 =  0.77334326684722638389603898808e+1;
d511 = -0.30674084731089398182061213626e+2;
d512 = -0.93321305264302278729567221706e+1;
d513 =  0.15697238121770843886131091075e+2;
d514 = -0.31139403219565177677282850411e+2;
d515 = -0.93529243588444783865713862664e+1;
d516 =  0.35816841486394083752465898540e+2;
d61 =  0.19985053242002433820987653617e+2;
d66 = -0.38703730874935176555105901742e+3;
d67 = -0.18917813819516756882830838328e+3;
d68 =  0.52780815920542364900561016686e+3;
d69 = -0.11573902539959630126141871134e+2;
d610 =  0.68812326946963000169666922661e+1;
d611 = -0.10006050966910838403183860980e+1;
d612 =  0.77771377980534432092869265740;
d613 = -0.27782057523535084065932004339e+1;
d614 = -0.60196695231264120758267380846e+2;
d615 =  0.84320405506677161018159903784e+2;
d616 =  0.11992291136182789328035130030e+2;
d71  = -0.25693933462703749003312586129e+2;
d76  = -0.15418974869023643374053993627e+3;
d77  = -0.23152937917604549567536039109e+3;
d78  =  0.35763911791061412378285349910e+3;
d79  =  0.93405324183624310003907691704e+2;
d710 = -0.37458323136451633156875139351e+2;
d711 =  0.10409964950896230045147246184e+3;
d712 =  0.29840293426660503123344363579e+2;
d713 = -0.43533456590011143754432175058e+2;
d714 =  0.96324553959188282948394950600e+2;
d715 = -0.39177261675615439165231486172e+2;
d716 = -0.14972683625798562581422125276e+3;
% ---------------------------
% Error calculation coefficients
er1  =  0.1312004499419488073250102996e-1;
er6  = -0.1225156446376204440720569753e+1;
er7  = -0.4957589496572501915214079952;
er8  =  0.1664377182454986536961530415e+1;
er9  = -0.3503288487499736816886487290;
er10 =  0.3341791187130174790297318841;
er11 =  0.8192320648511571246570742613e-1;
er12 = -0.2235530786388629525884427845e-1;
% ---------------------------

% ------------
% --- BASIC INTEGRATION STEP  
% ------------

Done = false;

while ~Done 
  % -------------------------
  % THE FIRST 11 STAGES
  % ------------------------- 
  Stat.StepNbr = Stat.StepNbr+1; 
  
  if Stat.StepNbr > MaxNbrStep
    warning([Solver_Name,':  NbrSteps = ',num2str(Stat.StepNbr),' > MaxNbrStep']);
    break
  end
  
  if (0.1*abs(h) <= abs(t)*eps)
    warning([Solver_Name,' : Too small step size']);    
    Done = true;
  end
  
  if  (PosNeg * (t + 1.001*h - tfinal) >= 0 )     
    h = tfinal - t;
  elseif PosNeg * (t + 1.8*h - tfinal) > 0
    h = (tfinal - t)*0.5;
  end
  
  ch = h*c;  
  ah = h*a';     % Needed for matrix calculation  
 
  for j = 1:11 
    time = t + ch(j+1);
    y1   = y+K*ah(:,j);
    OdeFcnArg = {OdeFcn,time,y1};
    if (Arg.Ode)
      OdeFcnArg = [OdeFcnArg,{varargin{:}}];
    end 
    f0 = feval(OdeFcnArg{:});
    if any(isnan(f0))
      error([Solver_Name, ': Some components of f0 = OdeFcn are NAN'])       
    end
    if MassExist                % There is a Mass
      switch MassArgNbr
        % case 0   Mass already known         
        case 1
          MassFcnArg = {MassFcn,time};
        case 2
          MassFcnArg = {MassFcn,time,y1};
        otherwise
          MassFcnArg = {MassFcn,time,y1,varargin{:}};
      end
      if MassArgNbr > 0        % If constant already known         
        Mass = feval(MassFcnArg{:});
        if any(isnan(Mass))
          error([Solver_Name, ': Some components of Mass are NAN'])       
        end
      end
      K(:,j+1) = Mass \ f0; 
    else
      K(:,j+1) = f0;
    end              
  end
  Stat.FcnNbr = Stat.FcnNbr+11;
  
  % K2 in Hairer -->  K(:,11)
  % K3 in Hairer -->  K(:,12)
  K(:,4)      = b1*K(:,1) + b6*K(:,6)+ b7*K(:,7) + b8*K(:,8) + ...
                b9*K(:,9) + b10*K(:,10) + b11*K(:,11) + b12*K(:,12);
  K(:,5)      = y + h*K(:,4);
  tph         = t + h;
  % --- ERROR ESTIMATION   (639)
  if NormControl
    %  norm(e) <= max(RelTol*norm(y),AbsTol)
    Sk = max(AbsTol) + max(RelTol)* max(norm(y),norm(K(:,5)));
  else  
    Sk = AbsTol + RelTol .* max( abs(y),abs(K(:,5))); 
  end
  Err2 = sum( ((K(:,4) - bhh1*K(:,1) - bhh2*K(:,9) - bhh3*K(:,12))./Sk).^2);
  Err  = sum((( er1*K(:,1) + er6*K(:,6) + er7*K(:,7) + er8*K(:,8) + er9*K(:,9) +  ...
                er10*K(:,10) + er11*K(:,11) + er12*K(:,12) ) ./ Sk).^2);
  Deno = Err + 0.01*Err2;  
  if Deno <= 0
    Deno = 1.0;
  end
  Err = abs(h)*Err*sqrt(1/(Ny*Deno));
  
  % --- COMPUTATION OF HNEW -----> 662 Hairer
  Fac11 = Err^Expo1;
  % --- LUND-STABILIZATION
  Fac   =  Fac11/FacOld^Beta; %Fac11;
  % --- WE REQUIRE  FAC1 <= HNEW/H <= FAC2
  Fac   = max(FacR,min(FacL,Fac/Safe));
  hNew  = h/Fac;   
  if(Err < 1.D0)
    % --- STEP IS ACCEPTED        (669 Hairer)    
    Stat.StepAccNbr= Stat.StepAccNbr + 1;
    if StatsExist
      Dyn.haccept_t    = [Dyn.haccept_t,t];
      Dyn.haccept_Step = [Dyn.haccept_Step,Stat.StepNbr];
      Dyn.haccept      = [Dyn.haccept,h];
    end
    FacOld = max(Err,1d-4); 
    OdeFcnArg = {OdeFcn,tph,K(:,5)};
    if (Arg.Ode)
      OdeFcnArg = [OdeFcnArg,{varargin{:}}];
    end 
    f0 = feval(OdeFcnArg{:});  
    if any(isnan(f0))
      error([Solver_Name, ': Some components of f0 = OdeFcn are NAN'])       
    end    
    if MassExist                % There is a Mass
      switch MassArgNbr
        % case 0   Mass already known         
        case 1
          MassFcnArg = {MassFcn,tph};
        case 2
          MassFcnArg = {MassFcn,tph,K(:,5)};
        otherwise
          MassFcnArg = {MassFcn,tph,K(:,5),varargin{:}};
      end
      if MassArgNbr > 0        % If constant already known         
        Mass = feval(MassFcnArg{:});  
        if any(isnan(Mass))
          error([Solver_Name, ': Some components of Mass are NAN'])       
        end
      end
      K(:,4) = Mass \ f0; 
    else
      K(:,4) = f0;
    end    
    Stat.FcnNbr = Stat.FcnNbr + 1;
  
    % ------- STIFFNESS DETECTION                     675
    if mod(Stat.StepAccNbr,StiffTest)== 0 || IaSti > 0   
      StNum = sum( (K(:,4) - K(:,12)).^2 );
      StDen = sum( (K(:,5) - y1(:)).^2 );
      if StDen > 0 
        hLamb = abs(h) * sqrt(StNum/StDen);
      end         
      if hLamb > 6.1      
        StiffTest = 0;
        IaSti    = IaSti + 1;
        if IaSti == 15
          warning([Solver_Name,' The problem seems to become stiff at t = ', num2str(t)]);              
        end
      else
        StiffTest = StiffTest + 1;
        if StiffTest == 6 
          IaSti = 0;
        end
      end
    end    
  
% ------- FINAL PREPARATION FOR DENSE OUTPUT     697 --> 748 
    if Refine > 1 || ntspan > 2 || EventsExist
      cont(:,1) = y;          % Every components of y will be saved
      YDiff     = K(:,5) - y;
      cont(:,2) = YDiff;
      Bspl      = h*K(:,1) - YDiff;
      cont(:,3) = Bspl;
      cont(:,4) = YDiff - h*K(:,4) - Bspl;
      cont(:,5) = d41*K(:,1) + d46*K(:,6) +d47*K(:,7) + d48*K(:,8) + ...
                  d49*K(:,9) + d410*K(:,10) + d411*K(:,11) + d412*K(:,12);
      cont(:,6) = d51*K(:,1) + d56*K(:,6) + d57*K(:,7) + d58*K(:,8) + ...
                  d59*K(:,9) + d510*K(:,10) + d511*K(:,11) + d512*K(:,12);
      cont(:,7) = d61*K(:,1) + d66*K(:,6) + d67*K(:,7) + d68*K(:,8) + ...
                  d69*K(:,9) + d610*K(:,10) + d611*K(:,11) + d612*K(:,12);
      cont(:,8) = d71*K(:,1) + d76*K(:,6) + d77*K(:,7) + d78*K(:,8) + ...
                  d79*K(:,9) + d710*K(:,10) + d711*K(:,11) + d712*K(:,12);
      % ---     THE NEXT THREE FUNCTION EVALUATIONS
      
      time      = t+ch(14);
      y1 = y + h*( a141*K(:,1) + a147*K(:,7) + a148*K(:,8) + ...
                   a149*K(:,9) + a1410*K(:,10) + a1411*K(:,11) + ... 
                   a1412*K(:,12) + a1413*K(:,4));          
      OdeFcnArg = {OdeFcn,time,y1};
      if (Arg.Ode)
        OdeFcnArg = [OdeFcnArg, {varargin{:}}];
      end
      f0 = feval(OdeFcnArg{:});  
      if any(isnan(f0))
        error([Solver_Name, ': Some components of f0 = OdeFcn are NAN'])       
      end    
      if MassExist                % There is a Mass
        switch MassArgNbr
          % case 0   Mass already known         
          case 1
            MassFcnArg = {MassFcn,time};
          case 2
            MassFcnArg = {MassFcn,time,y1};
          otherwise
            MassFcnArg = {MassFcn,time,y1,varargin{:}};
        end
        if MassArgNbr > 0        % If constant already known         
          Mass = feval(MassFcnArg{:}); 
          if any(isnan(Mass))
            error([Solver_Name, ': Some components of Mass are NAN'])       
          end
        end
        K(:,10) = Mass \ f0; 
      else
        K(:,10) = f0;
      end    
     
      time = t+ch(15);
      y1 = y + h*( a151*K(:,1) + a156*K(:,6) + a157*K(:,7) + ...
                  a158*K(:,8) + a1511*K(:,11) + a1512*K(:,12) + ...
                  a1513*K(:,4) + a1514*K(:,10));                          
      OdeFcnArg = {OdeFcn,time,y1};
      if (Arg.Ode)
        OdeFcnArg = [OdeFcnArg, {varargin{:}}];
      end
      f0 = feval(OdeFcnArg{:});  
      if any(isnan(f0))
        error([Solver_Name, ': Some components of f0 = OdeFcn are NAN'])       
      end    
      if MassExist                % There is a Mass
        switch MassArgNbr
          % case 0   Mass already known         
          case 1
            MassFcnArg = {MassFcn,time};
          case 2
            MassFcnArg = {MassFcn,time,y1};
          otherwise
            MassFcnArg = {MassFcn,time,y1,varargin{:}};
        end
        if MassArgNbr > 0        % If constant already known         
          Mass = feval(MassFcnArg{:}); 
          if any(isnan(Mass))
            error([Solver_Name, ': Some components of Mass are NAN'])       
          end
        end
        K(:,11) = Mass \ f0; 
      else
        K(:,11) = f0;
      end    
           
      time = t+ch(16);    
      y1 = y + h*( a161*K(:,1) + a166*K(:,6) + a167*K(:,7) + ...
                   a168*K(:,8) + a169*K(:,9) + a1613*K(:,4)+ ...
                   a1614*K(:,10) + a1615*K(:,11));      
      OdeFcnArg = {OdeFcn,time,y1};
      if (Arg.Ode)
        OdeFcnArg = [OdeFcnArg, {varargin{:}}];
      end
      f0 = feval(OdeFcnArg{:});
      if any(isnan(f0))
        error([Solver_Name, ': Some components of f0 = OdeFcn are NAN'])       
      end
      if MassExist                % There is a Mass
        switch MassArgNbr
          % case 0   Mass already known         
          case 1
            MassFcnArg = {MassFcn,time};
          case 2
            MassFcnArg = {MassFcn,time,y1};
          otherwise
            MassFcnArg = {MassFcn,time,y1,varargin{:}};
        end
        if MassArgNbr > 0        % If constant already known         
          Mass = feval(MassFcnArg{:}); 
          if any(isnan(Mass))
            error([Solver_Name, ': Some components of Mass are NAN'])       
          end
        end
        K(:,12) = Mass \ f0; 
      else
        K(:,12) = f0;
      end   
     Stat.FcnNbr = Stat.FcnNbr+3;      
    
    % ---     FINAL PREPARATION        
      cont(:,5) = h*(cont(:,5) + d413*K(:,4) + d414*K(:,10) + ...
                  d415*K(:,11) + d416*K(:,12));
      cont(:,6) = h*(cont(:,6) + d513*K(:,4) + d514*K(:,10) + ...
                  d515*K(:,11) + d516*K(:,12));
      cont(:,7) = h*(cont(:,7) + d613*K(:,4) + d614*K(:,10) + ...
                  d615*K(:,11) + d616*K(:,12));
      cont(:,8) = h*(cont(:,8) + d713*K(:,4) + d714*K(:,10) + ...
                  d715*K(:,11) + d716*K(:,12));                         
    end  
    
    if EventsExist
      [te,ye,ie,Stop] = EventZeroFcn(EventsFcn,t,h,K(:,5),cont,[],'',varargin{:});
      if ie > 0
        teout = [teout;te];
        yeout = [yeout;ye'];
        ieout = [ieout;ie];
        if Stop 
          t = te;
          y = ye;
          break 
        end
      end      
    end
        
    if nargout > 0
      switch OutFlag        
        case 1          % Computed points, no Refinement 
          nout = nout + 1;
          if nout > length(tout)
            tout = [tout;zeros(nBuffer,1)];
            yout = [yout;zeros(nBuffer,Ny)];  
          end
          tout(nout)   = t;
          yout(nout,:) = y';                                    
        case 2          % Computed points, with refinement   
          nout         = nout + 1;
          tout(nout)   = t;
          yout(nout,:) = y';
          oldnout      = nout;
          nout         = nout + Refine - 1;
          S            = (1:Refine-1)' / Refine;
          if nout > length(tout)
            tout         = [tout; zeros(10*Refine,1)]; 	
            yout         = [yout; zeros(10*Refine,Ny)];
          end
          ii           = oldnout+1:nout;
          tinterp      = t+h*S;
          yinterp      = ntrprad(tinterp,t,h,cont);
          tout(ii)     = tinterp;
          yout(ii,:)   = yinterp;
        case 3          % Output only at tspan points
          while ( PosNeg > 0 && t<= tspan(nout+1) && tspan(nout+1) < tph || ...
                  PosNeg < 0 && t>= tspan(nout+1) && tspan(nout+1) > tph)
            nout         = nout + 1;         
            yinterp      = ntrprad(tspan(nout),t,h,cont);     
            tout(nout)   = tspan(nout);  
            yout(nout,:) = yinterp';  % Column output
          end      
      end
    end 

    if ~isempty(OutputFcn)
      switch OutFlag      % Output function required
        case 1            % Computed points, no Refinement 
          feval(OutputFcn,t,y(OutputSel)','');
        case 2            % Computed points, with refinement 
          [tout2,yout2] = OutFcnSolout2(t,h,y,cont,OutputSel,Refine);
          for k = 1 : length(tout2)
            feval(OutputFcn,tout2(k),yout2(k,:),'');                    
          end       
        case 3            % Output only at tspan points
          [nout3,tout3,yout3] = OutFcnSolout3(nout3,t,h,cont,OutputSel,tspan);          
          for k = 1 : length(tout3)
            feval(OutputFcn,tout3(k),yout3(k,:),'');                    
          end
      end  
    end
          
    K(:,1) = K(:,4);
    t      = tph;
    y      = K(:,5);  
    
    if t == tfinal  
      Done = true;
    end           
    
    if abs(hNew) > hmax
      hNew = PosNeg*hmax;
    end
    if Reject
      hNew = PosNeg*min(abs(hNew),abs(h));
    end
	     
    Reject = false;
  
  else % --- STEP IS REJECTED      depuis 457    (769 Hairer)
      
    hNew = h/min(FacL,Fac11/Safe);
    Reject = true;
    if Stat.StepAccNbr > 1 
      Stat.StepRejNbr = Stat.StepRejNbr + 1;
    end       
    if StatsExist
      Dyn.hreject_t    = [Dyn.hreject_t,t];
      Dyn.hreject_Step = [Dyn.hreject_Step,Stat.StepNbr];
      Dyn.hreject      = [Dyn.hreject,h];
    end
  end
  h = hNew;
end  % while

% Output of the last value
if StatsExist
  Stats.Stat = Stat;
  Stats.Dyn  = Dyn;
end

OutputNbr = abs(nargout);
if OutputNbr > 0 
  nout         = nout + 1;
  tout(nout)   = t;
  yout(nout,:) = y';
  tout         = tout(1:nout);
  yout         = yout(1:nout,:);
  varargout = {tout,yout};
  if EventsExist
    varargout = [varargout,{teout,yeout,ieout}];
  end
  if StatsExist
    varargout = [varargout,{Stats}];
  end      
end  
 
if OutputFcnExist   % Close the OutputFcn        
  OutputFcnArg = {OutputFcn,t,y(OutputSel)',''};
  feval(OutputFcnArg{:}); 
  OutputFcnArg = {OutputFcn,t,y(OutputSel)','done'};
  feval(OutputFcnArg{:});
end
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------

% Computed points, with Refinement
function [tout,yout] = OutFcnSolout2(t,h,y,cont,OutputSel,Refine)
tout       = zeros(Refine,1); 	
yout       = zeros(Refine,length(OutputSel));
tout(1)    = t;
yout(1,:)  = y(OutputSel)';
ii         = 2:Refine;
S          = (1:Refine-1)' / Refine;
tinterp    = t+h*S;
yinterp    = ntrprad(tinterp,t,h,cont);
tout(ii)   = tinterp;
yout(ii,:) = yinterp(:,OutputSel);

% Output only at tspan points 
function [nout,tout,yout] = OutFcnSolout3(nout,t,h,cont,OutputSel,tspan)
PosNeg = sign(tspan(end) - tspan(1));
tph    = t+h;
tout   = [];
yout   = [];
Compt  = 0;
while ( PosNeg > 0 && t <= tspan(nout+1) && tspan(nout+1) < tph || ...
        PosNeg < 0 && t>= tspan(nout+1) && tspan(nout+1) > tph)
  Compt         = Compt + 1 ;
  nout          = nout + 1;
  yinterp       = ntrprad(tspan(nout),t,h,cont);     
  tout(Compt)   = tspan(nout); 
  yout(Compt,:) = yinterp(OutputSel)';  % Column output
end

function yinterp = ntrprad(tinterp,t,h,cont)
S       = (tinterp-t)/h;   % S is theta in the book
S1      = 1-S;
for k = 1:length(S)
  ConPar        = cont(:,5)+S(k)*(cont(:,6)+S1(k)*(cont(:,7)+ S(k)*cont(:,8)));        
  yinterp(k,:)  = cont(:,1) + S(k)*(cont(:,2) + S1(k)*(cont(:,3) + ...
                 S(k)*(cont(:,4) + S1(k)*ConPar)));
end
return

function h = hInitFcn(OdeFcn,MassFcn,MassArgNbr,Arg,t,y,PosNeg,hmax,f0,RelTol,AbsTol,varargin)                          
% ----------------------------------------------------------
% ----  COMPUTATION OF AN INITIAL STEP SIZE GUESS
% ----------------------------------------------------------      
% ---- COMPUTE A FIRST GUESS FOR EXPLICIT EULER AS
% ----   H = 0.01 * NORM (Y0) / NORM (F0)
% ---- THE INCREMENT FOR EXPLICIT EULER IS SMALL
% ---- COMPARED TO THE SOLUTION


% ------- MASSFCN arguments or not
Function_Name = 'hInitFcn';

Ordre = 8;

Sk  = AbsTol + RelTol.*abs(y);
Dnf = sum( (f0./Sk).^2 );
Dny = sum( (y./Sk).^2 );
if (Dnf < 1e-10 || Dny < 1e-10)
  h = 1e-6;
else
  h = sqrt(Dny/Dnf) * 0.01; 
end
h = min(h,hmax) * PosNeg;

% ---- PERFORM AN EXPLICIT EULER STEP
y1 = y + h*f0;

OdeFcnArg = {OdeFcn,t+h,y1};
if ~isempty(Arg.Ode)
  OdeFcnArg = [OdeFcnArg, {varargin{:}}];
end 
f1 = feval(OdeFcnArg{:}); 
if any(isnan(f1))
  error([Solver_Name, ': Some components of f0 = OdeFcn are NAN'])       
end
if ~isempty(MassFcn) 
  switch MassArgNbr
    case 0      
      MassFcnArg = {MassFcn};    
    case 1
      MassFcnArg = {MassFcn,t+h};
    case 2
      MassFcnArg = {MassFcn,t+h,y1};
    otherwise
      MassFcnArg = {MassFcn,t+h,y1,varargin{:}};
  end
  Mass = feval(MassFcnArg{:});
  if any(isnan(Mass))
    error([Solver_Name, ': Some components of Mass are NAN'])       
  end
  f1 = Mass \ f1;  
end

% ---- ESTIMATE THE SECOND DERIVATIVE OF THE SOLUTION
Sk   = AbsTol + RelTol .* abs(y);
Der2 = sum ( ((f1-f0)./Sk).^2 );   
Der2 = sqrt(Der2)/h;
% ---- STEP SIZE IS COMPUTED SUCH THAT
% ----  H**IORD * MAX ( NORM (F0), NORM (DER2)) = 0.01
Der12 = max(abs(Der2),sqrt(Dnf));
if Der12 <= 1e-15 
  h1 = max(1e-6,abs(h)*1e-3);
else
  h1 = (0.01/Der12)^(1/Ordre);
end
h = min([100*abs(h),h1,hmax])*PosNeg;
return
% -------------------------------------------------------------------
% -------------------------------------------------------------------
function [tout,yout,iout,Stop] = EventZeroFcn(EvFcn,t,h,y,...
                                 cont,f0,Flag,varargin)
% EventZeroFcn evaluate, if it exist, the value of the zero of the Events
% function. The t interval is [t, t+h]. The method is the Regula Falsi.

persistent t1 E1v 
% E1vt = [t1,E1v]

tout = [];
yout = [];
iout = [];
Stop = 0;
t2   = t+h;

EvFcnArgNbr = abs(nargin(EvFcn));
switch EvFcnArgNbr
  case 1   
    EvFcnVar = {EvFcn,t2};
  case 2
    EvFcnVar = {EvFcn,t2,y};
  otherwise
    EvFcnVar = {EvFcn,t2,y,varargin{:}};
end
 
if strcmp(Flag,'init')
  [E1v,Stopv,Slopev] = feval(EvFcnVar{:});
  t1                 = t;
  Ind = find(E1v == 0);
  if ~isempty (Ind)
    IndL = length(Ind);
    for k = 1 : IndL
      if sign(f0(Ind(k))) == Slopev(k)
        tout = t;
        yout = y';
        iout = Ind(k); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Stop = false;
      end
    end
  end
  return
end

[E2v,Stopv,Slopev] = feval(EvFcnVar{:});
IterMax = 50;
%tol     = 1e-6;                                  % --> ~1e-7
%tol     = 1024*max([eps,eps(t2),eps(t1)]);       % --> ~1e-12
%tol     = 131072 * max([eps,eps(t2),eps(t1)]);   % --> ~1e-10
tol     = 65536 * max([eps,eps(t2),eps(t1)]);  % --> ~1e-9

tol     = min(tol, abs(t2 - t1));
tAbsTol = tol; 
tRelTol = tol;
EAbsTol = tol;

Indk = 0;
NE1v = length(E1v);
for k = 1: NE1v 
  t1N = t1;
  t2N = t2;
  E1  = E1v(k);
  E2  = E2v(k);
  E12 = E1*E2;
  p12 = (E2-E1)/(t2N-t1N);
    
  if (E12 < 0) && (p12*Slopev(k) >= 0) % An event is there
    
    Indk = Indk + 1;   % Indice de stockage   
    Done = false;
    Iter = 0;
    
    tNew = t2N;
    yNew = y;
    ENew = E2;     
    while ~Done      
      Iter = Iter + 1;
      if Iter >= IterMax 
        warning('EventZeroFcn: iteration number > maximal iteration number \n')    
        break
      end
      tRel = abs(t1N-t2N)*tRelTol < max(abs(t1N),abs(t2N));
      tAbs = abs(t1N-t2N) < tAbsTol;
      if abs(ENew) < EAbsTol && tRel && tAbs  % On a trouvé        
        break
      else    
        % Regula falsi or dichotomy
        if abs(E1) < 200*EAbsTol || abs(E2) < 200*EAbsTol
          tNew = 0.5*(t1N + t2N);          
        else                     
          tNew = (t1N*E2-t2N*E1)/(E2-E1);
        end        
        S    = (tNew-t1)/h;
        S1   = 1-S;
        yNew = cont(:,1) + S*(cont(:,2) + S1*(cont(:,3) + ...
                           S*(cont(:,4) + S1*cont(:,5))));
        switch EvFcnArgNbr
          case 1   
            EvFcnVar = {EvFcn,tNew};
          case 2
            EvFcnVar = {EvFcn,tNew,yNew};
          otherwise
            EvFcnVar = {EvFcn,tNew,yNew,varargin{:}};
        end                                          
        ENew = feval(EvFcnVar{:});  
        ENew = ENew(k);
        if ENew * E1 > 0 
          t1N = tNew;
          E1  = ENew;
        else
          t2N = tNew;
          E2  = ENew;
        end
      end
    end
    ioutk(Indk)   = k;   
    toutk(Indk)   = tNew;
    youtk(Indk,:) = yNew;
    Stopk(Indk)   = Stopv(k);
  end
  if exist('toutk')
    if t1 < t2
      [mt,Ind] = min(toutk);
    else
      [mt,Ind] = max(toutk);
    end
    iout = ioutk(Ind(1));
    tout = mt(1);
    yout = youtk(Ind(1),:)';
    Stop = Stopk(Ind(1));
  end
end
t1  = t2;
E1v = E2v;
% -------------------------------------------------------------------
% -------------------------------------------------------------------

