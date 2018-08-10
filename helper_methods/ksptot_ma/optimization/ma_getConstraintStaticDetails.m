function [unit, lbLim, ubLim, lbVal, ubVal, body, othersc] = ma_getConstraintStaticDetails(type)
%ma_getConstraintStaticDetails Summary of this function goes here
%   Detailed explanation goes here

	switch type
        case 'Body-centric Position (X)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Body-centric Position (Y)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Body-centric Position (Z)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Body-centric Velocity (X)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Body-centric Velocity (Y)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Body-centric Velocity (Z)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Sun-centric Position (X)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Sun-centric Position (Y)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Sun-centric Position (Z)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
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
        case 'Right Asc. of the Asc. Node'
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
        case 'Mean Anomaly'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Universal Time'
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
        case 'Distance to Ref. Celestial Body'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Distance to Ref. Spacecraft'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
%         case 'Distance to Ref. Station'
%             unit = 'km';
%             lbLim = 0;
%             ubLim = Inf;
%             lbVal = 0;
%             ubVal = 0;
%             body = -1;
%             othersc = -1;
        case 'Relative Vel. to Ref. Spacecraft'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Pos. of Ref. Spacecraft (In-Track)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Pos. of Ref. Spacecraft (Cross-Track)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Pos. of Ref. Spacecraft (Radial)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Pos. of Ref. Spacecraft (In-Track; Ref. SC-centered)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Pos. of Ref. Spacecraft (Cross-Track; Ref. SC-centered)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Pos. of Ref. Spacecraft (Radial; Ref. SC-centered)'
            unit = 'km';
            lbLim = -Inf;
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
        case 'Relative SMA of Ref. Spacecraft'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Eccentricity of Ref. Spacecraft'
            unit = ' ';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Inclination of Ref. Spacecraft'
            unit = 'deg';
            lbLim = 0;
            ubLim = 180;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative RAAN of Ref. Spacecraft'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Relative Argument of Periapsis of Ref. Spacecraft'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Central Body ID'
            unit = '';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Liquid Fuel/Ox Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Monopropellant Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Xenon Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Total Spacecraft Mass'
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
        case 'Longitudinal Drift Rate'
            unit = 'degE/hr';
            lbLim = -Inf;
            ubLim = Inf;
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
        case 'Surface Velocity'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Vertical Velocity'
            unit = 'km/s';
            lbLim = -Inf;
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
        case 'Hyperbolic Velocity Unit Vector X'
            unit = ' ';
            lbLim = -1;
            ubLim = 1;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Hyperbolic Velocity Unit Vector Y'
            unit = ' ';
            lbLim = -1;
            ubLim = 1;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Hyperbolic Velocity Unit Vector Z'
            unit = ' ';
            lbLim = -1;
            ubLim = 1;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Hyperbolic Velocity Magnitude'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Hyperbolic Velocity Vector Right Ascension'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Hyperbolic Velocity Vector Declination'
            unit = 'deg';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Solar Beta Angle'
            unit = 'deg';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        case 'Speed of Spacecraft'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
        otherwise
            error(['Unrecongized Constraint Type: ', type]);
	end
end

