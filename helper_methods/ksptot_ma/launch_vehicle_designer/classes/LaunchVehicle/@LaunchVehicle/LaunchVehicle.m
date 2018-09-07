classdef LaunchVehicle < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stages@LaunchVehicleStage
        engineTankConns@EngineToTankConnection
    end
    
    methods
        function obj = LaunchVehicle()
            
        end
        
        function tanks = getTanksConnectedToEngine(obj, engine)
            engineTankConns = obj.engineTankConns;
            tanks = findobj(engineTankConns,'engine',engine); %connectedTanks
        end
    end
end