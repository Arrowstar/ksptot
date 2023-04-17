classdef AlwaysFalseActionCondition < AbstractActionConditional
    %AlwaysFalseActionCondition Summary of this class goes here
    %   Detailed explanation goes here

    properties
        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.AlwaysFalse;
    end

    methods
        function obj = AlwaysFalseActionCondition()

        end

        function tf = evaluateConditional(obj, stateLogEntry)
            arguments(Input)
                obj(1,1) AlwaysFalseActionCondition
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            arguments(Output)
                tf(1,1) logical
            end

            tf = false;
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('Always False');
        end

        function condStr = getConditionalString(obj)
            condStr = 'FALSE';
        end

        function node = getTreeNodes(obj, parent)
            node = uitreenode(parent, 'Text',obj.getListboxStr(), 'NodeData',obj, 'Icon','cancel.png');
        end
    end
end