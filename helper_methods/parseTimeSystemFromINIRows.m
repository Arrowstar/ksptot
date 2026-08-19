function [timeSystem] = parseTimeSystemFromINIRows(iniRows)
%parseTimeSystemFromINIRows Parses a [Time] section from a cell array of
%INI rows (as returned by inifile('readall')) into a KSPTOT_TimeSystem.
%
% Returns [] if the rows do not contain a [Time] section.
%
% Supported fields (all optional except that a "custom" system should
% provide secondsPerDay and secondsPerYear):
%   system           = kerbin_stock | earth_stock | custom
%   secondsPerDay    = number of UT seconds in one day
%   secondsPerYear   = number of UT seconds in one year
%   hoursPerDay      = number of hours in a day (display metadata)
%   minutesPerHour   = number of minutes in an hour (display metadata)
%   secondsPerMinute = number of seconds in a minute (display metadata)
%
% See also getTimeSystemFromConfig, getCustomTimeSystem.

    timeSystem = [];

    if(isempty(iniRows))
        return;
    end

    sectionCol = lower(matlab.lang.makeValidName(iniRows(:,1)));
    tf = strcmpi(sectionCol,'time');

    if(~any(tf))
        return;
    end

    rows = iniRows(tf,:);

    system = '';
    secondsPerDay = [];
    secondsPerYear = [];
    hoursPerDay = [];
    minutesPerHour = [];
    secondsPerMinute = [];

    for(i=1:size(rows,1)) %#ok<*NO4LP>
        key = lower(matlab.lang.makeValidName(rows{i,3}));
        rawVal = rows{i,4};

        if(checkStrIsNumeric(rawVal))
            entry = str2double(rawVal);
        else
            entry = rawVal;
        end

        switch key
            case 'system'
                system = strtrim(lower(entry));

            case 'secondsperday'
                secondsPerDay = entry;

            case 'secondsperyear'
                secondsPerYear = entry;

            case 'hoursperday'
                hoursPerDay = entry;

            case 'minutesperhour'
                minutesPerHour = entry;

            case 'secondsperminute'
                secondsPerMinute = entry;
        end
    end

    if(isempty(system))
        %A [Time] section exists but no system was declared.  Treat it as
        %a custom definition.
        system = 'custom';
    end

    switch system
        case {'kerbin', 'kerbin_stock'}
            system = 'kerbin_stock';
        case {'earth', 'earth_stock'}
            system = 'earth_stock';
        case 'custom'
            %Intentionally left as-is.
        otherwise
            warning('KSPTOT_TimeSystem:UnknownSystem', ...
                'Unknown time system "%s" in [Time] section; defaulting to kerbin_stock.', system);
            system = 'kerbin_stock';
    end

    kvPairs = {};
    if(~isempty(secondsPerDay))
        kvPairs = [kvPairs, {'secondsPerDay', secondsPerDay}];
    end
    if(~isempty(secondsPerYear))
        kvPairs = [kvPairs, {'secondsPerYear', secondsPerYear}];
    end
    if(~isempty(hoursPerDay))
        kvPairs = [kvPairs, {'hoursPerDay', hoursPerDay}];
    end
    if(~isempty(minutesPerHour))
        kvPairs = [kvPairs, {'minutesPerHour', minutesPerHour}];
    end
    if(~isempty(secondsPerMinute))
        kvPairs = [kvPairs, {'secondsPerMinute', secondsPerMinute}];
    end

    timeSystem = KSPTOT_TimeSystem(system, kvPairs{:});
end