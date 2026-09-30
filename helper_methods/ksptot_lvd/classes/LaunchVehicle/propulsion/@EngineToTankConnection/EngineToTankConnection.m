classdef EngineToTankConnection < matlab.mixin.SetGet
    %EngineToTankConnection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank LaunchVehicleTank 
        engine LaunchVehicleEngine

        %priority Within one propellant species, connections at a higher
        %priority drain first; lower priorities are untouched until every
        %tank at the higher priority is empty.  Tied priorities drain
        %concurrently per flowWeight.  Default 0 reproduces the legacy
        %even split exactly.
        priority(1,1) double = 0;

        %flowWeight Share of the species flow for this connection among
        %tied-priority connections to the same engine.  NaN (default) means
        %"even": identical to the legacy split.  Otherwise must be > 0 and
        %is normalized against the other tied weights.
        flowWeight(1,1) double = NaN;
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        function obj = EngineToTankConnection(tank, engine)
            if(nargin > 0)
                obj.tank = tank;
                obj.engine = engine;
            end
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.engine.stage.launchVehicle.lvdData;
        end
        
        function nameStr = getName(obj)
            nameStr = sprintf('%s to %s', obj.engine.name, obj.tank.name);
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesEngineToTankConn(obj);
        end

        function w = getEffectiveWeight(obj)
            %getEffectiveWeight Flow weight with the NaN-means-even default
            %resolved to 1.  Always > 0 for a valid connection.
            if(isnan(obj.flowWeight))
                w = 1;
            else
                w = obj.flowWeight;
            end
        end

        function setFlowWeight(obj, w)
            %setFlowWeight Validated write: NaN (even) or a positive share.
            if(not(isnan(w)) && ~(isnumeric(w) && isscalar(w) && w > 0))
                error('EngineToTankConnection:invalidFlowWeight', ...
                    'Flow weight must be NaN (even split) or a positive number, got %s.', mat2str(w));
            end
            obj.flowWeight = w;
        end

        function newConn = copy(obj, newTank, newEngine)
            %copy Duplicate this connection, preserving priority/weight.
            %Pass explicit tank/engine to re-point; otherwise shared.
            if(nargin < 2 || isempty(newTank))
                newTank = obj.tank;
            end
            if(nargin < 3 || isempty(newEngine))
                newEngine = obj.engine;
            end
            newConn = EngineToTankConnection(newTank, newEngine);
            newConn.priority = obj.priority;
            newConn.flowWeight = obj.flowWeight;
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            %Connections saved before priority/weight existed load with
            %empty; restore the defaults that reproduce the legacy split.
            if(isempty(obj.priority))
                obj.priority = 0;
            end
            if(isempty(obj.flowWeight))
                obj.flowWeight = NaN;
            end
        end
    end
end