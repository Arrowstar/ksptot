classdef SoITransitionUpIntTermCause < AbstractIntegrationTerminationCause
    %SoITransitionUpIntTermCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fromBody(1,1) KSPTOT_BodyInfo
        toBody KSPTOT_BodyInfo
        celBodyData struct
    end
    
    methods
        function obj = SoITransitionUpIntTermCause(fromBody, toBody, celBodyData)
            obj.fromBody = fromBody;
            obj.toBody = toBody;
            obj.celBodyData = celBodyData;
        end
        
        function tf = shouldRestartIntegration(obj)
            tf = true;
        end
        
        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
            bodyInfo = stateLogEntry.centralBody;
            ut = stateLogEntry.time;
            rVect = reshape(stateLogEntry.position,1,3);
            vVect = reshape(stateLogEntry.velocity,1,3);
            
            [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, obj.celBodyData, ut, rVect, vVect);
            
            dcm = stateLogEntry.attitude.dcm;
             
            newStateLogEntry = stateLogEntry.deepCopy();
            newStateLogEntry.position = rVectUp;
            newStateLogEntry.velocity = vVectUp;
            newStateLogEntry.centralBody = obj.toBody;
            newStateLogEntry.steeringModel = stateLogEntry.steeringModel.deepCopy();
            
            newStateLogEntry.steeringModel.setContinuityTerms(true, true, true);
            newStateLogEntry.steeringModel.setConstsFromDcmAndContinuitySettings(dcm, ut, rVectUp, vVectUp, obj.toBody);
            newStateLogEntry.steeringModel.setT0(ut);
            
            newStateLogEntry.lvState.clearCachedConnEnginesTanks();
        end
    end
end