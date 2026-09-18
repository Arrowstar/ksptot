classdef LvdCameraAnchorTypeEnum < matlab.mixin.SetGet
    %LvdCameraAnchorTypeEnum Where the FixedAnchor camera mode of the LVD
    %3-D view puts the (fixed) camera position.
    %
    %   FixedXYZ       - an XYZ coordinate in a user-chosen reference frame,
    %                    resolved into the view frame at each time.
    %   GroundObject   - one of the mission's ground objects.
    %   GeometricPoint - one of the mission's (vehicle-independent) geometric
    %                    points.

    enumeration
        FixedXYZ('Fixed Coordinates')
        GroundObject('Ground Object')
        GeometricPoint('Geometric Point')
    end

    properties
        name(1,:) char = '';
    end

    methods
        function obj = LvdCameraAnchorTypeEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LvdCameraAnchorTypeEnum');
            listBoxStr = {m.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdCameraAnchorTypeEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdCameraAnchorTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
