classdef LaunchVehicleEngine < matlab.mixin.SetGet
    %LaunchVehicleEngine Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage = LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData()));
        
        vacThrust(1,1) double = 0     %kN
        vacIsp(1,1) double =  0       %sec
        seaLvlThrust(1,1) double = 0  %kN
        seaLvlIsp(1,1) double = 0     %sec
        
        bodyFrameThrustVect(3,1) double = [1;0;0]; %ND
        
        minThrottle(1,1) double = 0.0; %must be 0<=x<=1
        maxThrottle(1,1) double = 1.0; %must be 0<=x<=1
        
        name(1,:) char = 'Untitled Engine';
        id(1,1) double = 0;
    end
    
    properties(Dependent)
        lvdData
    end
    
    properties(Constant)
        vacPress = 0;            %kPa
        seaLvlPress = 101.325;   %kPa
    end
    
    methods
        function obj = LaunchVehicleEngine(stage)
            if(nargin>0)
                obj.stage = stage;
            end
            
            obj.id = rand();
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.stage.launchVehicle.lvdData;
        end
        
        function val = getVacThrust(obj)
            val = obj.vacThrust;
        end
        
        function val = getVacIsp(obj)
            val = obj.vacIsp;
        end
        
        function val = getSeaLvlThrust(obj)
            val = obj.seaLvlThrust;
        end
        
        function val = getSeaLvlIsp(obj)
            val = obj.seaLvlIsp;
        end
        
        function val = getMinThrottle(obj)
            val = obj.minThrottle;
        end
        
        function val = getMaxThrottle(obj)
            val = obj.maxThrottle;
        end
        
        function engineSummStr = getEngineSummaryStr(obj)
            engineSummStr = {};
            
            engineSummStr{end+1} = sprintf('\t\t\t%s', obj.name);
            engineSummStr{end+1} = sprintf('\t\t\t\tVacuum Thrust = %.3f kN', obj.vacThrust);
            engineSummStr{end+1} = sprintf('\t\t\t\tVacuum Isp = %.3f sec', obj.vacIsp);
            engineSummStr{end+1} = sprintf('\t\t\t\tSea Level Thrust = %.3f kN', obj.seaLvlThrust);
            engineSummStr{end+1} = sprintf('\t\t\t\tSea Level Isp = %.3f sec', obj.seaLvlIsp);
        end
        
        function [thrust, isp] = getThrustIspForPressure(obj, presskPa)
            x = presskPa;
            x1 = obj.seaLvlPress;
            x2 = obj.vacPress;
            
            y1 = obj.seaLvlThrust;
            y2 = obj.vacThrust;
            thrust = y1 + ((x-x1)*(y2-y1))/(x2-x1);
            
            y1 = obj.seaLvlIsp;
            y2 = obj.vacIsp;
            isp = y1 + ((x-x1)*(y2-y1))/(x2-x1);
        end
        
        function [thrust, mdot] = getThrustFlowRateForPressure(obj, presskPa)
            [thrust, isp] = obj.getThrustIspForPressure(presskPa);
            
            mdot = -(thrust/(getG0() * isp)); %kN/(m/s/s * s) = kN/(m/s) = (1/1000) N / (m/s) = (1/1000) kg*m/s/s /(m/s) = (1/1000) kg/s = mT/s
        end
        
        function newThrottle = adjustThrottleForMinMax(obj, inputThrottle)
            if(inputThrottle < obj.minThrottle)
                newThrottle = obj.minThrottle;
            elseif(inputThrottle > obj.maxThrottle)
                newThrottle = obj.maxThrottle;
            else
                newThrottle = inputThrottle;
            end
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesEngine(obj);
        end
        
        function newEngine = copy(obj)
            newEngine = LaunchVehicleEngine(obj.stage);
            
            newEngine.vacThrust = obj.vacThrust;
            newEngine.vacIsp = obj.vacIsp;
            newEngine.seaLvlThrust = obj.seaLvlThrust;
            newEngine.seaLvlIsp = obj.seaLvlIsp;
            
            newEngine.bodyFrameThrustVect = obj.bodyFrameThrustVect;
            
            newEngine.minThrottle = obj.minThrottle;
            newEngine.maxThrottle = obj.maxThrottle;
            
            newEngine.name = sprintf('Copy of %s', obj.name);
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
    end
end