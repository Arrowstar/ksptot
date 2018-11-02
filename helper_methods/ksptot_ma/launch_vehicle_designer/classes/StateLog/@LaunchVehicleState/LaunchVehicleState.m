classdef LaunchVehicleState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lv(1,1) LaunchVehicle = LaunchVehicle(LvdData.getEmptyLvdData())
        
        e2TConns(1,:) EngineToTankConnState
        holdDownEnabled(1,1) logical = false
    end
    
    properties(Constant)
        emptyTankArr = LaunchVehicleTank.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleState(lv)
            obj.lv = lv;
        end
        
        function addE2TConnState(obj, newConnState)
            obj.e2TConns(end+1) = newConnState;
        end
        
        function removeE2TConnStateForConn(obj, conn)
            ind = [];
            for(i=1:length(obj.e2TConns)) %#ok<*NO4LP>
                if(obj.e2TConns(i).conn == conn)
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                obj.e2TConns(ind) = [];
            end
        end
        
        function tanks = getTanksConnectedToEngine(obj, engine)
            tanks = obj.emptyTankArr;
            
            connStates = obj.e2TConns([obj.e2TConns.active] == true);
            connections = [connStates.conn];
            
            if(not(isempty(connections)))
                connections = connections([connections.engine] == engine);
                tanks = [connections.tank];
            end
        end
        
        function newLvState = deepCopy(obj)
            newLvState = obj.copy();
            
            for(i=1:length(obj.e2TConns)) 
                newLvState.e2TConns(i) = obj.e2TConns(i).deepCopy();
            end
        end
    end
end