classdef ControlFramesEnum  < matlab.mixin.SetGet
    %ControlFramesEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        NedFrame('NED Frame', {'Roll Angle','Pitch Angle','Yaw Angle'})
        WindFrame('Wind Frame', {'Bank Angle','Angle of Attack','Sideslip Angle'});
        InertialFrame('Base Frame Relative', {'Roll Angle','Declination Angle','Right Ascension Angle'});
    end
    
    properties
        name(1,:) char
        angleNames (1,3) cell
    end
    
    methods
        function obj = ControlFramesEnum(name, angleNames)
            obj.name = name;
            obj.angleNames = angleNames;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('ControlFramesEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ControlFramesEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ControlFramesEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
        
        function cFrame = getControlFrameForEnum(enum)
            switch enum
                case ControlFramesEnum.NedFrame
                    cFrame = NedControlFrame();

                case ControlFramesEnum.WindFrame
                    cFrame = WindControlFrame();
                    
                case ControlFramesEnum.InertialFrame
                    cFrame = InertialControlFrame();
                    
                otherwise
                    error('Unknown control frame: %s', class(enum));
            end
        end
    end
end

