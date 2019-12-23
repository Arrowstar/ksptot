classdef SecondOrderODE < AbstractODE
    %SecondOrderODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods(Access=private)
        function obj = SecondOrderODE()
            
        end
    end
    
    methods(Static)
        function odeFH = getOdeFunctionHandle(simDriver, eventInitStateLogEntry, ~, ~)
            totalMass = eventInitStateLogEntry.getTotalVehicleMass();
            gravityForceModel = GravityForceModel();
            
            odeFH = @(t,y) SecondOrderODE.odefun(t,y, simDriver, eventInitStateLogEntry, [], totalMass, gravityForceModel);
        end
        
        function odeEventsFH = getOdeEventsFunctionHandle(simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses)
            numTankStatesToAppend = length(eventInitStateLogEntry.getAllActiveTankStates());
            
            odeEventsFH = @(t,y,yp) SecondOrderODE.odeEvents(t,y,yp, simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses,numTankStatesToAppend);
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(tStartPropTime, maxPropTime)
            odeOutputFH = @(t,y,yp,flag) SecondOrderODE.odeOutput(t,y,yp,flag, tStartPropTime, maxPropTime);
        end
    end
    
    methods(Static, Access=private)
        ypp = odefun(t,y, obj, eventInitStateLogEntry, tankStates, dryMass, forceModels);
        
        [value,isterminal,direction, causes] = odeEvents(t,y,yp, obj, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses,numTankStatesToAppend);
        
        status = odeOutput(t,y,yp,flag, intStartTime, maxIntegrationDuration)
    end
end