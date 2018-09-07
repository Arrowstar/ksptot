classdef ThrustForceModel < AbstractForceModel
    %AbstractForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModel(1,1)
        throttleModel(1,1)
    end
    
    methods
        function obj = ThrustForceModel(steeringModel, throttleModel)
            obj.steeringModel = steeringModel;
            obj.throttleModel = throttleModel;
        end
        
        function forceVect = getForce(obj, stateLogEntry)
            [ut, rVect, vVect, mass, bodyInfo] = obj.getParamsFromStateLogEntry(stateLogEntry);
            
            bodyThrust = [0;0;0];
            
            tankStates = obj.stateLogEntry.getAllTankStates();
            stageStates = obj.stateLogEntry.stageStates;
            for(i=1:length(stageStates)) %#ok<*NO4LP>
                stgState = stageStates(i);
                
                if(stgState.active)
                    engineStates = stgState.engineStates;

                    lv = stgState.stage.launchVehicle;
                    
                    for(j=1:length(engineStates))
                        engState = engineStates(j);
                        
                        if(engState.active)
                            engine = engState.engine;

                            tanks = lv.getTanksConnectedToEngine(engine); %connected tanks

                            propExistsInATank = false; 
                            for(k=1:length(tanks))
                                tank = tanks(k);
                                tankState = findobj(tankStates,'tank',tank);

                                if(tankState.tankMass > 0) %just check to make sure the engine is connected to fuel somewhere
                                    propExistsInATank = true; 
                                    break;
                                end
                            end
                            
                            if(propExistsInATank)
                                bodyThrust = bodyThrust + engine.bodyFrameThrustVect;
                            end
                        end
                    end
                end
            end
            
            %TODO - have bodyThrust now, need to convert to correct
            %inertial direction and throttle setting using steering and
            %throttle models.
        end
    end
end