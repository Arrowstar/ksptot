function util_echoOptions(opts)
%UTIL_ECHOOPTIONS  Print the non-default solver options in effect.
%   adamnlopt.util_echoOptions(opts) writes one line to the command window for
%   every field of the resolved options struct OPTS whose value differs from
%   its default (see DEFAULTOPTIONS), and nothing at all when OPTS is entirely
%   default.  SOLVE calls it after option resolution and immediately before the
%   first iteration whenever Display is not 'off', so the console shows which
%   non-default settings a run is actually using before the iteration table
%   starts.
%
%   The two options that SOLVE resolves from other options -- muMin
%   (0.1*optTol when unset) and compTol (optTol when unset) -- are compared
%   against the same resolved values, so an unset muMin/compTol is never
%   reported as non-default while an explicit override still is.
%
%   The text is written to the command window and, when opts.LogFile is set,
%   appended to that file as well -- the same record in both places, matching
%   how UTIL_LOGGER and DIAGNOSE emit, so a run's log tells the whole story.
%
%   Inputs:
%     opts - resolved options struct (see MAPOPTIONS).
%
%   Outputs:
%     (none) text is written to the command window and optionally the log file.
%
%   See also DEFAULTOPTIONS, MAPOPTIONS, SOLVE, UTIL_LOGGER.

import adamnlopt.*

d = defaultOptions();
% Mirror the two effective defaults that solve() resolves after mapOptions, so
% the comparison is against the values the solver actually runs with: a caller
% who tightens optTol gets the tied muMin/compTol, not the untied defaults.
if isempty(d.muMin),   d.muMin   = 0.1 * opts.optTol; end
if isempty(d.compTol), d.compTol = opts.optTol;       end

names = fieldnames(opts);
rows = {};
for i = 1:numel(names)
    name = names{i};
    if ~isfield(d, name), continue; end
    if sameValue(opts.(name), d.(name)), continue; end
    rows{end+1} = sprintf('  %-30s = %s', name, valueString(opts.(name))); %#ok<AGROW>
end

if isempty(rows)
    return;
end
txt = sprintf('Non-default options in use:\n');
for i = 1:numel(rows)
    txt = [txt sprintf('%s\n', rows{i})]; %#ok<AGROW>
end
txt = [txt sprintf('\n')]; %#ok<AGROW>
fprintf('%s', txt);
if isfield(opts, 'LogFile')
    util_logAppend(opts.LogFile, txt);
end
end

function eq = sameValue(a, b)
%SAMEVALUE  Value equality tolerant of char/string representation differences.
if (ischar(a) || isstring(a)) && (ischar(b) || isstring(b))
    eq = strcmp(char(a), char(b));
else
    eq = isequal(a, b);
end
end

function s = valueString(v)
%VALUESTRING  Single-line rendering of an option value for the echo.
if ischar(v) || isstring(v)
    s = sprintf('''%s''', char(v));
elseif islogical(v)
    if v, s = 'true'; else, s = 'false'; end
elseif isnumeric(v) && isscalar(v)
    s = num2str(v);
elseif isa(v, 'function_handle')
    s = func2str(v);
elseif iscell(v)
    s = cellString(v);
else
    s = mat2str(v);
end
end

function s = cellString(v)
%CELLSTRING  Single-line rendering of a cell-array option value.
%   mat2str cannot render a cell array that contains function handles (or any
%   non-numeric content), which PlotFcn/IterationFcn are allowed to be, so
%   render element-wise: handles as func2str, scalars numerically, and
%   everything else through mat2str.
parts = cell(size(v));
for i = 1:numel(v)
    el = v{i};
    if isa(el, 'function_handle')
        parts{i} = func2str(el);
    elseif ischar(el) || isstring(el)
        parts{i} = sprintf('''%s''', char(el));
    elseif isnumeric(el) && isscalar(el)
        parts{i} = num2str(el);
    elseif islogical(el)
        if el, parts{i} = 'true'; else, parts{i} = 'false'; end
    else
        parts{i} = mat2str(el);
    end
end
s = ['{' strjoin(parts, ', ') '}'];
end
