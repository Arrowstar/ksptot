function palette = lvd_defaultEventPalette()
%lvd_defaultEventPalette Default event/segment colors as Nx3 RGB doubles.
%   The rows preserve the legacy ColorSpecEnum order (Red first) so
%   auto-colored missions look identical after the enum-to-RGB migration.
%   See also: lvd_colorSpecToRGB, EventColorLineSpec.

palette = [1, 0, 0; ...                         % Red
           178/255, 0, 1; ...                   % Magenta
           1, 131/255, 0; ...                   % Orange
           1, 216/255, 0; ...                   % Yellow
           76/255, 220/255, 0; ...              % Green
           0, 210/255, 1; ...                   % Cyan
           0, 0, 1; ...                         % Blue
           0, 0, 0; ...                         % Black
           1, 1, 1; ...                         % White
           1, 0, 220/255; ...                   % Pink
           139/255, 69/255, 19/255; ...         % Brown
           0.15, 0.15, 0.15; ...                % Dark Grey
           0.5, 0.5, 0.5; ...                   % Grey
           223/255, 223/255, 223/255; ...       % Light Grey
           102/255, 1, 0];                      % Bright Green
end
