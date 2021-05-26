classdef PropagatorEnum < matlab.mixin.SetGet
    %PropagatorEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        ForceModel('Force Model Propagator','Propagates vehicle trajectories using a full force model.  This is the most generic and comprehesive propagator but also the most CPU intensive.  Use this if you have thrust, drag, third body gravity, etc.');
        TwoBody('Two Body Propagator','Propagates trajectories according to two body motion (central body gravity only).  This is a faster propagator but also much more restrictive.  Use this if your vehicle is only influenced by one gravitational source and there is no drag, thrust, etc.');
    end
    
    properties
        name char = '';
        desc char = '';
    end
    
    methods
        function obj = PropagatorEnum(nameStr, descStr)
            obj.name = nameStr;
            obj.desc = descStr;
        end
    end
        
    methods(Static)       
        function listBoxStr = getListBoxStr()
            m = enumeration('PropagatorEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PropagatorEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PropagatorEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    
        function propagatorObj = getPropagatorObjFromEnum(m)
            switch m
                case PropagatorEnum.ForceModel
                    propagatorObj = ForceModelPropagator();

                otherwise
                    error('Unknown propagator type.');
            end
        end
    end
end