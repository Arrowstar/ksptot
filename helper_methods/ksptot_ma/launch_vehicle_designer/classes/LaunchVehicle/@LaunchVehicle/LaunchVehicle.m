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
            obj.engineTankConns = obj.engineTankConns;
            tanks = findobj(obj.engineTankConns,'engine',engine); %connectedTanks
        end
    end
end