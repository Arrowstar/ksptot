classdef (Abstract) AbstractForceModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        forceVect = getForce(obj, ut, rVect, vVect, mass, bodyInfo, CdA, throttleModel, steeringModel, tankStates, stageStates, lvState);
    end
    
    methods(Static)
        function [ut, rVect, vVect, mass, bodyInfo, CdA] = getParamsFromStateLogEntry(stateLogEntry)
            ut = stateLogEntry.time;
            rVect = stateLogEntry.position;
            vVect = stateLogEntry.velocity;
            mass = stateLogEntry.getTotalVehicleMass();
            bodyInfo = stateLogEntry.centralBody;
            CdA = stateLogEntry.aero.area * stateLogEntry.aero.Cd; 
        end
    end
end