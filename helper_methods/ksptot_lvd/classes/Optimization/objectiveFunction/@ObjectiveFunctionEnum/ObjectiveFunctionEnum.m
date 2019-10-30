classdef ObjectiveFunctionEnum < matlab.mixin.SetGet
    %ObjectiveFunctionEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        NoObjectiveFunction('Satisfy Constraints Only','NoOptimizationObjectiveFcn')
        MinDistToBody('Minimize Distance to Body','MinDistanceToBodyObjectiveFcn')
        MaximizeVehicleMass('Maximize Vehicle Mass','MaximizeLaunchVehicleMassObjectiveFcn')
    end
    
    properties
        name char = '';
        class char = '';
    end
    
    methods
        function obj = ObjectiveFunctionEnum(name, class)
            obj.name = name;
            obj.class = class;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ObjectiveFunctionEnum');
            listBoxStr = {m.name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ObjectiveFunctionEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [ind, enum] = getIndForClass(objFcnObject)
            m = enumeration('ObjectiveFunctionEnum');
            ind = find(ismember({m.class},class(objFcnObject)),1,'first');
            enum = m(ind);
        end
    end
end

