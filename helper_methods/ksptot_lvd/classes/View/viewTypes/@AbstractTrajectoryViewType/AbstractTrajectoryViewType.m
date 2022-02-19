classdef (Abstract) AbstractTrajectoryViewType < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractTrajectoryViewType Summary of this class goes here
    %   Detailed explanation goes here
        
    methods
        [hCBodySurf, childrenHGs] = plotStateLog(obj, orbitNumToPlot, lvdData, handles)
    end
end