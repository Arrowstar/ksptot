classdef KSPTOT_TimeSystem < matlab.mixin.SetGet
    %KSPTOT_TimeSystem Definition of the time/calendar system used for
    %display and day/year conversions in KSPTOT.
    %
    % KSPTOT always propagates spacecraft and celestial bodies in UT
    % seconds.  These constants are used only to convert between UT seconds
    % and the Year/Day/Hours:Minutes:Seconds display shown in the UI, and
    % for input fields that accept days/years.
    %
    % The secondsPerDay and secondsPerYear properties are the source of
    % truth for day/year math.  The hoursPerDay, minPerHr, and secPerMin
    % properties are display/formatting metadata that define how a day is
    % subdivided into hours/minutes/seconds.

    properties
        %system - Base system this time definition represents.  Valid values:
        %   "kerbin_stock" - Stock Kerbin: 6 h days, 426 days/year.
        %   "earth_stock"  - Stock Earth: 24 h days, 365 days/year.
        %   "custom"       - User-defined constants from a [Time] section.
        system char = 'kerbin_stock';

        %secondsPerDay - Number of UT seconds in one day.
        secondsPerDay(1,1) double = 21600;

        %secondsPerYear - Number of UT seconds in one year.
        secondsPerYear(1,1) double = 9201600;

        %hoursPerDay - Number of hours in a day (display metadata).
        hoursPerDay(1,1) double = 6;

        %minutesPerHour - Number of minutes in an hour (display metadata).
        minutesPerHour(1,1) double = 60;

        %secondsPerMinute - Number of seconds in a minute (display metadata).
        secondsPerMinute(1,1) double = 60;
    end

    properties (Dependent)
        %secondsPerHour - Number of UT seconds in one hour (derived).
        secondsPerHour

        %daysPerYear - Number of days in one year (derived).
        daysPerYear
    end

    methods
        function obj = KSPTOT_TimeSystem(system, varargin)
            %KSPTOT_TimeSystem Constructs a time system definition.
            %
            % KSPTOT_TimeSystem()                  -> Stock Kerbin
            % KSPTOT_TimeSystem('kerbin_stock')    -> Stock Kerbin
            % KSPTOT_TimeSystem('earth_stock')     -> Stock Earth
            % KSPTOT_TimeSystem('custom', 'secondsPerDay', 43200, ...
            %                       'secondsPerYear', 16459200) -> Custom
            %
            % Optional name/value pairs override any of the public scalar
            % properties after the system defaults are applied.

            if(nargin >= 1 && ~isempty(system))
                obj.system = lower(system);
            end

            if(mod(numel(varargin),2) ~= 0)
                error('KSPTOT_TimeSystem:BadInput', 'Name/value arguments must come in pairs.');
            end

            provided = struct();
            for(i=1:2:numel(varargin)) %#ok<*NO4LP>
                propName = varargin{i};
                propVal = varargin{i+1};

                if(~isprop(obj,propName))
                    error('KSPTOT_TimeSystem:UnknownProperty', 'Unknown property "%s" for KSPTOT_TimeSystem.', propName);
                end

                provided.(propName) = propVal;
            end

            switch obj.system
                case 'kerbin_stock'
                    if(~isfield(provided,'secondsPerDay'))
                        obj.secondsPerDay = 21600;
                    end

                    if(~isfield(provided,'secondsPerYear'))
                        obj.secondsPerYear = 9201600;
                    end

                    if(~isfield(provided,'hoursPerDay'))
                        obj.hoursPerDay = 6;
                    end

                case 'earth_stock'
                    if(~isfield(provided,'secondsPerDay'))
                        obj.secondsPerDay = 86400;
                    end

                    if(~isfield(provided,'secondsPerYear'))
                        obj.secondsPerYear = 31536000;
                    end

                    if(~isfield(provided,'hoursPerDay'))
                        obj.hoursPerDay = 24;
                    end

                case 'custom'
                    if(~isfield(provided,'secondsPerDay'))
                        warning('KSPTOT_TimeSystem:NoSecondsPerDay', ...
                            'Custom time system specified without secondsPerDay; defaulting to Kerbin stock (21600 s/day).');
                    end

                    if(~isfield(provided,'secondsPerYear'))
                        warning('KSPTOT_TimeSystem:NoSecondsPerYear', ...
                            'Custom time system specified without secondsPerYear; defaulting to Kerbin stock (9201600 s/year).');
                    end

                otherwise
                    error('KSPTOT_TimeSystem:UnknownSystem', ...
                        'Unknown time system "%s".  Valid options are "kerbin_stock", "earth_stock", and "custom".', system);
            end

            %Apply provided property overrides.
            for(i=1:2:numel(varargin))
                obj.(varargin{i}) = varargin{i+1};
            end

            %If hoursPerDay was not explicitly provided, derive it from
            %secondsPerDay so it stays consistent with the day length.
            if(~isfield(provided,'hoursPerDay'))
                obj.hoursPerDay = obj.secondsPerDay / obj.secondsPerHour;
            end

            obj.validateSystem();
        end

        function [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits(obj)
            %getSecondsInVariousTimeUnits Returns the number of seconds in
            %a minute, hour, day, and year for this time system.
            secInMin = obj.secondsPerMinute;
            secInHr = obj.secondsPerHour;
            secInDay = obj.secondsPerDay;
            secInYear = obj.secondsPerYear;
        end

        function val = get.secondsPerHour(obj)
            val = obj.minutesPerHour * obj.secondsPerMinute;
        end

        function val = get.daysPerYear(obj)
            val = obj.secondsPerYear / obj.secondsPerDay;
        end

        function str = getDisplayName(obj)
            %getDisplayName Returns a human-readable name for this system.
            switch lower(obj.system)
                case 'earth_stock'
                    str = 'Earth (Stock)';
                case 'kerbin_stock'
                    str = 'Kerbin (Stock)';
                otherwise
                    str = 'Custom';
            end
        end

        function str = getDescription(obj)
            %getDescription Returns a short human-readable description of
            %the day/year constants in this time system.
            str = sprintf('1 year = %g days, 1 day = %g hours', obj.daysPerYear, obj.hoursPerDay);
        end

        function validateSystem(obj)
            %validateSystem Validates the time system constants.
            if(obj.secondsPerMinute <= 0 || obj.minutesPerHour <= 0 || obj.secondsPerDay <= 0 || obj.secondsPerYear <= 0)
                error('KSPTOT_TimeSystem:NonPositiveValue', 'All time unit values must be positive.');
            end

            if(obj.secondsPerYear < obj.secondsPerDay)
                error('KSPTOT_TimeSystem:BadYearDay', ...
                    'secondsPerYear (%g) must be greater than or equal to secondsPerDay (%g).', obj.secondsPerYear, obj.secondsPerDay);
            end
        end
    end

    methods (Static)
        function obj = kerbinStock()
            %kerbinStock Returns the stock Kerbin time system.
            obj = KSPTOT_TimeSystem('kerbin_stock');
        end

        function obj = earthStock()
            %earthStock Returns the stock Earth time system.
            obj = KSPTOT_TimeSystem('earth_stock');
        end

        function obj = custom(secondsPerDay, secondsPerYear, varargin)
            %custom Creates a custom time system from explicit day/year
            %constants.  Optional name/value pairs (e.g. 'hoursPerDay',
            %'minutesPerHour', 'secondsPerMinute') are passed through.
            if(nargin < 1 || isempty(secondsPerDay))
                secondsPerDay = 21600;
                warning('KSPTOT_TimeSystem:NoSecondsPerDay', ...
                    'Custom time system specified without secondsPerDay; defaulting to Kerbin stock (21600 s/day).');
            end

            if(nargin < 2 || isempty(secondsPerYear))
                secondsPerYear = 9201600;
                warning('KSPTOT_TimeSystem:NoSecondsPerYear', ...
                    'Custom time system specified without secondsPerYear; defaulting to Kerbin stock (9201600 s/year).');
            end

            obj = KSPTOT_TimeSystem('custom', 'secondsPerDay', secondsPerDay, 'secondsPerYear', secondsPerYear, varargin{:});
        end
    end
end