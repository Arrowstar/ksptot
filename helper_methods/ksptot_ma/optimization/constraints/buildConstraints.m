function [const] = buildConstraints(handles, lbValue, ubValue, eventID, celBodyComboSelected, otherSC, type, lbActive, ubActive)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    selected = celBodyComboSelected;
    if(strcmpi(selected,''))
        bodyInfo.id = -1;
    else
        bodyInfo = celBodyData.(lower(selected));
    end
    
    if(lbActive == false) 
        lbValue = -1E99;
    end
    
    if(ubActive == false)
        ubValue = 1E99;
    end
    
    bodyID = bodyInfo.id;
    switch type
        case 'Semi-major Axis'
            const = @(stateLog) ma_semiMajorAxisConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Eccentricity'
            const = @(stateLog) ma_eccentricityConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Inclination'
            lbValue = deg2rad(lbValue);
            ubValue = deg2rad(ubValue);
            const = @(stateLog) ma_inclinationConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'RAAN'
            lbValue = deg2rad(lbValue);
            ubValue = deg2rad(ubValue);
            const = @(stateLog) ma_raanConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Argument of Periapsis'
            lbValue = deg2rad(lbValue);
            ubValue = deg2rad(ubValue);
            const = @(stateLog) ma_argConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'True Anomaly'
            lbValue = deg2rad(lbValue);
            ubValue = deg2rad(ubValue);
            const = @(stateLog) ma_truConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Universal Time (UT)'
            const = @(stateLog) ma_utConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Radius of Apoapsis'
            const = @(stateLog) ma_rApConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Radius of Periapsis'
            const = @(stateLog) ma_rPeConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Altitude of Apoapsis'
            const = @(stateLog) ma_hApConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Altitude of Periapsis'
            const = @(stateLog) ma_hPeConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Radius of Spacecraft'
            const = @(stateLog) ma_radiusConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Distance to Body'
            const = @(stateLog) ma_distFromBodyConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Distance to Ref. S/C'
            const = @(stateLog) ma_distFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, celBodyData, maData);
        case 'Central Body'
            const = @(stateLog) ma_centralBodyConstraint(stateLog, eventID, bodyID, bodyID, bodyID, celBodyData, maData);
        case 'Liq. Fuel/Ox  Remaining'
            const = @(stateLog) ma_liqFuelOxPropMassConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Monoprop Remaining'
            const = @(stateLog) ma_monoPropMassConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Xenon Remaining'
            const = @(stateLog) ma_XenonPropMassConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Longitude (East)'
            const = @(stateLog) ma_longConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Latitude (North)'
            const = @(stateLog) ma_latConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Altitude'
            const = @(stateLog) ma_altConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Orbital Period'
            const = @(stateLog) ma_orbitPeriodConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Equinoctial H1'
            const = @(stateLog) ma_equiH1Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Equinoctial K1'
            const = @(stateLog) ma_equiK1Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Equinoctial H2'
            const = @(stateLog) ma_equiH2Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        case 'Equinoctial K2'
            const = @(stateLog) ma_equiK2Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
        otherwise
            error(['Unknown constraint of type: ', type]);
    end
end

