classdef(Abstract) AbstractLvdSweepVariation < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLvdSweepVariation How one sweep parameter is varied across a run.
    %
    %   There are two flavors, and the sampler needs to be able to mix them
    %   in a single run: a grid (an explicit list of levels, as the original
    %   case matrix always used) and a distribution (a continuous range that
    %   the sampler draws from).  A grid still answers sampleFromUnit so a
    %   Latin hypercube or random run can include a gridded parameter, and a
    %   distribution still answers getGridValues so a full factorial run can
    %   include a dispersed one.

    properties
        id(1,1) double = 0;
    end

    methods(Abstract)
        %getGridValues The explicit levels this parameter takes in a full
        %factorial run.
        values = getGridValues(obj)

        %sampleFromUnit Maps u on [0, 1] onto a parameter value.
        x = sampleFromUnit(obj, u)

        %isGrid True for a level list, false for a distribution.
        tf = isGrid(obj)

        %getSummaryStr One line description for the parameter table.
        str = getSummaryStr(obj)
    end

    methods
        function n = getNumGridValues(obj)
            n = numel(obj.getGridValues());
        end

        function [lb, ub] = getRange(obj)
            values = obj.getGridValues();
            lb = min(values);
            ub = max(values);
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end
        end
    end

    methods(Sealed)
        function tf = eq(A, B)
            tf = [A.id] == [B.id];
        end

        function tf = ne(A, B)
            tf = [A.id] ~= [B.id];
        end
    end
end
