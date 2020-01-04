function [unit, lbLim, ubLim, lbVal, ubVal, body, othersc, usesLbUb, usesCelBody, usesRefSc] = ma_getConstraintStaticDetails(type)
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
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Body-centric Position (Y)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Body-centric Position (Z)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Body-centric Velocity (X)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Body-centric Velocity (Y)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Body-centric Velocity (Z)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Sun-centric Position (X)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Sun-centric Position (Y)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Sun-centric Position (Z)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Semi-major Axis'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Eccentricity'
            unit = ' ';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Inclination'
            unit = 'deg';
            lbLim = 0;
            ubLim = 180;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Right Asc. of the Asc. Node'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Argument of Periapsis'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'True Anomaly'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Mean Anomaly'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Universal Time'
            unit = 'sec';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Radius of Apoapsis'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Radius of Periapsis'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Altitude of Apoapsis'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Altitude of Periapsis'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Radius of Spacecraft'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Distance to Ref. Celestial Body'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Elevation Angle of Ref. Celestial Body'
            unit = 'deg';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Distance to Ref. Spacecraft'
            unit = 'km';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
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
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Pos. of Ref. Spacecraft (In-Track)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Pos. of Ref. Spacecraft (Cross-Track)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Pos. of Ref. Spacecraft (Radial)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Pos. of Ref. Spacecraft (In-Track; Ref. SC-centered)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Pos. of Ref. Spacecraft (Cross-Track; Ref. SC-centered)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Pos. of Ref. Spacecraft (Radial; Ref. SC-centered)'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Rel. Speed of Ref. S/C'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative SMA of Ref. Spacecraft'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Eccentricity of Ref. Spacecraft'
            unit = ' ';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Inclination of Ref. Spacecraft'
            unit = 'deg';
            lbLim = 0;
            ubLim = 180;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative RAAN of Ref. Spacecraft'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Relative Argument of Periapsis of Ref. Spacecraft'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = true;
        case 'Central Body ID'
            unit = '';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = false;
            usesCelBody = true;
            usesRefSc = false;
        case 'Liquid Fuel/Ox Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Monopropellant Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Xenon Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Total Spacecraft Mass'
            unit = 'tons';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Longitude (East)'
            unit = 'degE';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Latitude (North)'
            unit = 'degN';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Longitudinal Drift Rate'
            unit = 'degE/hr';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1; 
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Altitude'
            unit = 'km';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Surface Velocity'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Vertical Velocity'
            unit = 'km/s';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Orbital Period'
            unit = 'sec';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Equinoctial H1'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Equinoctial K1'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Equinoctial H2'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Equinoctial K2'
            unit = ' ';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Hyperbolic Velocity Unit Vector X'
            unit = ' ';
            lbLim = -1;
            ubLim = 1;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Hyperbolic Velocity Unit Vector Y'
            unit = ' ';
            lbLim = -1;
            ubLim = 1;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Hyperbolic Velocity Unit Vector Z'
            unit = ' ';
            lbLim = -1;
            ubLim = 1;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Hyperbolic Velocity Magnitude'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'C3 Energy'
            unit = 'km^2/s^2';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
            
        case 'Hyperbolic Velocity Vector Right Ascension'
            unit = 'deg';
            lbLim = -180;
            ubLim = 360;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Hyperbolic Velocity Vector Declination'
            unit = 'deg';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Solar Beta Angle'
            unit = 'deg';
            lbLim = -90;
            ubLim = 90;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
        case 'Speed of Spacecraft'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Dynamic Pressure'
            unit = 'kPa';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Atmospheric Pressure'
            unit = 'kPa';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Atmospheric Temperature'
            unit = 'K';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Atmospheric Density'
            unit = 'kg/m^3';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Body-Fixed Velocity (X)'
            unit = 'km/s';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Body-Fixed Velocity (Y)'
            unit = 'km/s';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Body-Fixed Velocity (Z)'
            unit = 'km/s';
            lbLim = -Inf;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Body-Fixed Velocity'
            unit = 'km/s';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        case 'Mach Number'
            unit = '';
            lbLim = 0;
            ubLim = Inf;
            lbVal = 0;
            ubVal = 0;
            body = -1;
            othersc = -1;
            
            usesLbUb = true;
            usesCelBody = true;
            usesRefSc = false;
            
        otherwise
            error(['Unrecongized Constraint Type: ', type]);
	end
end

