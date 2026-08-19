function [timeSystem] = getCustomTimeSystem(appOptions)
%getCustomTimeSystem Returns the custom time system defined by the
%configuration files, or [] if none is defined.
%
% A custom time system is considered "defined" when a [Time] section is
% present in time.ini or in the active bodies file.  Resolution order:
%   1. time.ini [Time] section.
%   2. The active bodies file's [Time] section (referenced by
%      appOptions.ksptot.bodiesinifile, or bodies.ini).
%
% This function is used by the UI to enable/disable the "Use Custom Time"
% menu item and to activate the custom system when selected.
%
% INPUTS
%   appOptions - (Optional) Struct/object produced by getAppOptionsFromFile().
%
% See also getTimeSystemFromConfig, parseTimeSystemFromINIRows.

    if(nargin < 1)
        appOptions = [];
    end

    %1. time.ini
    if(exist('time.ini','file'))
        timeIniRows = inifile('time.ini','readall');
        timeSystem = parseTimeSystemFromINIRows(timeIniRows);

        if(~isempty(timeSystem))
            return;
        end
    end

    %2. Active bodies file [Time] section.
    bodiesIniRows = [];

    if(~isempty(appOptions) && isfield(appOptions,'ksptot') && ...
       isprop(appOptions.ksptot,'bodiesinifile') && ~isempty(appOptions.ksptot.bodiesinifile) && ...
       exist(appOptions.ksptot.bodiesinifile,'file'))

        bodiesIniRows = inifile(appOptions.ksptot.bodiesinifile,'readall');
    elseif(exist('bodies.ini','file'))
        bodiesIniRows = inifile('bodies.ini','readall');
    end

    timeSystem = parseTimeSystemFromINIRows(bodiesIniRows);
end