function launch = ma_createLaunch(name, launchEpoch, launchLat, launchLong, launchAlt, ...
                                        launchToF, burnoutLat, burnoutLong, burnoutAlt, ...
                                        lineColor, lineStyle, bodyId)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % vars = [bool bool bool bool bool bool bool bool; 
    %         lower lower lower lower lower lower lower lower; 
    %         upper upper upper upper upper upper upper upper]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    
    launch = struct();
    launch.name = name;
    launch.type = 'Launch';
    launch.bodyId = bodyId;
    launch.launchValue = [launchEpoch, launchLat, launchLong, launchAlt, launchToF, burnoutLat, burnoutLong, burnoutAlt];
    launch.lineColor = lineColor;
    launch.lineStyle = lineStyle;
    launch.id = rand(1);
end