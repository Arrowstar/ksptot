classdef LvdSettings < matlab.mixin.SetGet
    %LvdSettings Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %integration
        minAltitude(1,1) double = -1;  %km
        simMaxDur(1,1) double = 20000; %sec
        maxScriptPropTime(1,1) double = 5; %sec
        isSparseOutput(1,1) logical = false;
        
        %auto-propagation
        autoPropScript(2,1) logical = true;
    end
    
    methods
        function obj = LvdSettings()

        end
    end
end