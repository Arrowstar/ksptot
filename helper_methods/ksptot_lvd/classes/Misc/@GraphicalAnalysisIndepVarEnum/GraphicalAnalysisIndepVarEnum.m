classdef GraphicalAnalysisIndepVarEnum < matlab.mixin.SetGet
    %GraphicalAnalysisIndepVarEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        Time('Time')
        MissionElapsedTime('Mission Elapsed Time');
        TrueAnomaly('True Anomaly');
        Longitude('Longitude')
        Altitude('Altitude')
    end

    properties
        name(1,:) char
    end

    methods
        function obj = GraphicalAnalysisIndepVarEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListboxStr()
            m = enumeration('GraphicalAnalysisIndepVarEnum');
            listBoxStr = {m.name};
        end
    end
end