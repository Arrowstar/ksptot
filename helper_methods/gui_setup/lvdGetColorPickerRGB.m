function rgb = lvdGetColorPickerRGB(fig, tag, fallbackRGB)
%lvdGetColorPickerRGB Pending picker color for Save & Close handlers.
%   Falls back to the object's stored color when picker state is missing
%   or invalid. Both inputs accept legacy ColorSpecEnum values.
%   See also: lvdSetupColorPicker.

rgb = getappdata(fig, [tag, 'RGB']);
try
    rgb = lvd_colorSpecToRGB(rgb);
catch
    rgb = lvd_colorSpecToRGB(fallbackRGB);
end
end
