classdef QuantityComparisonActionCondition < AbstractActionConditional
    %QuantityComparisonActionCondition Summary of this class goes here
    %   Detailed explanation goes here

    properties
        task GraphicalAnalysisTask
        frame AbstractReferenceFrame
        comparisonType ComparisonTypeEnum = ComparisonTypeEnum.Equals
        compareAgainst CompareAgainstEnum = CompareAgainstEnum.NumericConstant;

        %numerical
        tgtValue(1,1) double
        
        %quantity
        quantCompareTaskStr(1,:) char
        quantCompareFrame AbstractReferenceFrame

        %tolerance
        tol(1,1) double = 0;
    end

    properties(Constant)
        maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.QuantityComparison;
    end

    properties(Dependent)
        qcTask(1,1) GraphicalAnalysisTask
    end

    methods
        function obj = QuantityComparisonActionCondition(task, tgtValue, conditionalType, tol, frame)
            obj.task = task;
            obj.tgtValue = tgtValue;
            obj.comparisonType = conditionalType;
            obj.tol = tol;
            obj.frame = frame;
        end

        function set.frame(obj, newFrame)
            obj.frame = newFrame;
            obj.task.frame = newFrame; %#ok<MCSUP>
        end

        function value = get.qcTask(obj)
            value = GraphicalAnalysisTask(obj.quantCompareTaskStr, obj.quantCompareFrame);
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

            if(isempty(obj.frame))
                obj.frame = lvdData.initStateModel.centralBody.getBodyCenteredInertialFrame();
            end
            obj.task.frame = obj.frame;
            
            [curStateValue, unitStr, ~] = obj.task.executeTask(stateLogEntry, obj.maTaskList, prevDistTraveled, otherSCId, stationID, propNames, celBodyData);
            
            if(obj.compareAgainst == CompareAgainstEnum.NumericConstant)
                compareAgainstValue = obj.tgtValue;

            elseif(obj.compareAgainst == CompareAgainstEnum.GaTaskQuantity)
                if(isempty(obj.quantCompareTaskStr))
                    lvdTaskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());
                    obj.quantCompareTaskStr = lvdTaskList{1};
                end

                if(isempty(obj.quantCompareFrame))
                    obj.quantCompareFrame = lvdData.initStateModel.centralBody.getBodyCenteredInertialFrame();
                end

                [compareAgainstValue, ~, ~] = obj.qcTask.executeTask(stateLogEntry, obj.maTaskList, prevDistTraveled, otherSCId, stationID, propNames, celBodyData);
            else
                error('Uknown comparison against type: %s', obj.compareAgainst.name);
            end

            switch obj.comparisonType
                case ComparisonTypeEnum.Equals
                    tf = abs(compareAgainstValue - curStateValue) < obj.tol; 

                case ComparisonTypeEnum.GreaterThan
                    tf = curStateValue > compareAgainstValue - obj.tol;

                case ComparisonTypeEnum.LessThan
                    tf = curStateValue < compareAgainstValue + obj.tol;
    
                case ComparisonTypeEnum.GreaterThanOrEquals
                    tf = curStateValue >= compareAgainstValue - obj.tol;

                case ComparisonTypeEnum.LessThanOrEquals
                    tf = curStateValue <= compareAgainstValue + obj.tol;

                otherwise
                    error('Unknown conditional type: %s\n', obj.comparisonType.name);
            end
        end

        function listboxStr = getListboxStr(obj)
            if(obj.compareAgainst == CompareAgainstEnum.NumericConstant)
                listboxStr = sprintf('%s %s %0.3f (+/- %0.3f)', obj.task.getListBoxStr(), obj.comparisonType.symbol, obj.tgtValue, obj.tol);

            elseif(obj.compareAgainst == CompareAgainstEnum.GaTaskQuantity)
                listboxStr = sprintf('%s %s %s (+/- %0.3f)', obj.task.getListBoxStr(), obj.comparisonType.symbol, obj.qcTask.getListBoxStr(), obj.tol);

            else
                error('Uknown comparison against type: %s', obj.compareAgainst.name);
            end
        end

        function condStr = getConditionalString(obj)
            condStr = obj.getListboxStr();
        end

        function node = getTreeNodes(obj, parent)
            node = uitreenode(parent, 'Text',obj.getListboxStr(), 'NodeData',obj, 'Icon','calculator.png');
        end
    end
end