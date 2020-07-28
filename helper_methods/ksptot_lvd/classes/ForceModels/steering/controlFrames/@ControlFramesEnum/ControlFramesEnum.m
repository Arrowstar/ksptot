classdef ControlFramesEnum  < matlab.mixin.SetGet
    %ControlFramesEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        NedFrame('NED Frame')
        WindFrame('Wind Frame');
        InertialFrame('Inertial Frame');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = ControlFramesEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ControlFramesEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
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

