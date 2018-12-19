function options = rdpset(varargin)
% RDPSET Create/alter RADAU DOP45 DOP853 DOP54D DOP853D OPTIONS structure.
%   OPTIONS = RDPSET('NAME1',VALUE1,'NAME2',VALUE2,...) creates an 
%   integrator options structure, OPTIONS, in which the named properties 
%   have the specified values. Any unspecified properties have default 
%   values. 
%   
%   OPTIONS = RDPSET(OLDOPTS,'NAME1',VALUE1,...) alters an existing options
%   structure OLDOPTS.
%   
%   OPTIONS = RDPSET(OLDOPTS,NEWOPTS) combines an existing options 
%   structure, OLDOPTS, with a new options structure NEWOPTS. Any new
%   properties overwrite corresponding old properties. 
%   
%   RDPSET with no input arguments displays all property names and their
%   possible values.
%   
% RDPSET PROPERTIES
%   
%  All solver
%  ----------
%
%  RelTol - Relative error tolerance  [ positive scalar {1e-3} ]
%   This scalar applies to all components of the solution vector, and
%   defaults to 1e-3 (0.1% accuracy) in all solvers. The estimated error in
%   each integration step satisfies e(i)<=max(RelTol*abs(y(i)),AbsTol(i)).
%
%  AbsTol - Absolute error tolerance  [ positive scalar or vector {1e-6} ]
%   A scalar tolerance applies to all components of the solution vector.
%   Elements of a vector of tolerances apply to corresponding components of
%   the solution vector. AbsTol defaults to 1e-6 in all solvers. 
% 
%  InitialStep 
%   Initial step guess. For stiff equations with initial transient, 
%   InitialStep = 1/norm(f'), usually 1e-3 or 1e-5 is good. This 
%   choice is not very important, the step is quickly adapted. If 
%
%  MaxStep 
%   MaxStep, it's the larger allowed step. Default to 
%   abs(tspan(end)-tspan(1))
%
%  MaxNbrStep
%   MaxNbrStep is the maximal number of allowed steps (default is 100000) 
%   (IWORK(2))
%
%  Refine - Output refinement factor  [ positive integer ]
%   This property increases the number of output points by the specified
%   factor producing smoother output. Refine does not apply if 
%   length(TSPAN) > 2. 
% 
%  OutputFcn - Installable output function  [ function_handle ]
%   This output function is called by the solver after each time step. When
%   a solver is called with no output arguments, OutputFcn defaults to 
%   @odeplot. Otherwise, OutputFcn defaults to [].
% 
%  OutputSel - Output selection indices  [ vector of integers ]
%   This vector of indices specifies which components of the solution
%   vector are passed to the OutputFcn. OutputSel defaults to all 
%   components.
%
%  FacL   (default is 0.2)  (WORK(8))
%  FacR   (default is 8.0)  (WORK(9))
%   Parameters for step size selection. The new step size is chosen subject 
%   to the restriction FacL <= hnew / hold <= FacR
%
%  NormControl 
%    If true, the solvers control the error in each integration step 
%    with norm(e) <= max(RelTol*norm(y),AbsTol). By default the solvers 
%    use a more stringent componentwise error control.
%
%  Safe
%   The safety factor in step size selection  0.8 - 095  (default is 0.9).
%   (WORK(2))
%
%  MassFcn
%   MassFcn is the name or the handle of the user given function which 
%   define the mass in m*y' = f(t,y). Default: identity matrix.
%
%  EventsFcn
%   EventsFcn is the name or the handle of the user given function which 
%   define the events. (Default []).
%
%  DOPxxx Only
%  -----------
%
%  StiffTest 
%   Test for stiffness of the system (positiv integer {1000}. 
%
%  Beta 
%   Parameter for stabilized step control ( <= 0.04) make the step size
%   control more stable. default 0.
% 
%  RADAU only
%  ------------------
%  Complex   
%   Specific to radau solver
%   Complex a logical parameter [false]. If complex == false, all the 
%   calculations are real else complex calculations are allowed.
%
%  The following 3 integers are important for differential-algebraic 
%  systems of Index > 1 
%  The function which define the differential problem should be written 
%  such that the index 1 2 3 variables appear in this order. 
%  In estimating the error, the index 2 variables are multiplied by h 
%  (step size) and the index 3 variables by h^2.
%  NbrInd1+NbrInd2+NbrInd3 must be equal to the dimension of the system.
%
%  NbrInd1 
%    NbrInd1 Dimension of the index 0 or 1 variables. For ODE's this is 
%    equal to the dimension of the system (default)  (IWORK(5))
%    
%  NbrInd2 
%   NbrInd2 is the dimension of the index 2 variables [0]. IWORK(6))
%
%  NbrInd3 
%   NbrInd3 is the dimension of the index 3 variables [0]. (IWORK(7))
%   
%  Jacobian
%   Jacobian is the name or the handle of the user given function which 
%   define the jacobian of the problem. By default (if there is no user 
%   defined jacobian), radau evaluate the jacobian numerically.
%  
%  JacRecompute
%   JacRecompute decides whether the jacobian should be recomputed. 
%   Increase JacRecompute to 0.1 say, when jacobian evaluations are costly. 
%   For small systems JacRecompute should be smaller (0.001 say). 
%   Negative JacRecompute forces the code to compute the jacobian after 
%   every accepted step. [0.001].
%
%  Start_Newt
%   Start_Newt is a logical parameter. If Start_Newt == false, the 
%   extrapolated collocation solution is taken as starting value for 
%   Newton's method. If Start_Newton == true, zero starting value are used.
%   The latter is recommended if Newton's method has difficulties with 
%   convergence. This is the case when nstep is larger than naccpt+nreject. 
%   Default is false.   (IWORK(4))
%
%  MaxNbrNewton
%   MaxNbrNewton is the maximum number of Newton iterations for the 
%   solution of the implicit system in each step. [7] MaxNbrNewton depends 
%   on NS, the number of Stage on the following way : 
%   NS = 1 -->  MaxNbrNewton - 3
%   NS = 3 -->  MaxNbrNewton 
%   NS = 5 -->  MaxNbrNewton + 5
%   NS = 7 -->  MaxNbrNewton + 10  (IWORK(3)).
%     
%  NbrStg 
%   NbrStg is the number of stages used at the beginning of the 
%   calculations. This value may be 1, 3, 5 or 7. (1 for implicit Euler, 
%   3 5 7 for radau)  (Default is NbrMinStg) 
%   NbrStg must obey the relation:  MinNbrStg <= NbrStg <= MaxNbrStg  
%   (IWORK(13)).
%   
%  MinNbrStg 
%   MinNbrStg is the minimum number of stages used in the calculation, 
%   this value may be 1 3 5 or 7  [3] (IWORK(11)).
%
%  MaxNbrStg 
%   MaxNbrStg is the maximmum number of stages used in the calculation,
%   this value may be 1 3 5 or 7  [7] (IWORK(12)).
%   MinNbrStg must be <= MaxNbrStg.  
%  
%  Quot1   (default is 1.0)
%  Quot2   (default is 1.2)
%   If Quot1 < hnew/hold < Quot2, then the step size is not changed. This 
%   saves, together with a large "JacRecompute", LU-decomposition and 
%   computing time for large systems. For small systems one may have 
%   Quot1 = 1 and Quot2 = 1.2. For large full systems Quot1 = 0.99 and 
%   Quot2 = 2.0 might be good
%
%  Vitu  
%   Order is increased if the contractivity factor is smaller than Vitu.
%   (Default is 0.002) (WORK(10)) 
%
%  Vitd   
%   Order is decreased if the contractivity factor is bigger than Vitd.
%   (Default is 0.8)  (Work(11)).
%
%  hhou  (default is 1.2)  (WORK(12))
%  hhod  (default is 0.8)  (WORK(13))
%   The order is decreased only if the step size ratio satisfies:
%   hhod <= hnew/h <= hhou
%
%  Gustafsson (logical) [true]  (IWORK(8))
%   If Gustafsson is true, mod. predictive controller (Gustafsson) 
%   If Gustafsson is false, classical step size control 
%   The choice Gustafsson == true seems to produce safer results.
%   In this code Gustafsson == true produces faster runs.
%   In Hairer - Wanner code we find the following sentence :
%   "For simple problems, the choice Gustafsson == false produces often 
%   slightly faster runs."
%
%   This is essentially an adaptation of RADAU  (FORTAN to MATLAB)
%   Authors of the FORTRAN code: 
%
%      E. Hairer and G. Wanner
%      Universite de Geneve, Dept. de Mathematiques
%      CH-1211 Geneve 24, SWITZERLAND 
%      email:  hairer@divsun.unige.ch, wanner@divsun.unige.ch
%
% Denis Bichsel
% Deurres 58
% 2000 NeuchÃ¢tel
% dbichsel@infomaniak.ch
%
% Version end of 2015
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
Fcn_Name = 'rdpset';

if (nargin == 0) && (nargout == 0)
  fprintf(' General parameters (for all solvers \n');  
  fprintf('          AbsTol: [ positive scalar or vector {1e-6} ]\n');
  fprintf('          RelTol: [ positive scalar {1e-3} ]\n');
  fprintf('     InitialStep: [ scalar ]\n');
  fprintf('         MaxStep: [ positive scalar ]\n');
  fprintf('      MaxNbrStep: [ positive integer ]\n'); 
  fprintf('          Refine: [ positive integer ]\n'); 
  fprintf('       OutputFcn: [ function_handle ]\n');
  fprintf('       OutputSel: [ vector of integers ]\n');   
  fprintf('            FacL: [  {5.0} ]\n');
  fprintf('            FacR: [  {1/8} ]\n');
  fprintf('     NormControl: [ logical {false}]\n'); 
  fprintf('            Safe: [ 0.8 - 0.95  ]\n'); 
  fprintf('         MassFcn: [ function_handle ]\n');
  fprintf('       EventsFcn: [ function_handle ]\n');
  fprintf(' Parameters for DOPxxx solver \n'); 
  fprintf('       StiffTest: [ Positive Integer {1000}]\n');
  fprintf('            Beta: [ {0.04}]\n');
  fprintf(' Parameters for radau solver \n');
  fprintf('         Complex: [ logical ]\n');
  fprintf('         NbrInd1: [ integer >= 0 ]\n');
  fprintf('         NbrInd2: [ integer >= 0 ]\n');
  fprintf('         NbrInd3: [ integer >= 0 ]\n');
  fprintf('          JacFcn: [ function_handle ]\n');  
  fprintf('    JacRecompute: [ 0.001 - < 1 ]\n');     % Thet dans le code
  fprintf('      Start_Newt: [ logical ] \n');
  fprintf('    MaxNbrNewton: [ positive integer ]\n');  
  fprintf('          NbrStg: [ {3} ]\n');
  fprintf('       MinNbrStg: [ 1 | 3 | 5 | 7 |  {3} ]\n');
  fprintf('       MaxNbrStg: [ 1 | 3 | 5 | 7 |  {7} ]\n');
  fprintf('           Quot1: [  {1.0} ]\n');
  fprintf('           Quot2: [  {1.2} ]\n');  
  fprintf('            Vitu: [  {0.002} ]\n'); 
  fprintf('            Vitd: [  {0.8} ]\n');
  fprintf('            hhou: [  ]\n');
  fprintf('            hhod: [  ]\n');
  fprintf('      Gustafsson: [ logical {true} ]\n');
  fprintf('\n');
  return;
end
Names = [
    'AbsTol          '   % General parameters
    'RelTol          '
    'InitialStep     '
    'MaxStep         '
    'MaxNbrStep      '
    'Refine          '
    'OutputFcn       '
    'OutputSel       '
    'FacL            '
    'FacR            '
    'NormControl     '
    'Safe            ' 
    'MassFcn         '
    'EventsFcn       '
    'StiffTest       '
    'Beta            '
    'Complex         '  
    'NbrInd1         '
    'NbrInd2         '
    'NbrInd3         '
    'JacFcn          '
    'JacRecompute    '
    'Start_Newt      '   
    'MaxNbrNewton    '
    'NbrStg          '
    'MinNbrStg       '
    'MaxNbrStg       '            
    'Quot1           '
    'Quot2           '     
    'Vitu            '
    'Vitd            ' 
    'hhou            '
    'hhod            ' 
    'Gustafsson      '           
    ]; 
m     = size(Names,1);
names = lower(Names);

% Combine all leading options structures o1, o2, ... in odeset(o1,o2,...).
options = [];
for j = 1:m
  options.(deblank(Names(j,:))) = [];
end
i = 1;
while i <= nargin
  arg = varargin{i};
  if ischar(arg)                         % arg is an option name
    break;
  end
  if ~isempty(arg)                      % [] is a valid options argument
    if ~isa(arg,'struct')
      error(message([Fcn_Name,': NoPropNameOrStruct'], i));       
    end
    for j = 1:m
      if any(strcmp(fieldnames(arg),deblank(Names(j,:))))
        val = arg.(deblank(Names(j,:)));
      else
        val = [];
      end
      if ~isempty(val)
        options.(deblank(Names(j,:))) = val;
      end
    end
  end
  i = i + 1;
end

% A finite state machine to parse name-value pairs.
if rem(nargin-i+1,2) ~= 0
  error(message([Fcn_Name,': ArgNameValueMismatch']));
end
expectval = 0;                          % start expecting a name, not a value
while i <= nargin
  arg = varargin{i};
    
  if ~expectval
    if ~ischar(arg)
      error(message([Fcn_Name,': NoPropName'], i));    
    end    
    lowArg = lower(arg);
    j = strmatch(lowArg,names);
    if isempty(j)   
      names(j)% if no matches
      error([Fcn_Name,': InvalidPropName'], arg);
    elseif length(j) > 1                % if more than one match
      % Check for any exact matches (in case any names are subsets of others)
      k = strmatch(lowArg,names,'exact');
      if length(k) == 1
        j = k;
      else
            matches = deblank(Names(j(1),:));
        for k = j(2:length(j))'
                matches = [matches ', ' deblank(Names(k,:))]; %#ok<AGROW>
        end
            error([Fcn_Name,': AmbiguousPropName'],arg,matches);
      end
    end
    expectval = 1;                      % we expect a value next
    
  else
    options.(deblank(Names(j,:))) = arg;
    expectval = 0;
      
  end
  i = i + 1;
end

if expectval
  error([Fcn_Name,': NoValueForProp'], arg);
end
