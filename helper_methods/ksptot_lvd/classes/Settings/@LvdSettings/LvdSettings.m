classdef LvdSettings < matlab.mixin.SetGet
    %LvdSettings Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %integration
        minAltitude(1,1) double = -1;  %km
        simMaxDur(1,1) double = 100000000; %sec
        maxScriptPropTime(1,1) double = 5; %sec
        isSparseOutput(1,1) logical = false;
        
        %auto-propagation
        autoPropScript(1,1) logical = true;
        
        %event propagation times
        disEvtPropTimes(1,1) logical = false;
    end
    
    methods
        function obj = LvdSettings()

        end
    end
end