classdef AeroIndepVar < matlab.mixin.SetGet
    %AeroIndepVar Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Altitude('Altitude', 'km')
        BodyFixedVelocity('Body-Fixed Velocity', 'km/s')
        AtmoPressure('Atmospheric Pressure', 'kPa')
        AtmoDensity('Atmospheric Density', 'kg/m^3')
        DynPressure('Dynamic Pressure', 'kPa')
        MachNum('Mach Number', '')
    end
    
    properties
        name(1,:) char
        unit(1,:) char
    end
    
    methods
        function obj = AeroIndepVar(name, unit)
            obj.name = name;
            obj.unit = unit;
        end
        
        function lblStr = getAxesLabelStr(obj)
            lblStr = sprintf('%s [%s]', obj.name, obj.unit);
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AeroIndepVar');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('AeroIndepVar');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AeroIndepVar');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end