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

        cachedEngTankInds cell
        cachedEngTankIndsTanks LaunchVehicleTank
        cachedEngTankIndsStgStates LaunchVehicleStageState
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
        
        function engTankInds = getEngineToTankStateIndices(obj, tankStates, stgStates)
            %Maps every (stage, engine) pair to the indices, within
            %tankStates, of the tank states that engine draws from.  The map
            %depends on the fuel line topology and on the identity/order of
            %tankStates and stgStates, nothing else.
            %
            %This memo lives on the LaunchVehicleState instance -- NOT in a
            %persistent -- for two reasons.  A persistent is session global,
            %so two different vehicles would silently share a topology, and
            %it is invisible to clearCachedConnEnginesTanks(), which is what
            %SetEngineTankConnActiveStateEventAction calls when it toggles a
            %connection at run time.  Hanging it here means it is invalidated
            %by exactly the same events that invalidate the connection memo
            %it is derived from.
            tankStateTanks = [tankStates.tank];

            if(not(isempty(obj.cachedEngTankInds)) && ...
               LaunchVehicleState.isSameHandleArray(obj.cachedEngTankIndsTanks, tankStateTanks) && ...
               LaunchVehicleState.isSameHandleArray(obj.cachedEngTankIndsStgStates, stgStates))
                engTankInds = obj.cachedEngTankInds;
                return;
            end

            engTankInds = cell(length(stgStates), 1);
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                engineStates_i = stgStates(i).engineStates;
                engTankInds{i} = cell(length(engineStates_i), 1);

                for(j=1:length(engineStates_i))
                    tanks_j = obj.getTanksConnectedToEngine(engineStates_i(j).engine);

                    inds = zeros(1, length(tanks_j));
                    numValid = 0;
                    for(k=1:length(tanks_j))
                        idx = find(tankStateTanks == tanks_j(k), 1);
                        if(not(isempty(idx)))
                            numValid = numValid + 1;
                            inds(numValid) = idx;
                        end
                    end

                    engTankInds{i}{j} = inds(1:numValid);
                end
            end

            obj.cachedEngTankInds = engTankInds;
            obj.cachedEngTankIndsTanks = tankStateTanks;
            obj.cachedEngTankIndsStgStates = stgStates;
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

            obj.cachedEngTankInds = {};
            obj.cachedEngTankIndsTanks = LaunchVehicleTank.empty(1,0);
            obj.cachedEngTankIndsStgStates = LaunchVehicleStageState.empty(1,0);
        end
    end

    methods(Static, Access=private)
        function tf = isSameHandleArray(arrA, arrB)
            %Element-wise handle identity.  Deliberately not isequal(), which
            %compares property values rather than object identity.
            tf = numel(arrA) == numel(arrB) && all(arrA(:) == arrB(:));
        end
    end
end