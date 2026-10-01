classdef EventColorLineSpec < matlab.mixin.SetGet
    %EventColorLineSpec Per-event trajectory line style.
    %   color is a free 1x3 RGB double in [0,1], picked with uisetcolor in
    %   the Edit Event window. Legacy missions that stored a ColorSpecEnum
    %   are migrated to RGB by loadobj (see lvd_colorSpecToRGB).

    properties
        color(1,3) double {mustBeBetween(color, 0, 1)} = [1, 0, 0]
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine
        lineWidth(1,1) double = 1.5;
        markerSpec(1,1) MarkerStyleEnum = MarkerStyleEnum.None
        markerSize(1,1) double = 6;
    end

    methods
        function obj = EventColorLineSpec()
            %Default event color is Red, matching the legacy palette row 1.
        end
    end

    methods(Static)
        function obj = loadobj(s)
            %loadobj Migrates missions saved with ColorSpecEnum colors.
            if(isa(s, 'EventColorLineSpec'))
                obj = s;
                %Tolerate a hand-built object carrying a legacy enum value.
                try
                    obj.color = lvd_colorSpecToRGB(obj.color);
                catch
                    obj.color = [1, 0, 0];
                end
                return;
            end
            obj = EventColorLineSpec();
            fields = fieldnames(s);
            for(i=1:numel(fields))
                switch(fields{i})
                    case 'color'
                        obj.color = lvd_colorSpecToRGB(s.color);
                    otherwise
                        try
                            obj.(fields{i}) = s.(fields{i});
                        catch
                            %Added/removed properties across versions: keep default.
                        end
                end
            end
        end
    end
end

