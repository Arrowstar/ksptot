classdef LaunchVehicleStage < matlab.mixin.SetGet
    %LaunchVehicleStage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        launchVehicle LaunchVehicle
        
        %propulsion
        name char = 'Untitled Stage';
        engines LaunchVehicleEngine
        tanks LaunchVehicleTank
        
        %dry mass
        dryMass(1,1) double = 0; %mT
        
        %electrical
        powerSrcs AbstractLaunchVehicleElectricalPowerSrcSnk = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
        powerSinks AbstractLaunchVehicleElectricalPowerSrcSnk = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
        powerStorages AbstractLaunchVehicleElectricalPowerStorage = AbstractLaunchVehicleElectricalPowerStorage.empty(1,0); 
        
        %id
        id(1,1) double = 0;
        
        optVar StageDryMassOptimizationVariable
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        function obj = LaunchVehicleStage(launchVehicle)
            obj.launchVehicle = launchVehicle;
            obj.id = rand();
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.launchVehicle.lvdData;
        end
        
        %% Propulsion
        function addEngine(obj, newEngine)
            obj.engines(end+1) = newEngine;
        end
        
        function removeEngine(obj, engine)
            obj.engines([obj.engines] == engine) = [];
            
            obj.launchVehicle.removeAllEngineToTanksConnsWithEngine(engine);
        end
        
        function addTank(obj, newTank)
            obj.tanks(end+1) = newTank;
        end
        
        function removeTank(obj, tank)
            obj.tanks([obj.tanks] == tank) = [];
            
            obj.launchVehicle.removeAllEngineToTanksConnsWithTank(tank);
        end
        
        %% Electrical
        function addPwrSrc(obj, newPwrSrc)
            obj.powerSrcs(end+1) = newPwrSrc;
        end
        
        function removePwrSrc(obj, pwrSrc)
            obj.powerSrcs([obj.powerSrcs] == pwrSrc) = [];
        end
        
        function addPwrSink(obj, newPwrSink)
            obj.powerSinks(end+1) = newPwrSink;
        end
        
        function removePwrSink(obj, pwrSink)
            obj.powerSinks([obj.powerSinks] == pwrSink) = [];
        end
        
        function addPwrStorage(obj, newPwrStorage)
            obj.powerStorages(end+1) = newPwrStorage;
        end
        
        function removePwrStorage(obj, pwrStorage)
            obj.powerStorages([obj.powerStorages] == pwrStorage) = [];
        end
        
        %% Everything else
        function stageSummStr = getStageSummaryStr(obj)
            stageSummStr = {};
            
            propMass = obj.getStageInitPropMass();
            totalMass = obj.getStageInitTotalMass();
            
            stageSummStr{end+1} = sprintf('\t%s (Dry Mass = %0.3f mT, Prop Mass = %.3f mT, Total = %.3f mT)', obj.name, obj.dryMass, propMass, totalMass);
            
            stageSummStr{end+1} = sprintf('\t\tTanks');
            if(~isempty(obj.tanks))
                for(i=1:length(obj.tanks)) %#ok<*NO4LP>
                    stageSummStr = horzcat(stageSummStr,obj.tanks(i).getTankSummaryStr()); %#ok<AGROW>
                end
            else
                stageSummStr{end+1} = sprintf('\t\t\tNone');
            end
            
            stageSummStr{end+1} = sprintf('\t\tEngines');
            if(~isempty(obj.engines))
                for(i=1:length(obj.engines))
                    stageSummStr = horzcat(stageSummStr,obj.engines(i).getEngineSummaryStr()); %#ok<AGROW>
                end
            else
                stageSummStr{end+1} = sprintf('\t\t\tNone');
            end
            
            stageSummStr{end+1} = sprintf('\t\tElectrical Power Sources');
            if(~isempty(obj.powerSrcs))
                for(i=1:length(obj.powerSrcs))
                    stageSummStr = horzcat(stageSummStr,obj.powerSrcs(i).getSummaryStr()); %#ok<AGROW>
                end
            else
                stageSummStr{end+1} = sprintf('\t\t\tNone');
            end
            
            stageSummStr{end+1} = sprintf('\t\tElectrical Power Storage');
            if(~isempty(obj.powerStorages))
                for(i=1:length(obj.powerStorages))
                    stageSummStr = horzcat(stageSummStr,obj.powerStorages(i).getSummaryStr()); %#ok<AGROW>
                end
            else
                stageSummStr{end+1} = sprintf('\t\t\tNone');
            end
            
            stageSummStr{end+1} = sprintf('\t\tElectrical Power Sinks');
            if(~isempty(obj.powerSinks))
                for(i=1:length(obj.powerSinks))
                    stageSummStr = horzcat(stageSummStr,obj.powerSinks(i).getSummaryStr()); %#ok<AGROW>
                end
            else
                stageSummStr{end+1} = sprintf('\t\t\tNone');
            end
        end
        
        function dryMass = getStageDryMass(obj)
            dryMass = obj.dryMass;
        end
        
        function propMass = getStageInitPropMass(obj)
            propMass = 0;
            for(i=1:length(obj.tanks))
                propMass = propMass + obj.tanks(i).getInitialMass();
            end
        end
        
        function totalMass = getStageInitTotalMass(obj)
            totalMass = obj.dryMass + obj.getStageInitPropMass();
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesStage(obj);
        end
        
        function tf = isStageAndChildrenInUse(obj)
            tf = obj.isInUse();
            
            if(tf == false)
                for(i=1:length(obj.engines))
                    tf = tf || obj.engines(i).isInUse();
                end
            end
            
            if(tf == false)
                for(i=1:length(obj.tanks))
                    tf = tf || obj.tanks(i).isInUse();
                end
            end
        end
        
        function optVar = getNewOptVar(obj)
            optVar = StageDryMassOptimizationVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
        
        function tf = isVarFromStage(obj, var)
            if(not(isempty(obj.optVar)))
                tf = obj.optVar == var;
            else
                tf = false;
            end
            
            for(i=1:length(obj.tanks))
                tf = tf || obj.tanks(i).isVarFromTank(var);
            end
        end
    end
end