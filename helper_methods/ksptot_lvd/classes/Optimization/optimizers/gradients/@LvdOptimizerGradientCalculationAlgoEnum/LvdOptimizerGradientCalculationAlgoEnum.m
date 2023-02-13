classdef LvdOptimizerGradientCalculationAlgoEnum < matlab.mixin.SetGet
    %LvdOptimizerGradientCalculationAlgoEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        BuiltIn('Built-In Method', ...
                'Uses the method built into the optimization algorithm directly to compute the gradient of the objective and constraints.', ...
                true);
        FiniteDifferences('Finite Differences', ...
                          'Compute the gradient of the objective function using finite differences of a custom type and error order.', ...
                          false);
        DerivEst('DERIVEst Suite', ...
                 'Compute the gradient of the objective function using the DERIVEst Suite.  Tends to be more accurate at the expense of more CPU time needed to compute derivatives.', ...
                 true);
    end
    
    properties
        name(1,:) char
        desc(1,:) char
        disableOptions(1,1) logical = false;
    end
    
    methods
        function obj = LvdOptimizerGradientCalculationAlgoEnum(name, desc, disableOptions)
            obj.name = name;
            obj.desc = desc;
            obj.disableOptions = disableOptions;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('LvdOptimizerGradientCalculationAlgoEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdOptimizerGradientCalculationAlgoEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdOptimizerGradientCalculationAlgoEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end