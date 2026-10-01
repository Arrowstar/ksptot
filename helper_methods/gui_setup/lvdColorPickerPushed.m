function lvdColorPickerPushed(src, ~)
%lvdColorPickerPushed Shared callback for lvdSetupColorPicker buttons.
%   Opens the injected color picker, then runs the dialog's onPick (for
%   live-write dialogs), updates the pending RGB and the swatch.
%   Cancels (picker returns 0) and invalid output leave state untouched.
%   See also: lvdSetupColorPicker, lvdGetColorPickerRGB.

tag = src.UserData.tag;
fig = ancestor(src, 'figure');

current = getappdata(fig, [tag, 'RGB']);
if(isempty(current))
    current = [1, 0, 0];
end
picker = getappdata(fig, [tag, 'PickerFcn']);
if(isempty(picker))
    picker = getappdata(fig, 'lvdColorPickerFcn');
end
if(isempty(picker))
    picker = @uisetcolor;
end
try
    newColor = picker(current, 'Pick Color');
catch
    return;
end
if(isequal(newColor, 0) || not(isnumeric(newColor)) || numel(newColor) ~= 3)
    return;
end
newColor = double(reshape(newColor, 1, 3));
if(any(not(isfinite(newColor))) || any(newColor < 0) || any(newColor > 1))
    return;
end

onPick = src.UserData.onPick;

setappdata(fig, [tag, 'RGB'], newColor);
sw = getappdata(fig, [tag, 'Swatch']);
if(not(isempty(sw)) && all(isvalid(sw)))
    sw.BackgroundColor = newColor;
end

if(not(isempty(onPick)))
    onPick(newColor);
end
figure(fig);
end
