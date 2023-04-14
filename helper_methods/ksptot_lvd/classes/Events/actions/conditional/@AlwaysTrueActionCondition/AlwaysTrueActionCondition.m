classdef AlwaysTrueActionCondition < AbstractActionConditional
    %AlwaysTrueActionCondition Summary of this class goes here
    %   Detailed explanation goes here

    properties
        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.AlwaysTrue;
    end

    methods
        function obj = AlwaysTrueActionCondition()

        end

        function tf = evaluateConditional(obj, stateLogEntry)
            arguments(Input)
                obj(1,1) AlwaysTrueActionCondition
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            arguments(Output)
                tf(1,1) logical
            end

            tf = true;
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('Always True');
        end

        function condStr = getConditionalString(obj)
            condStr = 'TRUE';
        end

        function node = getTreeNodes(obj, parent)
            node = uitreenode(parent, 'Text',obj.getListboxStr(), 'NodeData',obj);
        end
    end
end