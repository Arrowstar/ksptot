function plotXfrOrbitApses(hAxis, xferOrbit, anomDX, anomAX, gmuXfr)
%plotXfrOrbitApses Summary of this function goes here
%   Detailed explanation goes here

    smaX = xferOrbit(1);
    eccX = xferOrbit(2);
    incX = xferOrbit(3);
    raanX = xferOrbit(4);
    argX = xferOrbit(5);

    if(anomAX > anomDX) 
        if(anomDX < pi && anomAX > pi)
            r = getStatefromKepler(smaX, eccX, incX, raanX, argX, pi, gmuXfr);
            h = plot3(hAxis, r(1),r(2),r(3), 'gp', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
        end
    elseif(anomAX < anomDX)         
        r = getStatefromKepler(smaX, eccX, incX, raanX, argX, 0, gmuXfr);
        h = plot3(r(1),r(2),r(3), 'gd', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
        if(anomAX > pi || anomDX < pi)
            r = getStatefromKepler(smaX, eccX, incX, raanX, argX, pi, gmuXfr);
            h = plot3(r(1),r(2),r(3), 'gp', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
        end
    end
end

