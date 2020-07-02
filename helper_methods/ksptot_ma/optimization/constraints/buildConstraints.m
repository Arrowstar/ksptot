function [const] = buildConstraints(maData, celBodyData, lbValue, ubValue, eventID, celBodyComboSelected, otherSC, type, lbActive, ubActive)
%buildConstraints Summary of this function goes here
%   Detailed explanation goes here
%     maData = getappdata(handles.ma_MainGUI,'ma_data');
%     celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    selected = celBodyComboSelected;
    if(strcmpi(selected,''))
        bodyInfo.id = -1;
    else
        bodyInfo = celBodyData.(strtrim(lower(selected)));
    end
    
    if(lbActive == false) 
        lbValue = -realmax;
    end
    
    if(ubActive == false)
        ubValue = realmax;
    end
    
    taskStr = type;
    refBodyId = bodyInfo.id;
    refOtherScId = otherSC.id;
    refStationId = -1; %need to build a constraint that actually uses stations first
    
    propNames = maData.spacecraft.propellant.names;
    for(i=1:length(propNames)) %#ok<*NO4LP>
        propNames{i} = sprintf('%s Mass',propNames{i});
    end
    
    funcHandle = @(stateLogRow, onlyReturnTaskStr, maData) ma_getDepVarValueUnit(1, stateLogRow, taskStr, 0, refBodyId, refOtherScId, refStationId, propNames, maData, celBodyData, onlyReturnTaskStr);
    const = @(stateLog) ma_genericConstraint(stateLog, eventID, funcHandle, lbValue, ubValue, refBodyId, celBodyData, maData, taskStr);

%     switch type
%         case 'Semi-major Axis'
%             const = @(stateLog) ma_semiMajorAxisConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Eccentricity'
%             const = @(stateLog) ma_eccentricityConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Inclination'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_inclinationConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'RAAN'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_raanConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Argument of Periapsis'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_argConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'True Anomaly'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_truConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Universal Time (UT)'
%             const = @(stateLog) ma_utConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Radius of Apoapsis'
%             const = @(stateLog) ma_rApConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Radius of Periapsis'
%             const = @(stateLog) ma_rPeConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Altitude of Apoapsis'
%             const = @(stateLog) ma_hApConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Altitude of Periapsis'
%             const = @(stateLog) ma_hPeConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Radius of Spacecraft'
%             const = @(stateLog) ma_radiusConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Distance to Body'
%             const = @(stateLog) ma_distFromBodyConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Distance to Ref. S/C'
%             const = @(stateLog) ma_distFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, celBodyData, maData);
%         case 'Relative Vel. to Ref. Spacecraft'
%             const = @(stateLog) ma_relVelocityFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, celBodyData, maData);
%         case 'Relative Pos. of Ref. Spacecraft (In-Track)'
%             const = @(stateLog) ma_progradeDistFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'relPositionInTrack', celBodyData, maData);
%         case 'Relative Pos. of Ref. Spacecraft (Cross-Track)'
%             const = @(stateLog) ma_normalDistFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'relPositionCrossTrack', celBodyData, maData);
%         case 'Relative Pos. of Ref. Spacecraft (Radial)'
%             const = @(stateLog) ma_radialDistFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'relPositionRadial', celBodyData, maData);
%         case 'Relative Pos. of Ref. Spacecraft (In-Track; Ref. SC-centered)'
%             const = @(stateLog) ma_progradeDistFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'relPositionInTrackOScCentered', celBodyData, maData);
%         case 'Relative Pos. of Ref. Spacecraft (Cross-Track; Ref. SC-centered)'
%             const = @(stateLog) ma_normalDistFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'relPositionCrossTrackOScCentered', celBodyData, maData);
%         case 'Relative Pos. of Ref. Spacecraft (Radial; Ref. SC-centered)'
%             const = @(stateLog) ma_radialDistFromOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'relPositionRadialOScCentered', celBodyData, maData);
%         case 'Relative SMA of Ref. Spacecraft'
%             const = @(stateLog) ma_relOrbitParamsOfOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'sma', celBodyData, maData);
%         case 'Relative Eccentricity of Ref. Spacecraft'
%             const = @(stateLog) ma_relOrbitParamsOfOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'ecc', celBodyData, maData);
%         case 'Relative Inclination of Ref. Spacecraft'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_relOrbitParamsOfOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'inc', celBodyData, maData);
%         case 'Relative RAAN of Ref. Spacecraft'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_relOrbitParamsOfOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'raan', celBodyData, maData);
%         case 'Relative Argument of Periapsis of Ref. Spacecraft'
%             lbValue = deg2rad(lbValue);
%             ubValue = deg2rad(ubValue);
%             const = @(stateLog) ma_relOrbitParamsOfOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSC.id, 'arg', celBodyData, maData);
%         case 'Central Body'
%             const = @(stateLog) ma_centralBodyConstraint(stateLog, eventID, bodyID, bodyID, bodyID, celBodyData, maData);
%         case 'Liq. Fuel/Ox  Remaining'
%             const = @(stateLog) ma_liqFuelOxPropMassConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Monoprop Remaining'
%             const = @(stateLog) ma_monoPropMassConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Xenon Remaining'
%             const = @(stateLog) ma_XenonPropMassConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Longitude (East)'
%             const = @(stateLog) ma_longConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Latitude (North)'
%             const = @(stateLog) ma_latConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Longitudinal Drift Rate'
%             const = @(stateLog) ma_driftRateConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Altitude'
%             const = @(stateLog) ma_altConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Surface Velocity'
%             const = @(stateLog) ma_surfaceVelConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Vertical Velocity'
%             const = @(stateLog) ma_verticalVelConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Orbital Period'
%             const = @(stateLog) ma_orbitPeriodConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Equinoctial H1'
%             const = @(stateLog) ma_equiH1Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Equinoctial K1'
%             const = @(stateLog) ma_equiK1Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Equinoctial H2'
%             const = @(stateLog) ma_equiH2Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Equinoctial K2'
%             const = @(stateLog) ma_equiK2Constraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData);
%         case 'Hyperbolic Velocity Unit Vector X'
%             const = @(stateLog) ma_OutboundHyperVelVectConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData, 'x');
%         case 'Hyperbolic Velocity Unit Vector Y'
%             const = @(stateLog) ma_OutboundHyperVelVectConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData, 'y');
%         case 'Hyperbolic Velocity Unit Vector Z'
%             const = @(stateLog) ma_OutboundHyperVelVectConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData, 'z');
%         case 'Hyperbolic Velocity Magnitude'
%             const = @(stateLog) ma_OutboundHyperVelVectConstraint(stateLog, eventID, lbValue, ubValue, bodyID, celBodyData, maData, 'mag');
%         otherwise
%             error(['Unknown constraint of type: ', type]);
%     end
end

