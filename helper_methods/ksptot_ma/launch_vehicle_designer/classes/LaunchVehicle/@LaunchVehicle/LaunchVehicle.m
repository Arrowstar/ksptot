classdef LaunchVehicle < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stages(1,:) LaunchVehicleStage
        engineTankConns(1,:) EngineToTankConnection
        
        lvdData(1,:) LvdData
    end
    
    methods
        function obj = LaunchVehicle(lvdData)
            obj.lvdData = lvdData;
        end
        
        function lvSummStr = getLvSummaryStr(obj)
            lvSummStr = {};
            
            %TODO
            dryMass = 0;
            propMass = 0;
            totalMass = 0;
            
            for(i=1:length(obj.stages))
                dryMass = dryMass + obj.stages(i).getStageDryMass();
                propMass = propMass + obj.stages(i).getStageInitPropMass();
                totalMass = totalMass + obj.stages(i).getStageInitTotalMass();
            end
            
            lvSummStr{end+1} = 'Launch Vehicle Configuration Summary';
            lvSummStr{end+1} = '----------------------';
            lvSummStr{end+1} = sprintf('Launch Vehicle (Dry Mass = %.3f mT, Prop Mass = %.3f mT, Total = %.3f mT)', dryMass, propMass, totalMass);
            
            for(i=1:length(obj.stages))
                lvSummStr = horzcat(lvSummStr, obj.stages(i).getStageSummaryStr());
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
        
        function ind = getListBoxIndForStage(obj, stage)
            ind = find(obj.stages == stage);
        end
                
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
        
        function ind = getListBoxIndForTank(obj, tank)
            ind = [];
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                ind = find(obj.stages(i).tanks == tank);
                
                if(not(isempty(ind)))
                    break;
                end
            end
        end
        
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
        
        function ind = getListBoxIndForEngine(obj, engine)
            ind = [];
            
            for(i=1:length(obj.stages)) %#ok<*NO4LP>
                ind = find(obj.stages(i).engines == engine);
                
                if(not(isempty(ind)))
                    break;
                end
            end
        end
        
        function [e2TConnStr, e2TConns] = getEngineToTankConnectionsListBoxStr(obj)
            e2TConnStr = {};
            e2TConns = obj.engineTankConns;
            
            for(i=1:length(obj.engineTankConns)) %#ok<*NO4LP>
                e2TConnStr{end+1} = obj.engineTankConns(i).getName(); %#ok<AGROW>
            end
        end
    end
    
    methods(Static)
        function newLv = createDefaultLaunchVehicle(lvdData)
            newLv = LaunchVehicle(lvdData);
            
            pyldStg = LaunchVehicleStage(newLv);
            pyldStg.name = 'Payload';
            
            uprStg = LaunchVehicleStage(newLv);
            uprStg.name = 'Upper Stage';
            
            firstStg = LaunchVehicleStage(newLv);
            firstStg.name = 'First Stage';
            
            uprStgEngine = LaunchVehicleEngine(uprStg);
            uprStgEngine.name = 'Upper Stage Engine';
            uprStgEngine.vacThrust = 60;
            uprStgEngine.vacIsp = 345;
            uprStgEngine.seaLvlThrust = 14.783;
            uprStgEngine.seaLvlIsp = 85;
            
            firstStgEngine = LaunchVehicleEngine(firstStg);
            firstStgEngine.name = 'First Stage Engine';
            firstStgEngine.vacThrust = 215;
            firstStgEngine.vacIsp = 350;
            firstStgEngine.seaLvlThrust = 168;
            firstStgEngine.seaLvlIsp = 250;
            
            uprStgTank = LaunchVehicleTank(uprStg);
            uprStgTank.name = 'Upper Stage Tank';
            uprStgTank.initialMass = 1;
            
            firstStgTank = LaunchVehicleTank(firstStg);
            firstStgTank.name = 'First Stage Tank';
            firstStgTank.initialMass = 4;
                        
            pyldStg.dryMass = 0.5; %mT;
            
            uprStg.dryMass = 0.5+0.125; %mT;
            uprStg.tanks(end+1) = uprStgTank;
            uprStg.engines(end+1) = uprStgEngine;
            
            firstStg.dryMass = 1.5+0.5; %mT;
            firstStg.tanks(end+1) = firstStgTank;
            firstStg.engines(end+1) = firstStgEngine;
            
            newLv.stages(end+1) = pyldStg;
            newLv.stages(end+1) = uprStg;
            newLv.stages(end+1) = firstStg;
            
            newLv.engineTankConns(end+1) = EngineToTankConnection(uprStgTank, uprStgEngine);
            newLv.engineTankConns(end+1) = EngineToTankConnection(firstStgTank, firstStgEngine);
        end
    end
end