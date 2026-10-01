function btn = lvdSetupColorPicker(fig, parentGrid, row, col, dropdown, rgb, tooltip, tag, onPick)
%lvdSetupColorPicker Free RGB color button + swatch replacing a dropdown.
%   Deletes the legacy fixed-list DROPDOWN and builds a nested 1x2 grid in
%   its cell holding a "Choose..." button (uisetcolor) and a swatch panel,
%   so the parent grid layout is untouched. Idempotent: repopulating an
%   open dialog only refreshes the swatch.
%
%   ONPICK (optional function_handle) runs as onPick(rgb) after a
%   successful pick, for dialogs that write live (no Save & Close).
%   Save-style dialogs omit it and read lvdGetColorPickerRGB on save.
%
%   The picker is seam-injected for tests: per-picker appdata [TAG
%   'PickerFcn'], else fig-level 'lvdColorPickerFcn', else @uisetcolor.
%   See also: lvdColorPickerPushed, lvdGetColorPickerRGB.

arguments
    fig(1,1) matlab.ui.Figure
    parentGrid(1,1) matlab.ui.container.GridLayout
    row(1,1) double
    col(1,1) double
    dropdown
    rgb
    tooltip(1,:) char
    tag(1,:) char
    onPick = []
end

rgb = lvd_colorSpecToRGB(rgb);
setappdata(fig, [tag, 'RGB'], rgb);
if(not(isappdata(fig, 'lvdColorPickerFcn')))
    setappdata(fig, 'lvdColorPickerFcn', @uisetcolor);
end

btn = getappdata(fig, [tag, 'Button']);
if(not(isempty(btn)) && all(isvalid(btn)))
    sw = getappdata(fig, [tag, 'Swatch']);
    if(not(isempty(sw)) && all(isvalid(sw)))
        sw.BackgroundColor = rgb;
    end
    btn.UserData = struct('tag', tag, 'onPick', onPick);
    return;
end

if(isa(dropdown, 'matlab.ui.control.DropDown') && not(isempty(dropdown)) && all(isvalid(dropdown)))
    row = dropdown.Layout.Row;
    col = dropdown.Layout.Column;
    delete(dropdown);
end

sub = uigridlayout(parentGrid);
sub.Layout.Row = row;
sub.Layout.Column = col;
sub.ColumnWidth = {'1x', 42};
sub.RowHeight = {'1x'};
sub.Padding = [0, 0, 0, 0];
sub.RowSpacing = 0;
sub.ColumnSpacing = 4;

btn = uibutton(sub, 'push');
btn.Tag = [tag, 'Button'];
btn.Text = 'Choose...';
btn.Tooltip = tooltip;
btn.FontSize = 10.6666666666667;
btn.ButtonPushedFcn = @(src, evt) lvdColorPickerPushed(src, evt);
btn.UserData = struct('tag', tag, 'onPick', onPick);
btn.Layout.Row = 1;
btn.Layout.Column = 1;

sw = uipanel(sub);
sw.Tag = [tag, 'Swatch'];
sw.Title = '';
sw.BorderType = 'line';
sw.BackgroundColor = rgb;
sw.Layout.Row = 1;
sw.Layout.Column = 2;

setappdata(fig, [tag, 'Button'], btn);
setappdata(fig, [tag, 'Swatch'], sw);
end
