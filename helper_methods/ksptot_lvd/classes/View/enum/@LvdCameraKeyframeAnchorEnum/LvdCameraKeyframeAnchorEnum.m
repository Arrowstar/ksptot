classdef LvdCameraKeyframeAnchorEnum < matlab.mixin.SetGet
    %LvdCameraKeyframeAnchorEnum What a camera keyframe's time is measured
    %against.
    %
    %   AbsoluteTime - the keyframe time is a UT in seconds.
    %   EventStart   - the keyframe time is the first logged time of an
    %                  event plus an offset in seconds.
    %   EventEnd     - the keyframe time is the last logged time of an event
    %                  plus an offset in seconds.

    enumeration
        AbsoluteTime('Absolute Time (UT)')
        EventStart('Event Start')
        EventEnd('Event End')
    end

    properties
        name(1,:) char = '';
    end

    methods
        function obj = LvdCameraKeyframeAnchorEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LvdCameraKeyframeAnchorEnum');
            listBoxStr = {m.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdCameraKeyframeAnchorEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdCameraKeyframeAnchorEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
