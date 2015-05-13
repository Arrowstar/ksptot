function [unit, lbLim, ubLim, lbVal, ubVal, body, othersc] = ma_getConstraintStaticDetails(type)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

	switch type
        case 'Semi-major Axis'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Eccentricity'
            unit = ' ';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Inclination'
            unit = 'deg';
            lbLim = 0;
            ubLim = 180;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'RAAN'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Argument of Periapsis'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'True Anomaly'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Universal Time (UT)'
            unit = 'sec';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Radius of Apoapsis'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Radius of Periapsis'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Altitude of Apoapsis'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Altitude of Periapsis'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Radius of Spacecraft'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Distance to Body'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Distance to Ref. S/C'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Rel. Speed of Ref. S/C'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Central Body'
            unit = '';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Liq. Fuel/Ox  Remaining'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Monoprop Remaining'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Xenon Remaining'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Longitude (East)'
            unit = 'degE';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Latitude (North)'
            unit = 'degN';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Altitude'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Orbital Period'
            unit = 'sec';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Equinoctial H1'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Equinoctial K1'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Equinoctial H2'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Equinoctial K2'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        otherwise
            error(['Unrecongized Constraint Type: ', type]);
	end
end

