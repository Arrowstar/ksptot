function options = gniset(varargin)
%GNISET Create/alter GNI OPTIONS structure.
%   The syntax for GNISET is the same as for ODESET, but the list of possible
%   properties is different.
%   
%GNISET PROPERTIES
%   
%OutputFcn - Name of installable output function  [ string ]
%   This output function is called by the solver after each time step.  When
%   a solver is called with no output arguments, OutputFcn defaults to
%   'odeplot'.  Otherwise, OutputFcn defaults to ''.
%   
%OutputSel - Output selection indices  [ vector of integers ]
%   This vector of indices specifies which components of the solution vector
%   are passed to the OutputFcn.  OutputSel defaults to all components.
%   
%OutputSteps - Which steps to output  [ integer | 1 ]
%   This value tells which computed solution points are sent to the output. If
%   OutputSteps = 10, every 10th solution point is sent to the output. If
%   OutputSteps = -1, only the first and the last values are sent to the output.
%   
%Vectorized - Vectorized ODE file  [ on | {off} ]
%   Set this property 'on' if the ODE file is coded so that F(t,[y1 y2 ...])
%   returns [F(t,y1) F(t,y2) ...].
%   
%Events - Locate events  [ on | {off} ]
%   Set this property 'on' if the ODE file is coded so that F(t,y,'events')
%   returns the values of an event function.  See ODEFILE.
%   
%StepSize - Step size  [ positive scalar ]
%   The solver will use a fixed step size given by StepSize. It may be
%   slightly altered if the length of the integration interval is not an
%   integer multiple of the step size.
%   
%NumSteps - Number of steps  [ positive integer ]
%   The solver will use a fixed step size adjusted to make NumSteps steps.
%   If StepSize is set, it overrides this option.
%   
%MaxIter - Maximal number of iterations [ integer | {50} ]
%   Maximal number of Gauss-Newton iterations performed at each step for gni_irk2.
%
%PartialFlow - Name of a flow function [ string | {'stverl'} ]
%   The flow function is used by the composition method gni_comp.
%
%Method - Name of the method [ string | {'817'} ]
%   For gni_irk2, implemented methods are 'G4', 'G8', and 'G12'.
%   For gni_comp, implemented methods are '43', '45', '67', '69',
%      '815', '817', '1033', and '21'.
%   For gni_lmm2, implemented methods are '801', '802', and '803'.
%   In all cases the first one or two digits denote the order of the method.
%
%   See also GNIGET, GNI_IRK2, GNI_COMP, GNI_LMM2.

% Print out possible values of properties.
if (nargin == 0) & (nargout == 0)
  fprintf('       OutputFcn: [ string ]\n');
  fprintf('       OutputSel: [ vector of integers ]\n');
  fprintf('     OutputSteps: [ integer ]\n');
  fprintf('      Vectorized: [ on | {off} ]\n');
  fprintf('          Events: [ on | {off} ]\n');
  fprintf('        StepSize: [ positive scalar ]\n');
  fprintf('        NumSteps: [ positive integer ]\n');
  fprintf('         MaxIter: [ positive integer ]\n');
  fprintf('     PartialFlow: [ string ]\n');
  fprintf('          Method: [ string ]\n');
  fprintf('\n');
  return;
end

Names = [
    'OutputFcn   '
    'OutputSel   '
    'OutputSteps '
	'Events      '
    'Stats       '
    'Vectorized  '
	'Jacobian    '
	'StepSize    '
	'NumSteps    '
	'MaxIter     '
	'PartialFlow '
	'Method      '
    ];
[m,n] = size(Names);
names = lower(Names);

options = [];
i = 1;
while i <= nargin
  arg = varargin{i};
  if isstr(arg)                         % arg is an option name
    break;
  end
  if ~isempty(arg)                      % [] is a valid options argument
    if ~isa(arg,'struct')
      error(sprintf(['Expected argument %d to be a string property name ' ...
                     'or an options structure\ncreated with GNISET.'], i));
    end
    if isempty(options)
      options = arg;
    else
      for j = 1:m
        val = getfield(arg,Names(j,:));
        if ~isequal(val,[])             % empty strings '' do overwrite
          options = setfield(options,Names(j,:),val);
        end
      end
    end
  end
  i = i + 1;
end
if isempty(options)
  for j = 1:m
    options = setfield(options,Names(j,:),[]);
  end
end

% A finite state machine to parse name-value pairs.
if rem(nargin-i+1,2) ~= 0
  error('Arguments must occur in name-value pairs.');
end
expectval = 0;                          % start expecting a name, not a value
while i <= nargin
  arg = varargin{i};
    
  if ~expectval
    if ~isstr(arg)
      error(sprintf('Expected argument %d to be a string property name.', i));
    end
    
    lowArg = lower(arg);
    j = strmatch(lowArg,names);
    if isempty(j)                       % if no matches
      error(sprintf('Unrecognized property name ''%s''.', arg));
    elseif length(j) > 1                % if more than one match
      % Check for any exact matches (in case any names are subsets of others)
      k = strmatch(lowArg,names,'exact');
      if length(k) == 1
        j = k;
      else
        msg = sprintf('Ambiguous property name ''%s'' ', arg);
        msg = [msg '(' deblank(Names(j(1),:))];
        for k = j(2:length(j))'
          msg = [msg ', ' deblank(Names(k,:))];
        end
        msg = sprintf('%s).', msg);
        error(msg);
      end
    end
    expectval = 1;                      % we expect a value next
    
  else
    options = setfield(options,Names(j,:),arg);
    expectval = 0;
      
  end
  i = i + 1;
end

if expectval
  error(sprintf('Expected value for property ''%s''.', arg));
end
