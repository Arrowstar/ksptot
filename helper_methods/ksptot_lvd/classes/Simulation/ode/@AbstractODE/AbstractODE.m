classdef(Abstract) AbstractODE < matlab.mixin.SetGet
    %AbstractODE Summary of this class goes here
    %   Detailed explanation goes here

    methods(Abstract)
        odeFH = getOdeFunctionHandle(simDriver, eventInitStateLogEntry, dryMass, forceModels)

        odeEventsFH = getOdeEventsFunctionHandle(simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses)

        odeOutputFH = getOdeOutputFunctionHandle(tStartPropTime, maxPropTime)
    end
    
    methods(Static, Access=protected)
        function [ut, rVect, vVect, tankStates] = decomposeIntegratorTandY(t,y, numTankStates)
            ut = t;
            rVect = y(1:3);
            vVect = y(4:6);
            tankStates = y(7:6+numTankStates);
        end
    end
end

