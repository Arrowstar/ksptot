function [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits()
%getSecondsInVariousTimeUnits Returns the number of seconds in a minute,
%hour, day, and year for the currently active time system.
%
% The active time system is set in the global variable ksptot_TimeSystem
% (a KSPTOT_TimeSystem object).  If that is not set, this function falls
% back to the legacy global options_UseEarthTimeSystem, and finally to
% stock Kerbin time.

    global ksptot_TimeSystem options_UseEarthTimeSystem;

    if(~isempty(ksptot_TimeSystem) && isa(ksptot_TimeSystem,'KSPTOT_TimeSystem'))
        [secInMin, secInHr, secInDay, secInYear] = ksptot_TimeSystem.getSecondsInVariousTimeUnits();

    elseif(~isempty(options_UseEarthTimeSystem) && options_UseEarthTimeSystem == true)
        secInMin = 60;
        secInHr = 60*secInMin;
        secInDay = 24*secInHr;
        secInYear = 365*secInDay;

    else
        secInMin = 60;
        secInHr = 60*secInMin;
        secInDay = 6*secInHr;
        secInYear = 426*secInDay;
    end
end