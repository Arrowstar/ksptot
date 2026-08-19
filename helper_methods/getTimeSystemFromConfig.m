function [timeSystem] = getTimeSystemFromConfig(appOptions, bodiesIniRows)
%getTimeSystemFromConfig Resolves the active time system for KSPTOT.
%
% Resolution order:
%   1. The [Time] section of time.ini, if that file exists.
%   2. The [Time] section of the active bodies file (the rows passed in
%      bodiesIniRows, or the file referenced by appOptions.ksptot.
%      bodiesinifile, or bodies.ini).
%   3. The legacy appOptions.ksptot.timesystem selection
%      ('Earth'/'Kerbin'/'custom').
%   4. Stock Kerbin defaults.
%
% The return value is always a valid KSPTOT_TimeSystem.
%
% INPUTS
%   appOptions    - Struct/object produced by getAppOptionsFromFile().
%   bodiesIniRows - (Optional) Cell array of INI rows for the active bodies
%                   file (as returned by inifile('readall')).  If omitted,
%                   the bodies file is read from appOptions.ksptot.
%                   bodiesinifile (or bodies.ini).
%
% See also getCustomTimeSystem, parseTimeSystemFromINIRows.

    if(nargin < 2 || isempty(bodiesIniRows))
        bodiesIniRows = [];
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
    if(isempty(bodiesIniRows))
        bodiesIniRows = getActiveBodiesIniRows(appOptions);
    end

    timeSystem = parseTimeSystemFromINIRows(bodiesIniRows);

    if(~isempty(timeSystem))
        return;
    end

    %3. Legacy appOptions selection.
    if(nargin >= 1 && ~isempty(appOptions) && isfield(appOptions,'ksptot') && ...
       isprop(appOptions.ksptot,'timesystem') && ~isempty(appOptions.ksptot.timesystem))

        switch lower(appOptions.ksptot.timesystem)
            case {'earth', 'earth_stock'}
                timeSystem = KSPTOT_TimeSystem('earth_stock');

            case {'kerbin', 'kerbin_stock'}
                timeSystem = KSPTOT_TimeSystem('kerbin_stock');

            case 'custom'
                warning('KSPTOT_TimeSystem:NoCustomDefined', ...
                    'appOptions requests the custom time system but no [Time] section was found in time.ini or the active bodies file.  Defaulting to Kerbin stock time.');
                timeSystem = KSPTOT_TimeSystem('kerbin_stock');

            otherwise
                warning('KSPTOT_TimeSystem:UnknownAppOptionsSystem', ...
                    'Unknown time system "%s" in appOptions.ini; defaulting to Kerbin stock time.', appOptions.ksptot.timesystem);
                timeSystem = KSPTOT_TimeSystem('kerbin_stock');
        end

    else
        %4. Stock Kerbin defaults.
        timeSystem = KSPTOT_TimeSystem('kerbin_stock');
    end
end

function [iniRows] = getActiveBodiesIniRows(appOptions)
%getActiveBodiesIniRows Reads the active bodies INI file into rows.

    iniRows = [];

    if(nargin >= 1 && ~isempty(appOptions) && isfield(appOptions,'ksptot') && ...
       isprop(appOptions.ksptot,'bodiesinifile') && ~isempty(appOptions.ksptot.bodiesinifile) && ...
       exist(appOptions.ksptot.bodiesinifile,'file'))

        filePath = appOptions.ksptot.bodiesinifile;
    else
        filePath = 'bodies.ini';
    end

    if(exist(filePath,'file'))
        iniRows = inifile(filePath,'readall');
    end
end