clc; clear all; format long g; close all

addpath(genpath('C:\Users\Adam\Dropbox\Documents\MATLAB\mice'));

d = dir('C:\Users\Adam\Dropbox\Documents\MATLAB\mice\data');
for(i=1:length(d))
    di = d(i);

    if(~di.isdir)
        try
        cspice_furnsh(fullfile(di.folder, di.name));
        catch ME
            continue;
        end
    end
end

frames = {'IAU_MERCURY', ...
          'IAU_VENUS', ...
          'IAU_EARTH', ...
          'IAU_MOON', ...
          'IAU_MARS', ...
          'IAU_JUPITER', ...
          'IAU_SATURN', ...
          'IAU_URANUS', ...
          'IAU_NEPTUNE', ...
          'IAU_PLUTO'};

for(i=1:length(frames))
    frame = frames{i};

    et = cspice_str2et('2000-Jan-01 12:00:00.0000 TDB');
    mat = cspice_pxform(frame, 'ECLIPJ2000', et);
    
    disp(frame);
    x_axis = mat * [1;0;0];
    fprintf('bodyxaxis = %0.9f, %0.9f, %0.9f\n', x_axis(1), x_axis(2), x_axis(3));

    z_axis = mat * [0;0;1];
    fprintf('bodyzaxis = %0.9f, %0.9f, %0.9f\n\n', z_axis(1), z_axis(2), z_axis(3));
end

