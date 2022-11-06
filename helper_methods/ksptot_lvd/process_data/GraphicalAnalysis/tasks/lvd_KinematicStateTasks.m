function datapt = lvd_KinematicStateTasks(stateLogEntry, subTask, inFrame)
%lvd_KinematicStateTasks Summary of this function goes here
%   Detailed explanation goes here
    
    cartElem = stateLogEntry.getCartesianElementSetRepresentation();
    cartElem = cartElem.convertToFrame(inFrame);
    
    datapt = -1;
    switch subTask
        % Cartesian Elements
        case 'rVectX'
            rVect = cartElem.rVect;
            datapt = rVect(1);
        case 'rVectY'
            rVect = cartElem.rVect;
            datapt = rVect(2);
        case 'rVectZ'
            rVect = cartElem.rVect;
            datapt = rVect(3);
        case 'vVectX'
            vVect = cartElem.vVect;
            datapt = vVect(1);
        case 'vVectY'
            vVect = cartElem.vVect;
            datapt = vVect(2);
        case 'vVectZ'
            vVect = cartElem.vVect;
            datapt = vVect(3);
        
        % Keplerian Elements
        case 'sma'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.sma;
        case 'ecc'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.ecc;
        case 'inc'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = rad2deg(kepElemSet.inc);
        case 'raan'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = rad2deg(kepElemSet.raan);
        case 'arg'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = rad2deg(kepElemSet.arg);
        case 'tru'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = rad2deg(kepElemSet.tru);
        case 'mean'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = rad2deg(kepElemSet.getMeanAnomaly());
            
        % Geographic Elements
        case 'lat'
            geoElemSet = cartElem.convertToGeographicElementSet();
            datapt = rad2deg(geoElemSet.lat);
        case 'long'
            geoElemSet = cartElem.convertToGeographicElementSet();
            datapt = rad2deg(geoElemSet.long);
        case 'alt'
            geoElemSet = cartElem.convertToGeographicElementSet();
            datapt = geoElemSet.alt;
        case 'velAz'
            geoElemSet = cartElem.convertToGeographicElementSet();
            datapt = rad2deg(geoElemSet.velAz);
        case 'velEl'
            geoElemSet = cartElem.convertToGeographicElementSet();
            datapt = rad2deg(geoElemSet.velEl);
        case 'velMag'
            geoElemSet = cartElem.convertToGeographicElementSet();
            datapt = geoElemSet.velMag;
            
        % Universal Elements - don't need to do Kep repeated elements
        case 'c3'
            univElemSet = cartElem.convertToUniversalElementSet();
            datapt = univElemSet.c3;
        case 'tau'
            univElemSet = cartElem.convertToUniversalElementSet();
            datapt = univElemSet.tau;
            
        % Misc.
        case 'period'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.getPeriod();
        case 'rPe'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.getRadiusPeriapsis();
        case 'rApo'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.getRadiusApoapsis();
        case 'altPeri'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.getAltitudePeriapsis();
        case 'altApo'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.getAltitudeApoapsis();
        case 'H1'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [datapt, ~, ~, ~] = kepElemSet.getEquinoctialElements();
        case 'K1'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, datapt, ~, ~] = kepElemSet.getEquinoctialElements();
        case 'H2'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, ~, datapt, ~] = kepElemSet.getEquinoctialElements();
        case 'K2'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, ~, ~, datapt] = kepElemSet.getEquinoctialElements();
        case 'FPA'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = rad2deg(kepElemSet.getFlightPathAngle());
        case 'hyperVelUnitVectX'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [datapt, ~, ~, ~, ~, ~] = kepElemSet.getOutboundHyperbolicVelocityElements();
        case 'hyperVelUnitVectY'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, datapt, ~, ~, ~, ~] = kepElemSet.getOutboundHyperbolicVelocityElements();
        case 'hyperVelUnitVectZ'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, ~, datapt, ~, ~, ~] = kepElemSet.getOutboundHyperbolicVelocityElements();
        case 'hyperVelUnitVectRA'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, ~, ~, datapt, ~, ~] = kepElemSet.getOutboundHyperbolicVelocityElements();
        case 'hyperVelUnitVectDec'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, ~, ~, ~, datapt, ~] = kepElemSet.getOutboundHyperbolicVelocityElements();
        case 'hyperVelMag'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            [~, ~, ~, ~, ~, datapt] = kepElemSet.getOutboundHyperbolicVelocityElements();
            

        case 'radius'
            datapt = cartElem.getRadiusMagnitude();
        case 'velocity'
            datapt = cartElem.getVelocityMagnitude();
        case 'horzVel'
            [datapt, ~] = cartElem.getHorzVertVelocities();
        case 'vertVel'
            [~, datapt] = cartElem.getHorzVertVelocities();
            
        case 'longDriftRate'
            kepElemSet = cartElem.convertToKeplerianElementSet();
            datapt = kepElemSet.getLongDriftRate() * (3600*180/pi); %convert rad/sec to deg/hr
            
        case 'centralBodyId'
            datapt = stateLogEntry.centralBody.id;

        case 'heightAboveTerrain'
            geoElemSet = cartElem.convertToFrame(stateLogEntry.centralBody.getBodyFixedFrame()).convertToGeographicElementSet();
            lat = geoElemSet.lat;
            lon = geoElemSet.long;
            heightMapGI = stateLogEntry.centralBody.getHeightMap();

            datapt = geoElemSet.alt - heightMapGI(angleNegPiToPi(lat), angleNegPiToPi(lon)); %subtract because it's our alt relative to terrain height
    end
end