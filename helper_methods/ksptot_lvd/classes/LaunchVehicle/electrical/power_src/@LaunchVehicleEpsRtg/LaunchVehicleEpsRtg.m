classdef LaunchVehicleEpsRtg < AbstractLaunchVehicleElectricalPowerSrcSnk
    %LaunchVehicleEpsRtg Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        name(1,:) char  = 'Untitled RTG';
        
        initPwrRate(1,1) double = 0; %EC/s
        halfLife(1,1) double = 0; %s
        initTime(1,1) double = 0; %sec UT
        
        id = rand();
    end
    
    methods
        function obj = LaunchVehicleEpsRtg(stage)
            obj.stage = stage;
            
            obj.id = rand();
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function stage = getAttachedStage(obj)
            stage = obj.stage;
        end
        
        function newState = createDefaultInitialState(obj, stageState)
            newState = LaunchVehicleEpsRtgState(stageState, obj);
        end
        
        function useTF = openEditDialog(obj)
            useTF = lvd_EditPowerRtgGUI(obj);
        end
        
        function tf = isInUse(obj)
            tf = false;
        end
        
        function newPowerSrc = copy(obj)
            newPowerSrc = LaunchVehicleEpsRtg(obj.stage);
            newPowerSrc.initPwrRate = obj.initPwrRate;
            newPowerSrc.halfLife = obj.halfLife;
            newPowerSrc.initTime = obj.initTime;
            
            newPowerSrc.name = sprintf('Copy of %s', obj.name);
        end
        
        function pwrRate = getElectricalPwrRate(obj, elemSet, ~, ~, ~, ~)
            time = elemSet.time;
            
            initialPwrRate = obj.initPwrRate;
            halfLifeSec = obj.halfLife;
            
            if(halfLifeSec > 0)
                deltaT = time - obj.initTime;
                if(deltaT > 0)
                    pwrRate = initialPwrRate * (1/2)^(deltaT/halfLifeSec);
                else
                    pwrRate = initialPwrRate;
                end
            else
                pwrRate = initialPwrRate;
            end
        end
        
        function summStr = getSummaryStr(obj)
            summStr = {};
            
            [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(obj.initTime);
            epochStr = formDateStr(year, day, hour, minute, sec);
            
            summStr{end+1} = sprintf('\t\t\t%s', obj.name);
            summStr{end+1} = sprintf('\t\t\t\tInitial Charge Rate = %.3f EC/s', obj.initPwrRate);
            summStr{end+1} = sprintf('\t\t\t\tHalf Life = %.3f s', obj.halfLife);
            summStr{end+1} = sprintf('\t\t\t\tHalf Life Initial Time = %s (%.3f s)', epochStr, obj.initTime);
        end
    end
end