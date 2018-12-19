function o = rdpget(options,name,default,flag)
%RDPGET Get ODE OPTIONS parameters.
%   VAL = RDPGET(OPTIONS,'NAME') extracts the value of the named property
%   from integrator options structure OPTIONS, returning an empty matrix if
%   the property value is not specified in OPTIONS.  [] is a valid OPTIONS 
%   argument.
%   
%   VAL = RDPGET(OPTIONS,'NAME',DEFAULT) extracts the named property as
%   above, but returns VAL = DEFAULT if the named property is not specified
%   in OPTIONS. For example
%   
%       val = rdpget(opts,'RelTol',1e-4);
%   
%   returns val = 1e-3 if the RelTol property is not specified in opts.
%   
%   See also RDPSET, RADAU,DOP45 and DOP853
% ------------------------------------------------------------------------

Fcn_Name = 'rdpget';

if (nargin == 4) && isequal(flag,'fast')
   o = getknownfield(options,name,default);
   return
end

if nargin < 2
  error(message([Fcn_Name,': NotEnoughInputs']));
end
if nargin < 3
  default = [];
end

if ~isempty(options) && ~isa(options,'struct')
  error(message([Fcn_Name,': Arg1NotODESETstruct']));
end

if isempty(options)
  o = default;
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
names = lower(Names);

lowName = lower(name);
j = strmatch(lowName,names);
if isempty(j)  
  error([Fcn_Name,': InvalidPropName:  ', name]);
elseif length(j) > 1            % if more than one match
  % Check for any exact matches (in case any names are subsets of others)
  k = strmatch(lowName,names,'exact');
  if length(k) == 1
    j = k;
  else
    matches = deblank(Names(j(1),:));
    for k = j(2:length(j))'
      matches = [matches ', ' deblank(Names(k,:))]; %#ok<AGROW>
    end
    error([Fcn_Name,': AmbiguousPropName'],name,matches);
  end
end

if any(strcmp(fieldnames(options),deblank(Names(j,:))))
  o = options.(deblank(Names(j,:)));
  if isempty(o)
    o = default;
  end
else
  o = default;
end

% --------------------------------------------------------------------------
function v = getknownfield(s, f, d)
%GETKNOWNFIELD  Get field f from struct s, or else yield default d.

if isfield(s,f)   % s could be empty.
  v = s.(f);
  if isempty(v)
    v = d;
  end
else
  v = d;
end

