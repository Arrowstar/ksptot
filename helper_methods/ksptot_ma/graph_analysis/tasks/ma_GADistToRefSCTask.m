function datapt = ma_GADistToRefSCTask(stateLogEntry, subTask, otherSC, celBodyData)
%ma_GADistToRefSCTask Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    if(isempty(otherSC))
        datapt = -1;
        return;
    end
    
    gmu = bodyInfo.gm;
    rVect = stateLogEntry(2:4)';
    vVect = stateLogEntry(5:7)';

    [sma, ecc, inc, raan, arg, ~] = getKeplerFromState(rVect,vVect,gmu, true);
    
    switch subTask
        case 'distToRefSC'
            dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            datapt = norm(dVect);
            
        case 'relVelToCelBody'
            [~,dVect] = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                        bodyInfo, otherSC, celBodyData, stateLogEntry(5:7)');
            datapt = norm(dVect);
            
        case 'relPositionInTrack'
            rVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            lvlhPosDeputy = computeLvlhCurviPos(stateLogEntry(2:4)', stateLogEntry(5:7)', rVect, bodyInfo.gm);
            datapt = lvlhPosDeputy(2);
            
        case 'relPositionCrossTrack'
            rVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            lvlhPosDeputy = computeLvlhCurviPos(stateLogEntry(2:4)', stateLogEntry(5:7)', rVect, bodyInfo.gm);
            datapt = lvlhPosDeputy(3);
            
        case 'relPositionRadial'
            rVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            lvlhPosDeputy = computeLvlhCurviPos(stateLogEntry(2:4)', stateLogEntry(5:7)', rVect, bodyInfo.gm);
            datapt = lvlhPosDeputy(1);
        
        case 'relPositionInTrackOScCentered'
            rVect = -getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            
            oScBodyInfo = getBodyInfoByNumber(otherSC.parentID, celBodyData);
            [rVectOsc, vVectOsc] = getStateAtTime(otherSC, stateLogEntry(1), oScBodyInfo.gm);
                
            lvlhPosDeputy = computeLvlhCurviPos(rVectOsc, vVectOsc, rVect, oScBodyInfo.gm);
            datapt = lvlhPosDeputy(2);
            
        case 'relPositionCrossTrackOScCentered'
            rVect = -getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            
            oScBodyInfo = getBodyInfoByNumber(otherSC.parentID, celBodyData);
            [rVectOsc, vVectOsc] = getStateAtTime(otherSC, stateLogEntry(1), oScBodyInfo.gm);
                
            lvlhPosDeputy = computeLvlhCurviPos(rVectOsc, vVectOsc, rVect, oScBodyInfo.gm);
            datapt = lvlhPosDeputy(3);
            
        case 'relPositionRadialOScCentered'
            rVect = -getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
                
            oScBodyInfo = getBodyInfoByNumber(otherSC.parentID, celBodyData);
            [rVectOsc, vVectOsc] = getStateAtTime(otherSC, stateLogEntry(1), oScBodyInfo.gm);
                
            lvlhPosDeputy = computeLvlhCurviPos(rVectOsc, vVectOsc, rVect, oScBodyInfo.gm);
            datapt = lvlhPosDeputy(1);
            
        case 'relSma'
            datapt = otherSC.sma - sma;
            
        case 'relEcc'
            datapt = otherSC.ecc - ecc;
            
        case 'relInc'
            datapt = rad2deg(AngleZero2Pi(deg2rad(otherSC.inc - rad2deg(inc))));
            
        case 'relRaan'
            datapt = rad2deg(AngleZero2Pi(deg2rad(otherSC.raan - rad2deg(raan))));
            
        case 'relArg'
            datapt = rad2deg(AngleZero2Pi(deg2rad(otherSC.arg - rad2deg(arg))));
    end
end