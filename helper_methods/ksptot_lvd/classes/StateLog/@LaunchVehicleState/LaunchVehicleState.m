classdef LaunchVehicleState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lv LaunchVehicle 
        
        e2TConns EngineToTankConnState
        t2TConns TankToTankConnState
        holdDownEnabled(1,1) logical = false
    end
    
    properties(Transient)
        cachedEngines LaunchVehicleEngine
        cachedConnTanks cell
    end
    
    properties(Constant)
        emptyTankArr = LaunchVehicleTank.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleState(lv)
            obj.lv = lv;
            obj.clearCachedConnEnginesTanks();
        end
        
        %Engine to Tank Connections
        function addE2TConnState(obj, newConnState)
            obj.e2TConns(end+1) = newConnState;
            
            obj.clearCachedConnEnginesTanks();
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
            
            obj.clearCachedConnEnginesTanks();
        end
        
        function tanks = getTanksConnectedToEngine(obj, engine)
            ce = obj.cachedEngines;
            bool = ce == engine;
            if(any(bool))
                tanks = obj.cachedConnTanks{bool};
            else
                tanks = obj.emptyTankArr;

                connStates = obj.e2TConns([obj.e2TConns.active] == true);
                connections = [connStates.conn];

                if(not(isempty(connections)))
                    connections = connections([connections.engine] == engine);
                    tanks = [connections.tank];
                end
                
                if(isempty(tanks))
                    tanks = obj.emptyTankArr;
                end
                
                obj.cachedEngines(end+1) = engine;
                obj.cachedConnTanks(end+1) = {tanks};
            end
        end
        
        function tanks = getTanksConnectedToEngineForStage(obj, engine, stage)
%             tanks = obj.emptyTankArr;
            
            engineTanks = obj.getTanksConnectedToEngine(engine);
%             for(i=1:length(engineTanks))
%                 if(engineTanks(i).stage == stage)
%                     tanks(end+1) = engineTanks(i); %#ok<AGROW>
%                 end
%             end
            if(not(isempty(engineTanks)))
                bool = [engineTanks.stage] == stage;
                tanks = engineTanks(bool);
            else
                tanks = obj.emptyTankArr;
            end
        end
        
        %Tank To Tank Connections
        function addT2TConnState(obj, newConnState)
            obj.t2TConns(end+1) = newConnState;
        end
        
        function removeT2TConnStateForConn(obj, conn)
            ind = [];
            for(i=1:length(obj.t2TConns)) %#ok<*NO4LP>
                if(obj.t2TConns(i).conn == conn)
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                obj.t2TConns(ind) = [];
            end
        end
        
        function t2TConnState = getTank2TankConnStateForConn(obj, conn)
            ind = [];
            for(i=1:length(obj.t2TConns)) %#ok<*NO4LP>
                if(obj.t2TConns(i).conn == conn)
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                t2TConnState = obj.t2TConns(ind);
            end
        end
        
        function tanks = getTanksWithActiveTankToTankConnectionsForStage(obj, stageState)
            tanks = LaunchVehicleState.emptyTankArr;
            
            for(i=1:length(obj.t2TConns))
                connState = obj.t2TConns(i);
                
                if(connState.active)
                    conn = connState.conn;
                    
                    if((not(isempty(conn.srcTank)) && conn.srcTank.stage == stageState.stage))
                        tanks(end+1) = conn.srcTank; %#ok<AGROW>
                    end
                    
                    if((not(isempty(conn.tgtTank)) && conn.tgtTank.stage == stageState.stage))
                        tanks(end+1) = conn.tgtTank; %#ok<AGROW>
                    end                   
                end
            end
            
            if(length(tanks) > 1)
                tanks = unique(tanks);
            end
        end
        
        %Misc
        function newLvState = deepCopy(obj)
            newLvState = obj.copy();
            
            for(i=1:length(obj.e2TConns)) 
                newLvState.e2TConns(i) = obj.e2TConns(i).deepCopy();
            end
            
            for(i=1:length(obj.t2TConns)) 
                newLvState.t2TConns(i) = obj.t2TConns(i).deepCopy();
            end
            
            newLvState.clearCachedConnEnginesTanks();
        end
        
        function clearCachedConnEnginesTanks(obj)
            obj.cachedEngines = LaunchVehicleEngine.empty(1,0);
            obj.cachedConnTanks = {};
        end
    end
end