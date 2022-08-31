function datapt = ma_OutboundHyperVelVectTask(stateLogEntry, subTask, celBodyData)
%ma_OutboundHyperVelVectTask Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = stateLogEntry(2:4)';
    vVect = stateLogEntry(5:7)';
    
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    
    if(ecc > 1)
        [~, OUnitVector] = computeHyperSVectOVect(sma, ecc, inc, raan, arg, tru, gmu);
        [vInfRA,vInfDec,~] = cart2sph(OUnitVector(1),OUnitVector(2),OUnitVector(3));
        vInfRA = rad2deg(AngleZero2Pi(vInfRA));
        vInfDec = rad2deg(vInfDec);
        
        switch subTask
            case 'X'
                datapt = OUnitVector(1);
            case 'Y'
                datapt = OUnitVector(2);
            case 'Z'
                datapt = OUnitVector(3);
            case 'mag'
                datapt = sqrt(-gmu/sma);
            case 'RA'
                datapt = vInfRA;
            case 'Dec'
                datapt = vInfDec;
            case 'C3Energy'
                datapt = -gmu/sma;
        end
    else
        switch subTask
            case 'C3Energy'
                datapt = -gmu/sma;
            otherwise
                datapt = 0.0;
        end
    end
end

