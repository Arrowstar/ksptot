function lvPerfTable = getLVPerfTable(lvDef, liftoffUt)
    lvPerfTable = [];
    lvDefCumData = getStageData(lvDef);
    startUt = liftoffUt;
    for(i=1:size(lvDefCumData,1)) %#ok<*NO4LP>
        row = lvDefCumData(i,:);
        coastDur = row(8);
        coastStart = startUt + row(1);
        endUt = startUt + row(1) + coastDur;
        thrust = row(2);
        mdot = row(3);
        massStart = row(4);
        massEnd = row(5);
        dryMassCum = row(6);
        fuMassCum = row(7);
        cDa = row(9);
        
        lvPerfTable(i,:) = [startUt, endUt, thrust, mdot, massStart, massEnd, dryMassCum, fuMassCum, coastStart, cDa]; %#ok<AGROW>
        startUt = endUt;
    end    
    
    lvPerfTable(end+1,:) = lvPerfTable(end,:);
    lvPerfTable(end, 1) = lvPerfTable(end-1, 2);
    lvPerfTable(end, 2) = Inf;
    lvPerfTable(end, 3) = 0.0;
    lvPerfTable(end, 4) = 0.0;    
    lvPerfTable(end, 5) = lvPerfTable(end-1, 6);
    lvPerfTable(end, 6) = lvPerfTable(end, 5);
    lvPerfTable(end, 7) = lvPerfTable(end-1, 7);
    lvPerfTable(end, 8) = 0.0;
    lvPerfTable(end, 9) = Inf;
    lvPerfTable(end, 10) = 0.0;