classdef SensorReportDataTypesEnum < matlab.mixin.SetGet
    %SensorReportDataTypesEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Coverage('Coverage','')
        AzAngle('Azimuth Angle','deg');
        ElAngle('Elevation Angle','deg');
        Range('Range','km');
        AngleBoresight('Angle to Boresight','deg');
    end
    
    properties
        name(1,:) char
        unitStr(1,:) char
    end
    
    methods
        function obj = SensorReportDataTypesEnum(name, unitStr)
            obj.name = name;
            obj.unitStr = unitStr;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('SensorReportDataTypesEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('SensorReportDataTypesEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SensorReportDataTypesEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end

