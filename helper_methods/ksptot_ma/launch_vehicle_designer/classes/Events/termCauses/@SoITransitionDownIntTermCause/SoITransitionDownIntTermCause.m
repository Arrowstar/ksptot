classdef SoITransitionDownIntTermCause < AbstractIntegrationTerminationCause
    %SoITransitionDownIntTermCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fromBody(1,1) KSPTOT_BodyInfo
        toBody(1,1) KSPTOT_BodyInfo
        celBodyData struct
    end
    
    methods
        function obj = SoITransitionDownIntTermCause(fromBody, toBody, celBodyData)
            obj.fromBody = fromBody;
            obj.toBody = toBody;
            obj.celBodyData = celBodyData;
        end
        
        function tf = shouldRestartIntegration(obj)
            tf = true;
        end
        
        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
%             bodyInfo = stateLogEntry.centralBody;
            ut = stateLogEntry.time;
            rVect = reshape(stateLogEntry.position,1,3);
            vVect = reshape(stateLogEntry.velocity,1,3);
            
            [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(obj.toBody, obj.celBodyData, ut, rVect, vVect);
            
            dcm = stateLogEntry.attitude.dcm;
             
            newStateLogEntry = stateLogEntry.deepCopy();
            newStateLogEntry.position = rVectDown;
            newStateLogEntry.velocity = vVectDown;
            newStateLogEntry.centralBody = obj.toBody;
            newStateLogEntry.steeringModel = stateLogEntry.steeringModel.deepCopy();
            
            newStateLogEntry.steeringModel.setContinuityTerms(true, true, true);
            newStateLogEntry.steeringModel.setConstsFromDcmAndContinuitySettings(dcm, ut, rVectDown, vVectDown, obj.toBody);
            newStateLogEntry.steeringModel.setT0(ut);
        end
    end
end