classdef QuantityComparisonActionCondition < AbstractActionConditional
    %QuantityComparisonActionCondition Summary of this class goes here
    %   Detailed explanation goes here

    properties
        task GraphicalAnalysisTask
        tgtValue(1,1) double
        comparisonType ComparisonTypeEnum
        tol(1,1) double = 0;

        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.QuantityComparison;
    end

    properties(Constant, Transient)
        maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
    end

    methods
        function obj = QuantityComparisonActionCondition(task, tgtValue, conditionalType, tol)
            obj.task = task;
            obj.tgtValue = tgtValue;
            obj.comparisonType = conditionalType;
            obj.tol = tol;
        end

        function [tf, unitStr] = evaluateConditional(obj, stateLogEntry)
            arguments(Input)
                obj(1,1) QuantityComparisonActionCondition
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            arguments(Output)
                tf(1,1) logical
                unitStr(1,:) char
            end

            lvdData = stateLogEntry.lvdData;

            otherSCId = [];
            stationID = [];
            prevDistTraveled = 0;

            propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            celBodyData = lvdData.celBodyData;
            
            [curStateValue, unitStr, ~] = obj.task.executeTask(stateLogEntry, obj.maTaskList, prevDistTraveled, otherSCId, stationID, propNames, celBodyData);
            
            switch obj.comparisonType
                case ComparisonTypeEnum.Equals
                    tf = abs(obj.tgtValue - curStateValue) < obj.tol; 

                case ComparisonTypeEnum.GreaterThan
                    tf = curStateValue > obj.tgtValue - obj.tol;

                case ComparisonTypeEnum.LessThan
                    tf = curStateValue < obj.tgtValue + obj.tol;
    
                case ComparisonTypeEnum.GreaterThanOrEquals
                    tf = curStateValue >= obj.tgtValue - obj.tol;

                case ComparisonTypeEnum.LessThanOrEquals
                    tf = curStateValue <= obj.tgtValue + obj.tol;

                otherwise
                    error('Unknown conditional type: %s\n', obj.comparisonType.name);
            end
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s %s %0.3f (+/- %0.3f)', obj.task.getListBoxStr(), obj.comparisonType.symbol, obj.tgtValue, obj.tol);
        end

        function condStr = getConditionalString(obj)
            condStr = sprintf('%s %s %0.3f (+/- %0.3f)', obj.task.getListBoxStr(), obj.comparisonType.symbol, obj.tgtValue, obj.tol);
        end

        function node = getTreeNodes(obj, parent)
            node = uitreenode(parent, 'Text',obj.getListboxStr(), 'NodeData',obj);
        end
    end
end