classdef LaunchVehicle < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    events
        StageAdded
        StageDeleted
        EngineAdded
        EngineDeleted
        TankAdded
        TankDeleted
        EpsSinkAdded
        EpsSinkDeleted
        EpsSrcAdded
        EpsSrcDeleted
        EpsStorageAdded
        EpsStorageDeleted
    end
    
    properties
        stages LaunchVehicleStage
        engineTankConns EngineToTankConnection
        tankToTankConns TankToTankConnection
        stopwatches LaunchVehicleStopwatch
        extrema LaunchVehicleExtrema
        calcObjs AbstractLaunchVehicleCalculusCalc
        
        tankTypes TankFluidTypeSet
        
        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicle(lvdData)
            obj.lvdData = lvdData;
            
            tankTypeSet = TankFluidTypeSet.getDefaultFluidTypeSet();
            obj.tankTypes = tankTypeSet.copy();
        end
                                
        function lvSummStr = getLvSummaryStr(obj)
            lvSummStr = {};
            
            dryMass = 0;
            propMass = 0;
            totalMass = 0;
            
            for(i=1:length(obj.stages))
                dryMass = dryMass + obj.stages(i).getStageDryMass();
                propMass = propMass + obj.stages(i).getStageInitPropMass();
                totalMass = totalMass + obj.stages(i).getStageInitTotalMass();
            end
            
            lvSummStr{end+1} = 'Launch Vehicle Configuration Summary';
            lvSummStr{end+1} = '----------------------------------------------------------------------------------------';
            lvSummStr{end+1} = sprintf('Launch Vehicle (Dry Mass = %.3f mT, Prop Mass = %.3f mT, Total = %.3f mT)', dryMass, propMass, totalMass);
            
            for(i=1:length(obj.stages))
                lvSummStr = horzcat(lvSummStr, obj.stages(i).getStageSummaryStr()); %#ok<AGROW>
            end
            lvSummStr = horzcat(lvSummStr,newline);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Stages
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addStage(obj, stage)
            obj.stages(end+1) = stage;
            
            notify(obj,'StageAdded',StageAddedDeletedEventData(stage));
        end
        
        function removeStage(obj, stage)
            obj.stages([obj.stages] == stage) = [];
            
            for(i=1:length(stage.tanks))
                obj.removeAllEngineToTanksConnsWithTank(stage.tanks(i));
                notify(obj,'TankDeleted',TankAddedDeletedEventData(stage.tanks(i)));
            end
            
            for(i=1:length(stage.engines))
                obj.removeAllEngineToTanksConnsWithEngine(stage.engines(i));
                notify(obj,'EngineDeleted',EngineAddedDeletedEventData(stage.engines(i)));
            end
                        
            for(i=1:length(stage.powerSrcs))
                notify(obj,'EpsSrcDeleted',EpsSrcAddedDeletedEventData(stage.powerSrcs(i)));
            end
            
            for(i=1:length(stage.powerSinks))
                notify(obj,'EpsSinkDeleted',EpsSinkAddedDeletedEventData(stage.powerSinks(i)));
            end
            
            for(i=1:length(stage.powerStorages))
                notify(obj,'EpsStorageDeleted',EpsStorageAddedDeletedEventData(stage.powerStorages(i)));
            end           
            
            notify(obj,'StageDeleted',StageAddedDeletedEventData(stage));
        end
        
        function stage = getStageForInd(obj, ind)
            stage = LaunchVehicleStage.empty(0,1);
            
            if(ind >= 1 && ind <= length(obj.stages))
                stage = obj.stages(ind);
            end
        end
        
        function ind = getIndOfStage(obj, stage)
            ind = find([obj.stages] == stage,1,'first');
        end
        
        function numStages = getNumStages(obj)
            numStages = length(obj.stages);
        end
        
        function moveStageUp(obj, stage)
            ind = obj.getIndOfStage(stage);
            
            if(ind > 1)
                obj.stages([ind,ind-1]) = obj.stages([ind-1,ind]);
            end
        end
        
        function moveStageDown(obj, stage)
            ind = obj.getIndOfStage(stage);
            
            if(ind < obj.getNumStages())
                obj.stages([ind+1,ind]) = obj.stages([ind,ind+1]);
            end
        end
        
        function [stagesListStr, stages] = getStagesListBoxStr(obj)
            stagesListStr = {};
            stages = LaunchVehicleStage.empty(1,0);
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                stagesListStr{end+1} = obj.stages(i).name; %#ok<AGROW>
                stages(end+1) = obj.stages(i); %#ok<AGROW>
            end
            
            if(isempty(stagesListStr))
                stagesListStr{end+1} = '';
            end
        end
        
        function [stagesGAStr, stages] = getStagesGraphAnalysisTaskStrs(obj)
            [~, stages] = obj.getStagesListBoxStr();
            
            stagesGAStr = cell(1,2*length(stages));
            A = length(stages);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(stages))
                stagesGAStr{1+(i-1)*2} = sprintf(sprintf('Stage %s Dry Mass - "%s"',formSpec, stages(i).name), i);
                stagesGAStr{2*i} = sprintf(sprintf('Stage %s Active State - "%s"',formSpec, stages(i).name), i);
            end
        end
        
        function ind = getListBoxIndForStage(obj, stage)
            ind = find(obj.stages == stage);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Tanks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
        function [tanksListStr, tanks] = getTanksListBoxStr(obj)
            tanksListStr = {};
            tanks = LaunchVehicleTank.empty(1,0);
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                for(j=1:length(obj.stages(i).tanks))
                    tanksListStr{end+1} = obj.stages(i).tanks(j).name; %#ok<AGROW>
                    tanks(end+1) = obj.stages(i).tanks(j); %#ok<AGROW>
                end
            end
            
            if(isempty(tanksListStr))
                tanksListStr{end+1} = '';
            end
        end
        
        function moveTankToStage(obj, tank, newStage)
            for(i=1:length(obj.stages))
                stage = obj.stages(i);
                stage.tanks([stage.tanks] == tank) = [];
            end
            
            newStage.tanks(end+1) = tank;
            tank.stage = newStage;
        end
        
        function [tanksGAStr, tanks] = getTanksGraphAnalysisTaskStrs(obj)
            [~, tanks] = obj.getTanksListBoxStr();
            
            tanksGAStr = cell(1,2*length(tanks));
            A = length(tanks);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(tanks))
                tanksGAStr{i} = sprintf(sprintf('Tank %s Mass - "%s"',formSpec, tanks(i).name), i);
            end
            
            tI = 1;
            for(i=length(tanks)+1:2*length(tanks))
                tanksGAStr{i} = sprintf(sprintf('Tank %s Mass Flow Rate - "%s"',formSpec, tanks(tI).name), tI);
                tI = tI + 1;
            end
        end
        
        function ind = getListBoxIndForTank(obj, tank)
            [~, tanks] = obj.getTanksListBoxStr();
            ind = find([tanks] == tank, 1, 'first'); %#ok<NBRAK>
        end
        
        function tank = getTankForInd(obj, ind)
            [~, tanks] = obj.getTanksListBoxStr();
            tank = LaunchVehicleTank.empty(1,0);

            if(ind >= 1 && ind <= length(tanks))
                tank = tanks(ind);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Engines
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function [enginesListStr, engines] = getEnginesListBoxStr(obj)
            enginesListStr = {};
            engines = LaunchVehicleEngine.empty(1,0);
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                for(j=1:length(obj.stages(i).engines))
                    enginesListStr{end+1} = obj.stages(i).engines(j).name; %#ok<AGROW>
                    engines(end+1) = obj.stages(i).engines(j); %#ok<AGROW>
                end
            end
            
            if(isempty(enginesListStr))
                enginesListStr{end+1} = '';
            end
        end
        
        function moveEngineToStage(obj, engine, newStage)
            for(i=1:length(obj.stages))
                stage = obj.stages(i);
                stage.engines([stage.engines] == engine) = [];
            end
            
            newStage.engines(end+1) = engine;
            engine.stage = newStage;
        end
    
        function [engineGAStr, engines] = getEnginesGraphAnalysisTaskStrs(obj)
            [~, engines] = obj.getEnginesListBoxStr();
            
            engineGAStr = cell(1,length(engines));
            A = length(engines);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(engines))
                engineGAStr{i} = sprintf(sprintf('Engine %s Active State - "%s"',formSpec, engines(i).name), i);
            end
        end
        
        function engine = getEngineForInd(obj, ind)
            [~, engines] = obj.getEnginesListBoxStr();
            engine = LaunchVehicleEngine.empty(1,0);

            if(ind >= 1 && ind <= length(engines))
                engine = engines(ind);
            end
        end
        
        function ind = getListBoxIndForEngine(obj, engine)
            [~, engines] = obj.getEnginesListBoxStr();
            ind = find([engines] == engine, 1, 'first'); %#ok<NBRAK>
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Electrical Power Sinks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function [powerSinkListStr, powerSinks] = getPowerSinksListBoxStr(obj)
            powerSinkListStr = {};
            powerSinks = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                for(j=1:length(obj.stages(i).powerSinks))
                    powerSinkListStr{end+1} = obj.stages(i).powerSinks(j).getName(); %#ok<AGROW>
                    powerSinks(end+1) = obj.stages(i).powerSinks(j); %#ok<AGROW>
                end
            end
            
            if(isempty(powerSinkListStr))
                powerSinkListStr{end+1} = '';
            end
        end
        
        function movePwrSinkToStage(obj, sink, newStage)
            for(i=1:length(obj.stages))
                stage = obj.stages(i);
                stage.powerSinks([stage.powerSinks] == sink) = [];
            end
            
            newStage.powerSinks(end+1) = sink;
            sink.stage = newStage;
        end
    
        function [powerSinkGAStr, powerSinks] = getPowerSinksGraphAnalysisTaskStrs(obj)
            [~, powerSinks] = obj.getPowerSinksListBoxStr();
            
            powerSinkGAStr = cell(1,length(powerSinks));
            A = length(powerSinks);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(powerSinks))
                powerSinkGAStr{i} = sprintf(sprintf('Power Sink %s Active State - "%s"',formSpec, powerSinks(i).getName()), i);
            end
            
            for(i=1:length(powerSinks))
                powerSinkGAStr{length(powerSinks) + i} = sprintf(sprintf('Power Sink %s Discharge Rate - "%s"',formSpec, powerSinks(i).getName()), i);
            end
        end
        
        function powerSink = getPowerSinkForInd(obj, ind)
            [~, powerSinks] = obj.getPowerSinksListBoxStr();
            powerSink = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);

            if(ind >= 1 && ind <= length(powerSinks))
                powerSink = powerSinks(ind);
            end
        end
        
        function ind = getListBoxIndForPowerSink(obj, powerSink)
            [~, powerSinks] = obj.getPowerSinksListBoxStr();
            ind = find([powerSinks] == powerSink, 1, 'first'); %#ok<NBRAK>
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Electrical Power Sources
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function [powerSrcListStr, powerSrcs] = getPowerSrcsListBoxStr(obj)
            powerSrcListStr = {};
            powerSrcs = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                for(j=1:length(obj.stages(i).powerSrcs))
                    powerSrcListStr{end+1} = obj.stages(i).powerSrcs(j).getName(); %#ok<AGROW>
                    powerSrcs(end+1) = obj.stages(i).powerSrcs(j); %#ok<AGROW>
                end
            end
            
            if(isempty(powerSrcListStr))
                powerSrcListStr{end+1} = '';
            end
        end
        
        function movePwrSrcToStage(obj, src, newStage)
            for(i=1:length(obj.stages))
                stage = obj.stages(i);
                stage.powerSrcs([stage.powerSrcs] == src) = [];
            end
            
            newStage.powerSrcs(end+1) = src;
            src.stage = newStage;
        end
    
        function [powerSrcsGAStr, powerSrcs] = getPowerSrcsGraphAnalysisTaskStrs(obj)
            [~, powerSrcs] = obj.getPowerSrcsListBoxStr();
            
            powerSrcsGAStr = cell(1,length(powerSrcs));
            A = length(powerSrcs);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(powerSrcs))
                powerSrcsGAStr{i} = sprintf(sprintf('Power Source %s Active State - "%s"',formSpec, powerSrcs(i).getName()), i);
            end
            
            for(i=1:length(powerSrcs))
                powerSrcsGAStr{length(powerSrcs) + i} = sprintf(sprintf('Power Source %s Charge Rate - "%s"',formSpec, powerSrcs(i).getName()), i);
            end
        end
        
        function powerSrc = getPowerSrcForInd(obj, ind)
            [~, powerSrcs] = obj.getPowerSrcsListBoxStr();
            powerSrc = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);

            if(ind >= 1 && ind <= length(powerSrcs))
                powerSrc = powerSrcs(ind);
            end
        end
        
        function ind = getListBoxIndForPowerSrc(obj, powerSrc)
            [~, powerSrcs] = obj.getPowerSrcsListBoxStr();
            ind = find([powerSrcs] == powerSrc, 1, 'first'); %#ok<NBRAK>
        end    
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Electrical Power Storage
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function [powerStoragesListStr, powerStorages] = getPowerStoragesListBoxStr(obj)
            powerStoragesListStr = {};
            powerStorages = AbstractLaunchVehicleElectricalPowerStorage.empty(1,0);
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                for(j=1:length(obj.stages(i).powerStorages))
                    powerStoragesListStr{end+1} = obj.stages(i).powerStorages(j).getName(); %#ok<AGROW>
                    powerStorages(end+1) = obj.stages(i).powerStorages(j); %#ok<AGROW>
                end
            end
            
            if(isempty(powerStoragesListStr))
                powerStoragesListStr{end+1} = '';
            end
        end
        
        function movePwrStorageToStage(obj, storage, newStage)
            for(i=1:length(obj.stages))
                stage = obj.stages(i);
                stage.powerStorages([stage.powerStorages] == storage) = [];
            end
            
            newStage.powerStorages(end+1) = storage;
            storage.stage = newStage;
        end
    
        function [pwrStorageGAStr, powerStorages] = getPowerStorageGraphAnalysisTaskStrs(obj)
            [~, powerStorages] = obj.getPowerStoragesListBoxStr();
            
            pwrStorageGAStr = cell(1,2*length(powerStorages));
            A = length(powerStorages);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(powerStorages))
                pwrStorageGAStr{i} = sprintf(sprintf('Power Storage %s Active State - "%s"',formSpec, powerStorages(i).getName()), i);
            end
            
            for(i=1:length(powerStorages))
                pwrStorageGAStr{length(powerStorages) + i} = sprintf(sprintf('Power Storage %s State of Charge - "%s"',formSpec, powerStorages(i).getName()), i);
            end
        end
        
        function powerStorage = getPowerStorageForInd(obj, ind)
            [~, powerStorages] = obj.getPowerStoragesListBoxStr();
            powerStorage = AbstractLaunchVehicleElectricalPowerStorage.empty(1,0);

            if(ind >= 1 && ind <= length(powerStorages))
                powerStorage = powerStorages(ind);
            end
        end
        
        function ind = getListBoxIndForPowerStorage(obj, powerStorage)
            [~, powerStorages] = obj.getPowerStoragesListBoxStr();
            ind = find([powerStorages] == powerStorage, 1, 'first'); %#ok<NBRAK>
        end  
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Stopwatches
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addStopwatch(obj, sw)
            obj.stopwatches(end+1) = sw;
        end
        
        function removeStopwatch(obj, sw)
            obj.stopwatches([obj.stopwatches] == sw) = [];
        end
        
        function [swListStr, stopwatches] = getStopwatchesListBoxStr(obj)
            stopwatches = obj.stopwatches;
            swListStr = cell(size(obj.stopwatches));
            
            for(i=1:length(obj.stopwatches))
                swListStr{i} = obj.stopwatches(i).name;
            end
        end
        
        function ind = getListBoxIndForStopwatch(obj, stopwatch)
            [~, sws] = obj.getStopwatchesListBoxStr();
            ind = find(sws == stopwatch, 1, 'first'); 
        end
        
        function stopwatch = getStopwatchForInd(obj, ind)
            [~, sws] = obj.getStopwatchesListBoxStr();
            stopwatch = LaunchVehicleStopwatch.empty(1,0);

            if(ind >= 1 && ind <= length(sws))
                stopwatch = sws(ind);
            end
        end
        
        function [stopwatchGAStr, stopwatches] = getStopwatchGraphAnalysisTaskStrs(obj)
            [~, stopwatches] = obj.getStopwatchesListBoxStr();
            
            stopwatchGAStr = cell(1,length(stopwatches));
            A = length(stopwatches);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(stopwatches))
                stopwatchGAStr{i} = sprintf(sprintf('Stopwatch %s Value - "%s"',formSpec, stopwatches(i).name), i);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Extrema
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addExtremum(obj, ex)
            obj.extrema(end+1) = ex;
        end
        
        function removeExtremum(obj, ex)
            obj.extrema([obj.extrema] == ex) = [];
        end
        
        function [exListStr, extrema] = getExtremaListBoxStr(obj)
            extrema = obj.extrema;
            exListStr = cell(size(obj.extrema));
            
            for(i=1:length(obj.extrema))
                exListStr{i} = obj.extrema(i).getNameStr();
            end
        end
        
        function ind = getListBoxIndForExtremum(obj, extremum)
            [~, exa] = obj.getExtremaListBoxStr();
            ind = find(exa == extremum, 1, 'first'); 
        end
        
        function extremum = getExtremaForInd(obj, ind)
            [~, exa] = obj.getExtremaListBoxStr();
            extremum = LaunchVehicleExtrema.empty(0,1);

            if(ind >= 1 && ind <= length(exa))
                extremum = exa(ind);
            end
        end
        
        function [extremaGAStr, extrema] = getExtremaGraphAnalysisTaskStrs(obj)
            [~, extrema] = obj.getExtremaListBoxStr();
            
            extremaGAStr = cell(1,length(extrema));
            A = length(extrema);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(extrema))
                extremaGAStr{i} = sprintf(sprintf('Extrema %s Value - "%s"',formSpec, extrema(i).getNameStr()), i);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculus Calculation Objects
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addCalculusCalcObj(obj, calcObj)
            obj.calcObjs(end+1) = calcObj;
        end
        
        function removeCalculusCalcObj(obj, calcObj)
            obj.calcObjs([obj.calcObjs] == calcObj) = [];
        end
        
        function [calcListStr, calcObjs] = getCalculusCalcObjListBoxStr(obj)
            calcObjs = obj.calcObjs;
            calcListStr = cell(size(obj.calcObjs));
            
            for(i=1:length(obj.calcObjs))
                calcListStr{i} = obj.calcObjs(i).getNameStr();
            end
        end
        
        function ind = getListBoxIndForCalculusCalcObj(obj, calcObj)
            [~, cObj] = obj.getCalculusCalcObjListBoxStr();
            ind = find(cObj == calcObj, 1, 'first'); 
        end
        
        function calcObj = getCalculusCalcObjForInd(obj, ind)
            [~, cObj] = obj.getCalculusCalcObjListBoxStr();
            calcObj = AbstractLaunchVehicleCalculusCalc.empty(1,0);

            if(ind >= 1 && ind <= length(cObj))
                calcObj = cObj(ind);
            end
        end
        
        function [calcObjsGAStr, cObjs] = getCalculusCalcObjGraphAnalysisTaskStrs(obj)
            [~, cObjs] = obj.getCalculusCalcObjListBoxStr();
            
            calcObjsGAStr = cell(1,length(cObjs));
            A = length(cObjs);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(cObjs))
                calcObjsGAStr{i} = sprintf(sprintf('Calculus %s Value - "%s"',formSpec, cObjs(i).getNameStr()), i);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Engine to Tank Connections
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addEngineToTankConnection(obj, e2TConn)
            obj.engineTankConns(obj.engineTankConns == e2TConn) = [];
            obj.engineTankConns(end+1) = e2TConn;
        end
        
        function removeEngineToTankConnection(obj, e2TConn)
            obj.engineTankConns([obj.engineTankConns] == e2TConn) = [];
        end
        
        function [e2TConnStr, e2TConns] = getEngineToTankConnectionsListBoxStr(obj)
            e2TConnStr = {};
            e2TConns = obj.engineTankConns;
            
            for(i=1:length(obj.engineTankConns)) %#ok<*NO4LP>
                e2TConnStr{end+1} = obj.engineTankConns(i).getName(); %#ok<AGROW>
            end
        end

        function e2TConn = getEngineToTankForInd(obj, ind)
            [~, e2TConns] = obj.getEngineToTankConnectionsListBoxStr();
            e2TConn = EngineToTankConnection.empty(1,0);

            if(ind >= 1 && ind <= length(e2TConns))
                e2TConn = e2TConns(ind);
            end
        end
        
        function conns = getEngineToTankConnsForEngine(obj, engine)
            conns = obj.engineTankConns([obj.engineTankConns.engine] == engine);
        end
        
        function conns = getEngineToTankConnsForTank(obj, tank)
            conns = obj.engineTankConns([obj.engineTankConns.tank] == tank);
        end
        
        function removeAllEngineToTanksConnsWithEngine(obj, engine)
            obj.engineTankConns([obj.engineTankConns.engine] == engine) = [];
        end
        
        function removeAllEngineToTanksConnsWithTank(obj, tank)
            obj.engineTankConns([obj.engineTankConns.tank] == tank) = [];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Tank to Tank Connections
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addTankToTankConnection(obj, t2TConn)
            obj.tankToTankConns(obj.tankToTankConns == t2TConn) = [];
            obj.tankToTankConns(end+1) = t2TConn;
        end
        
        function removeTankToTankConnection(obj, t2TConn)
            obj.tankToTankConns([obj.tankToTankConns] == t2TConn) = [];
        end
        
        function [t2TConnStr, t2TConns] = getTankToTankConnectionsListBoxStr(obj)
            t2TConnStr = {};
            t2TConns = obj.tankToTankConns;
            
            for(i=1:length(obj.tankToTankConns)) %#ok<*NO4LP>
                t2TConnStr{end+1} = obj.tankToTankConns(i).getName(); %#ok<AGROW>
            end
        end

        function t2TConn = getTankToTankForInd(obj, ind)
            [~, t2TConns] = obj.getTankToTankConnectionsListBoxStr();
            t2TConn = TankToTankConnection.empty(1,0);

            if(ind >= 1 && ind <= length(t2TConns))
                t2TConn = t2TConns(ind);
            end
        end
        
        function conns = getTankToTankConnsForSrcTank(obj, srcTank)
            conns = obj.tankToTankConns([obj.tankToTankConns.srcTank] == srcTank);
        end
        
        function conns = getTankToTankConnsForTgtTank(obj, tgtTank)
            conns = obj.tankToTankConns([obj.tankToTankConns.tgtTank] == tgtTank);
        end
        
        function removeAllTankToTanksConnsWithSrcTank(obj, srcTank)
            obj.tankToTankConns([obj.tankToTankConns.srcTank] == srcTank) = [];
        end
        
        function removeAllTankToTanksConnsWithTgtTank(obj, tgtTank)
            obj.tankToTankConns([obj.tankToTankConns.tgtTank] == tgtTank) = [];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Other/Misc.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [vars, descStrs] = getActiveOptVars(obj)
            vars = AbstractOptimizationVariable.empty(0,1);
            descStrs = {};
            
            for(i=1:length(obj.stages))
                stage = obj.stages(i);
                stageVar = stage.getExistingOptVar();

                if(not(isempty(stageVar)) && stageVar.getUseTfForVariable())
                    vars(end+1) = stageVar; %#ok<AGROW>
                    descStrs{end+1} = sprintf('Stage "%s"',stage.name); %#ok<AGROW>
                end
                
                for(j=1:length(stage.tanks))
                    tank = stage.tanks(j);
                    
                    tVar = tank.getExistingOptVar();
                    if(not(isempty(tVar)) && tVar.getUseTfForVariable())
                        vars(end+1) = tVar; %#ok<AGROW>
                        descStrs{end+1} = sprintf('Tank "%s"',tank.name); %#ok<AGROW>
                    end
                end
            end
        end
        
        function tf = isVarFromLaunchVehicle(obj, var)
            tf = false;
            
            if(not(isempty(obj)))
                for(i=1:length(obj.stages))
                    tf = tf || obj.stages(i).isVarFromStage(var);
                end
            end
        end
    end
    
    methods(Static)
        function newLv = createDefaultLaunchVehicle(lvdData)
            newLv = LaunchVehicle(lvdData);
            
            firstStg = LaunchVehicleStage(newLv);
            firstStg.name = 'First Stage';
                       
            firstStgEngine = LaunchVehicleEngine(firstStg);
            firstStgEngine.name = 'First Stage Engine';
            firstStgEngine.vacThrust = 215;
            firstStgEngine.vacIsp = 350;
            firstStgEngine.seaLvlThrust = 168;
            firstStgEngine.seaLvlIsp = 250;
             
            firstStgTank = LaunchVehicleTank(firstStg);
            firstStgTank.name = 'First Stage Tank';
            firstStgTank.initialMass = 4;
                                    
            firstStg.dryMass = 1.5+0.5; %mT;
            firstStg.tanks(end+1) = firstStgTank;
            firstStg.engines(end+1) = firstStgEngine;
            
            newLv.stages(end+1) = firstStg;
            
            newLv.engineTankConns(end+1) = EngineToTankConnection(firstStgTank, firstStgEngine);
        end
        
        function obj = loadobj(obj)
            if(isempty(obj.tankTypes))
                obj.tankTypes = TankFluidTypeSet.getDefaultFluidTypeSet().copy();
            end
        end
    end
end