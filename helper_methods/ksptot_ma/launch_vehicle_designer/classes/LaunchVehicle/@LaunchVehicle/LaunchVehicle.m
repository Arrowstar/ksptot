classdef LaunchVehicle < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stages(1,:) LaunchVehicleStage
        engineTankConns(1,:) EngineToTankConnection
    end
    
    methods
        function obj = LaunchVehicle()
            
        end
        
        function tanks = getTanksConnectedToEngine(obj, engine)
            obj.engineTankConns = obj.engineTankConns;
            connections = obj.engineTankConns([obj.engineTankConns.engine] == engine); %connectedTanks
            tanks = [connections.tank];
        end
    end
    
    methods(Static)
        function newLv = createDefaultLaunchVehicle()
            newLv = LaunchVehicle();
            
            pyldStg = LaunchVehicleStage(newLv);
            pyldStg.name = 'Payload';
            
            uprStg = LaunchVehicleStage(newLv);
            uprStg.name = 'Upper Stage';
            
            firstStg = LaunchVehicleStage(newLv);
            firstStg.name = 'First Stage';
            
            uprStgEngine = LaunchVehicleEngine(uprStg);
            uprStgEngine.vacThrust = 60;
            uprStgEngine.vacIsp = 345;
            uprStgEngine.seaLvlThrust = 14.783;
            uprStgEngine.seaLvlIsp = 85;
            
            firstStgEngine = LaunchVehicleEngine(firstStg);
            firstStgEngine.vacThrust = 215;
            firstStgEngine.vacIsp = 350;
            firstStgEngine.seaLvlThrust = 168;
            firstStgEngine.seaLvlIsp = 250;
            
            uprStgTank = LaunchVehicleTank(uprStg);
            uprStgTank.initialMass = 1;
            
            firstStgTank = LaunchVehicleTank(firstStg);
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