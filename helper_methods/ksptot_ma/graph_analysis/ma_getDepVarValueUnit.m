function [depVarValue, depVarUnit, prevDistTraveled, taskStr, refBodyInfo, otherSC, station] = ma_getDepVarValueUnit(i, subLog, taskStr, prevDistTraveled, refBodyId, oscId, stnId, propNames, maData, celBodyData, onlyReturnTaskStr)
%ma_getDepVarValueUnit Summary of this function goes here
%   Detailed explanation goes here
    
    if(~isempty(refBodyId))
        refBodyInfo = getBodyInfoByNumber(refBodyId, celBodyData);
    else
        refBodyInfo = [];
    end
    
    if(~isempty(oscId))
        otherSC = getOtherSCInfoByID(maData, oscId);
    else
        otherSC = [];
    end
    
    if(~isempty(stnId))
        station = getStationInfoByID(maData, stnId);
    else
        station = [];
    end

    if(onlyReturnTaskStr == true)
        depVarValue = NaN;
        depVarUnit = NaN;
        prevDistTraveled = NaN;
        
        return;
    end
    
    switch taskStr
        case 'Universal Time'
            depVarValue = ma_TimeTask(subLog(i,:), 'ut', celBodyData);
            depVarUnit = 'sec';
        case 'Body-centric Position (X)'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'rX', celBodyData);
            depVarUnit = 'km';
        case 'Body-centric Position (Y)'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'rY', celBodyData);
            depVarUnit = 'km';
        case 'Body-centric Position (Z)'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'rZ', celBodyData);
            depVarUnit = 'km';
        case 'Body-centric Velocity (X)'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'vX', celBodyData);
            depVarUnit = 'km/s';
        case 'Body-centric Velocity (Y)'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'vY', celBodyData);
            depVarUnit = 'km/s';
        case 'Body-centric Velocity (Z)'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'vZ', celBodyData);
            depVarUnit = 'km/s';
        case 'Sun-centric Position (X)'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'sunRX', celBodyData);
            depVarUnit = 'km';
        case 'Sun-centric Position (Y)'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'sunRY', celBodyData);
            depVarUnit = 'km';
        case 'Sun-centric Position (Z)'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'sunRZ', celBodyData);
            depVarUnit = 'km';
        case 'Semi-major Axis'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'sma', celBodyData);
            depVarUnit = 'km';
        case 'Eccentricity'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'ecc', celBodyData);
            depVarUnit = '';
        case 'Inclination'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'inc', celBodyData);
            depVarUnit = 'deg';
        case 'Right Asc. of the Asc. Node'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'raan', celBodyData);
            depVarUnit = 'deg';
        case 'Argument of Periapsis'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'arg', celBodyData);
            depVarUnit = 'deg';
        case 'True Anomaly'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'tru', celBodyData);
            depVarUnit = 'deg';
        case 'Mean Anomaly'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'mean', celBodyData);
            depVarUnit = 'deg';
        case 'Orbital Period'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'period', celBodyData);
            depVarUnit = 'sec';
        case 'Radius of Periapsis'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'rPe', celBodyData);
            depVarUnit = 'km';
        case 'Radius of Apoapsis'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'rAp', celBodyData);
            depVarUnit = 'km';
        case 'Altitude of Apoapsis'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'altAp', celBodyData);
            depVarUnit = 'km';
        case 'Altitude of Periapsis'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'altPe', celBodyData);
            depVarUnit = 'km';
        case 'Radius of Spacecraft'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'rNorm', celBodyData);
            depVarUnit = 'km';
        case 'Speed of Spacecraft'
            depVarValue = ma_GAVectorElementsTask(subLog(i,:), 'vNorm', celBodyData);
            depVarUnit = 'km/s';
        case 'Flight Path Angle'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'flightPathAngle', celBodyData);
            depVarUnit = 'km/s';
        case 'Longitude (East)'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'long', celBodyData);
            depVarUnit = 'degE';
        case 'Latitude (North)'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'lat', celBodyData);
            depVarUnit = 'degN';
        case 'Longitudinal Drift Rate'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'driftRate', celBodyData);
            depVarUnit = 'degE/hr';
        case 'Altitude'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'alt', celBodyData);
            depVarUnit = 'km';
        case 'Surface Velocity'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'horzVel', celBodyData);
            depVarUnit = 'km/s';
        case 'Vertical Velocity'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'vertVel', celBodyData);
            depVarUnit = 'km/s';
        case 'Body-Fixed Velocity (X)'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'bodyFixedVx', celBodyData);
            depVarUnit = 'km/s';
        case 'Body-Fixed Velocity (Y)'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'bodyFixedVy', celBodyData);
            depVarUnit = 'km/s';
        case 'Body-Fixed Velocity (Z)'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'bodyFixedVz', celBodyData);
            depVarUnit = 'km/s';
        case 'Body-Fixed Velocity'
            depVarValue = ma_GALongLatAltTasks(subLog(i,:), 'bodyFixedVNorm', celBodyData);
            depVarUnit = 'km/s';
        case 'Solar Beta Angle'
            depVarValue = ma_GAKeplerElementsTask(subLog(i,:), 'betaAngle', celBodyData);
            depVarUnit = 'deg';
        case 'Dynamic Pressure'
            depVarValue = ma_GAAeroTasks(subLog(i,:), 'dynPress', celBodyData);
            depVarUnit = 'kPa';
        case 'Atmospheric Pressure'
            depVarValue = ma_GAAeroTasks(subLog(i,:), 'atmoPress', celBodyData);
            depVarUnit = 'kPa';
        case 'Atmospheric Temperature'
            depVarValue = ma_GAAeroTasks(subLog(i,:), 'atmoTemp', celBodyData);
            depVarUnit = 'K';
        case 'Atmospheric Density'
            depVarValue = ma_GAAeroTasks(subLog(i,:), 'atmoDensity', celBodyData);
            depVarUnit = 'kg/m^3';
        case 'Distance to Ref. Celestial Body'
            depVarValue = ma_GADistToCelBodyTask(subLog(i,:), 'distToCelBody', refBodyInfo, celBodyData);
            depVarUnit = 'km';
        case 'Elevation Angle of Ref. Celestial Body'
            depVarValue = ma_GADistToCelBodyTask(subLog(i,:), 'CelBodyElevation', refBodyInfo, celBodyData);
            depVarUnit = 'deg';
        case 'Distance to Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'distToRefSC',  otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Vel. to Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relVelToCelBody', otherSC, celBodyData);
            depVarUnit = 'km/s';
        case 'Relative Pos. of Ref. Spacecraft (In-Track)'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relPositionInTrack', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Pos. of Ref. Spacecraft (Cross-Track)'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relPositionCrossTrack', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Pos. of Ref. Spacecraft (Radial)'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relPositionRadial', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Pos. of Ref. Spacecraft (In-Track; Ref. SC-centered)'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relPositionInTrackOScCentered', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Pos. of Ref. Spacecraft (Cross-Track; Ref. SC-centered)'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relPositionCrossTrackOScCentered', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Pos. of Ref. Spacecraft (Radial; Ref. SC-centered)'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relPositionRadialOScCentered', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative SMA of Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relSma', otherSC, celBodyData);
            depVarUnit = 'km';
        case 'Relative Eccentricity of Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relEcc', otherSC, celBodyData);
            depVarUnit = '';
        case 'Relative Inclination of Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relInc', otherSC, celBodyData);
            depVarUnit = 'deg';
        case 'Relative RAAN of Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relRaan', otherSC, celBodyData);
            depVarUnit = 'deg';
        case 'Relative Argument of Periapsis of Ref. Spacecraft'
            depVarValue = ma_GADistToRefSCTask(subLog(i,:), 'relArg', otherSC, celBodyData);
            depVarUnit = 'deg';
        case 'Distance to Ref. Station'
            depVarValue = ma_GADistToRefStationTask(subLog(i,:), 'distToRefStn', station, celBodyData);
            depVarUnit = 'km';
        case 'Elevation Angle w.r.t. Ref. Station'
            depVarValue = ma_GAAzElRangeTasks(subLog(i,:), 'Elevation', station, celBodyData);
            depVarUnit = 'deg';
        case 'Distance Traveled'
            if(i>1)
                prevStateLogEntry = subLog(i-1,:);
            else
                prevStateLogEntry = [];
            end
            prevDistTraveled = ma_GADistanceTraveledTask(subLog(i,:), 'Distance Traveled', celBodyData, prevStateLogEntry, prevDistTraveled);
            depVarValue = prevDistTraveled;
            depVarUnit = 'km';
        case 'Line of Sight to Ref. Spacecraft'
            depVarValue = ma_GAEclipseTask(subLog(i,:), 'OtherSC_LOS', otherSC, station, celBodyData);
            depVarUnit = '';
        case 'Line of Sight to Ref. Station'
            depVarValue = ma_GAEclipseTask(subLog(i,:), 'Station_LOS', otherSC, station, celBodyData);
            depVarUnit = '';
        case 'Equinoctial H1'
            depVarValue = ma_GAEquinoctialElementsTask(subLog(i,:), 'H1', celBodyData);
            depVarUnit = '';
        case 'Equinoctial K1'
            depVarValue = ma_GAEquinoctialElementsTask(subLog(i,:), 'K1', celBodyData);
            depVarUnit = '';
        case 'Equinoctial H2'
            depVarValue = ma_GAEquinoctialElementsTask(subLog(i,:), 'H2', celBodyData);
            depVarUnit = '';
        case 'Equinoctial K2'
            depVarValue = ma_GAEquinoctialElementsTask(subLog(i,:), 'K2', celBodyData);
            depVarUnit = '';
        case 'Central Body ID'
            depVarValue = ma_GACentralBodyTasks(subLog(i,:), 'CB_ID', celBodyData);
            depVarUnit = '';
        case [propNames{1}, ' Mass'] %'Liquid Fuel/Ox Mass'
            depVarValue = ma_GASpacecraftMassTasks(subLog(i,:), 'fuelOx', celBodyData);
            depVarUnit = 'tons';
        case [propNames{2}, ' Mass'] %'Monopropellant Mass'
            depVarValue = ma_GASpacecraftMassTasks(subLog(i,:), 'monoprop', celBodyData);
            depVarUnit = 'tons';
        case [propNames{3}, ' Mass'] %'Xenon Mass'
            depVarValue = ma_GASpacecraftMassTasks(subLog(i,:), 'xenon', celBodyData);
            depVarUnit = 'tons';
        case 'Dry Mass'
            depVarValue = ma_GASpacecraftMassTasks(subLog(i,:), 'dry', celBodyData);
            depVarUnit = 'tons';
        case 'Total Spacecraft Mass'
            depVarValue = ma_GASpacecraftMassTasks(subLog(i,:), 'total', celBodyData);
            depVarUnit = 'tons';
        case 'Eclipse'
            depVarValue = ma_GAEclipseTask(subLog(i,:), 'Eclipse', otherSC, station, celBodyData);
            depVarUnit = '';
        case 'Hyperbolic Velocity Unit Vector X'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'X', celBodyData);
            depVarUnit = '';
        case 'Hyperbolic Velocity Unit Vector Y'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'Y', celBodyData);
            depVarUnit = '';
        case 'Hyperbolic Velocity Unit Vector Z'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'Z', celBodyData);
            depVarUnit = '';
        case 'Hyperbolic Velocity Vector Right Ascension'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'RA', celBodyData);
            depVarUnit = '';
        case 'Hyperbolic Velocity Vector Declination'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'Dec', celBodyData);
            depVarUnit = '';
        case 'Hyperbolic Velocity Magnitude'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'mag', celBodyData);
            depVarUnit = 'km/s';
        case 'C3 Energy'
            depVarValue = ma_OutboundHyperVelVectTask(subLog(i,:), 'C3Energy', celBodyData);
            depVarUnit = 'km^2/s^2';
        case 'Mach Number'
            depVarValue = ma_GAAeroTasks(subLog(i,:), 'machNumber', celBodyData);
            depVarUnit = '';
        otherwise
            error('Unknown task "%s"', taskStr);
    end
end