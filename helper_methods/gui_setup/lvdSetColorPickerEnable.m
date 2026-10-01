function lvdSetColorPickerEnable(fig, tag, state)
%lvdSetColorPickerEnable Enables/disables an lvdSetupColorPicker button.
%   STATE is 'on'/'off' (or the OnOffSwitchState equivalent).
%   See also: lvdSetupColorPicker.

btn = getappdata(fig, [tag, 'Button']);
if(not(isempty(btn)) && all(isvalid(btn)))
    btn.Enable = state;
end
end
