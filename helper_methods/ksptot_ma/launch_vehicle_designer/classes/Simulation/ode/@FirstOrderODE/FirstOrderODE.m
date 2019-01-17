classdef FirstOrderODE < AbstractODE
    %FirstOrderODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods(Access=private)
        function obj = FirstOrderODE()
            
        end
    end
    
    methods(Static)
        function odeFH = getOdeFunctionHandle(simDriver, eventInitStateLogEntry, dryMass, forceModels)
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            odeFH = @(t,y) FirstOrderODE.odefun(t,y, simDriver, eventInitStateLogEntry, tankStates, dryMass, forceModels);
        end
        
        function odeEventsFH = getOdeEventsFunctionHandle(simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses)
            odeEventsFH = @(t,y) FirstOrderODE.odeEvents(t,y, simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(tStartPropTime, maxPropTime)
            odeOutputFH = @(t,y,flag) FirstOrderODE.odeOutput(t,y,flag, tStartPropTime, maxPropTime);
        end
    end
    
    methods(Static, Access=private)
        dydt = odefun(t,y, obj, eventInitStateLogEntry, tankStates, dryMass, forceModels);
        
        [value,isterminal,direction, causes] = odeEvents(t,y, obj, eventInitStateLogEntry, evtTermCond, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
        
        status = odeOutput(t,y,flag, intStartTime, maxIntegrationDuration)
    end
end