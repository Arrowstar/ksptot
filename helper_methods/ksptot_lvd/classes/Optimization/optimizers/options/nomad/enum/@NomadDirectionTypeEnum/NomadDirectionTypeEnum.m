classdef NomadDirectionTypeEnum < matlab.mixin.SetGet
    %NomadDirectionTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Ortho1('ortho 1', 'Ortho 1')
        Ortho2('ortho 2', 'Ortho 2')
        OrthoN1('ortho n+1', 'Ortho N+1')
        OrthoN1Quad('ortho n+1 quad', 'Ortho N+1 Quad')
        OrthoN1Neg('ortho n+1 neg', 'Ortho N+1 Neg')
        Ortho('ortho', 'Ortho')
        Ortho2N('ortho 2n', 'Ortho 2N')
        
        LT1('lt 1', 'LT 1')
        LT2('lt 2', 'LT 2')
        LT2N('lt 2n', 'LT 2N')
        LTN1('lt n+1', 'LT N+1')
        
        GPSBin('gps binary', 'GPS Binary')
        GPS2NStatic('gps 2n static', 'GPS 2N Static')
        GPS2NRand('gps 2n rand', 'GPS 2N Random')
        GPSN1StaticUniform('gps n+1 static uniform', 'GPS N+1 Static Uniform')
        GPSN1Static('gps n+1 static', 'GPS N+1 Static')
        GPSN1RandUniform('gps n+1 rand uniform', 'GPS N+1 Random Uniform')
        GPSN1Rand('gps n+1 rand', 'GPS N+1 Random')
        GPS1Static('gps 1 static', 'GPS 1 Static')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadDirectionTypeEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('NomadDirectionTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadDirectionTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadDirectionTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end