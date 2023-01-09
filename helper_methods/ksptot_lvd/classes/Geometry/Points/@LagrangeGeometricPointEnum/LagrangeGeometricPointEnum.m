classdef LagrangeGeometricPointEnum < matlab.mixin.SetGet
    %LagrangeGeometricPointEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        L1('L1');
        L2('L2');
        L3('L3');
        L4('L4');
        L5('L5');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = LagrangeGeometricPointEnum(name)
            obj.name = name;
        end

        function LPCoord = getNormalizedLPointCoordinates(obj, muStar)
            LP = HaloOrbitApproximator.lagrangePoints(muStar);
            
            switch obj
                case LagrangeGeometricPointEnum.L1
                    LPCoord = LP(1,:)';

                case LagrangeGeometricPointEnum.L2
                    LPCoord = LP(2,:)';

                case LagrangeGeometricPointEnum.L3
                    LPCoord = LP(3,:)';

                case LagrangeGeometricPointEnum.L4
                    LPCoord = LP(4,:)';

                case LagrangeGeometricPointEnum.L5
                    LPCoord = LP(5,:)';
                
                otherwise
                    error('Unknown L Point: %s', obj.name);
            end
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LagrangeGeometricPointEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
    end
end