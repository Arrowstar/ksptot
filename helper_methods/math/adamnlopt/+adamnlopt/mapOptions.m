function opts = mapOptions(userOpts)
%MAPOPTIONS  Merge user options onto defaults, mapping fmincon option names.
%   opts = adamnlopt.mapOptions(userOpts) accepts a struct (with either
%   adamnlopt field names or fmincon names) or an optimoptions object and
%   returns a fully populated adamnlopt options struct.
%
%   Starts from adamnlopt.defaultOptions and overrides fields from userOpts.
%   A small name map translates recognized fmincon option names (e.g.
%   MaxIterations, OptimalityTolerance, ConstraintTolerance) onto the native
%   adamnlopt field names; native field names supplied directly are copied
%   through as-is. Empty values are ignored; names that match neither a mapped
%   fmincon name nor a native field are ignored with a warning. When userOpts is
%   an optimoptions object, each mapped property is read defensively (in a
%   try/catch) so unset or unsupported properties do not error. Finally the
%   fmincon symbolic default 'sqrt(eps)' for FiniteDifferenceStepSize is coerced
%   to its numeric value so downstream finite-difference arithmetic stays scalar.
%
%   Inputs:
%     userOpts - (optional) struct of adamnlopt and/or fmincon option names, or
%                an optimoptions object. Empty or omitted returns the defaults.
%
%   Outputs:
%     opts - fully populated adamnlopt options struct (defaults with the
%            recognized user overrides applied).
%
%   See also DEFAULTOPTIONS, VALIDATEPROBLEM.

import adamnlopt.*
opts = defaultOptions();
if nargin < 1 || isempty(userOpts)
    return;
end

% fmincon name -> adamnlopt field name
map = { ...
    'MaxIterations',            'maxIter'; ...
    'MaxFunctionEvaluations',   'maxFunEvals'; ...
    'OptimalityTolerance',      'optTol'; ...
    'ConstraintTolerance',      'feasTol'; ...
    'StepTolerance',            'stepTol'; ...
    'SpecifyObjectiveGradient', 'SpecifyObjectiveGradient'; ...
    'SpecifyConstraintGradient','SpecifyConstraintGradient'; ...
    'HessianFcn',               'HessianFcn'; ...
    'HessPattern',              'HessPattern'; ...
    'JacobPattern',             'JacobPattern'; ...
    'FiniteDifferenceStepSize', 'FiniteDifferenceStepSize'; ...
    'FiniteDifferenceType',     'FiniteDifferenceType'; ...
    'HonorBounds',              'HonorBounds'; ...
    'Display',                  'Display' };

if isstruct(userOpts)
    fn = fieldnames(userOpts);
    % Everything acceptable as an input name: the mapped fmincon names plus the
    % native adamnlopt field names.  Anything else is a typo or a stale option.
    known = [map(:,1); fieldnames(opts)];
    unknown = cell(numel(fn), 1);
    nUnknown = 0;
    for i = 1:numel(fn)
        name = fn{i};
        if ~any(strcmp(name, known))
            nUnknown = nUnknown + 1;
            unknown{nUnknown} = name;
            continue;
        end
        val = userOpts.(name);
        if isempty(val), continue; end
        idx = find(strcmp(name, map(:,1)), 1);
        if ~isempty(idx)
            opts.(map{idx,2}) = val;      % fmincon name
        else
            opts.(name) = val;            % native adamnlopt name
        end
    end
    if nUnknown > 0
        unknown = unknown(1:nUnknown);
        warning('adamnlopt:unknownOption', ...
            ['Unknown option(s) passed to adamnlopt.solve and ignored: %s. ' ...
             'Valid names are the fields of adamnlopt.defaultOptions plus the ' ...
             'fmincon names MaxIterations, MaxFunctionEvaluations, ' ...
             'OptimalityTolerance, ConstraintTolerance and StepTolerance.'], ...
            strjoin(unknown, ', '));
    end
else
    % optimoptions object: read known fmincon properties defensively.
    for i = 1:size(map,1)
        name = map{i,1};
        try
            val = userOpts.(name);
        catch
            continue;
        end
        if ~isempty(val)
            opts.(map{i,2}) = val;
        end
    end
end

% fmincon stores the FiniteDifferenceStepSize default symbolically as the char
% 'sqrt(eps)'; coerce any non-numeric value to the numeric step so downstream
% finite-difference arithmetic is scalar.
fd = opts.FiniteDifferenceStepSize;
if ~isnumeric(fd)
    v = str2double(fd);
    if ~isnan(v)
        opts.FiniteDifferenceStepSize = v;
    else
        opts.FiniteDifferenceStepSize = sqrt(eps);
    end
end

% Validate the Hessian-model selector.  An unrecognized string used to fall
% through silently to the finite-difference Hessian, and 'bfgs' was an
% undocumented alias for 'lbfgs'.  Both are now genuine, distinct models, so a
% typo has to be an error rather than a silent change of algorithm.
ha = opts.hessianApprox;
if ~(ischar(ha) || isstring(ha)) || ~isscalar(string(ha))
    error('adamnlopt:hessianApprox', ...
          'hessianApprox must be one of ''exact'', ''fd'', ''lbfgs'', ''bfgs''.');
end
try
    opts.hessianApprox = validatestring(char(ha), {'exact','fd','lbfgs','bfgs'});
catch
    error('adamnlopt:hessianApprox', ...
          ['Unrecognized hessianApprox ''%s''; expected ''exact'', ''fd'', ' ...
           '''lbfgs'' or ''bfgs''.'], char(ha));
end

% Validate the returned-iterate selector on the same principle: a typo here
% silently changes which point comes back, which is exactly the kind of change a
% caller would never notice from the outputs alone.
ri = opts.returnIterate;
if ~(ischar(ri) || isstring(ri)) || ~isscalar(string(ri))
    error('adamnlopt:returnIterate', ...
          'returnIterate must be ''last'' or ''bestKKT''.');
end
try
    opts.returnIterate = validatestring(char(ri), {'last','bestKKT'});
catch
    error('adamnlopt:returnIterate', ...
          'Unrecognized returnIterate ''%s''; expected ''last'' or ''bestKKT''.', ...
          char(ri));
end
end
