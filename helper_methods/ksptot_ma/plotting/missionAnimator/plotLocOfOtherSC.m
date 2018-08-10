function [hOtherScPt, hOtherScO] = plotLocOfOtherSC(hAxis, oScStruct, validBodyID, ut, posOffset, bodyInfo, isPlotOrbit, isPlotMarker)
    hOtherScPt = [];
    hOtherScO = [];
    if(oScStruct.parentID == validBodyID)
        epoch = oScStruct.epoch;
        sma = oScStruct.sma;
        ecc = oScStruct.ecc;
        inc = deg2rad(oScStruct.inc);
        raan =  deg2rad(oScStruct.raan);
        arg = deg2rad(oScStruct.arg);
        mean = deg2rad(oScStruct.mean);
        
        inputOrbit = [sma, ecc, inc, raan, arg, mean, epoch];
        otherScInfo = getBodyInfoStructFromOrbit(inputOrbit);
        
        [rVect, ~] = getStateAtTime(otherScInfo, ut, bodyInfo.gm);
        
        color = oScStruct.color;
        
        if(isPlotMarker)
            hold on;
            rVectOffset = rVect + posOffset;
            hOtherScPt = plot3(hAxis, rVectOffset(1), rVectOffset(2), rVectOffset(3), 'Color', color, 'Marker','p','MarkerFaceColor',color, 'MarkerSize', 6, 'Clipping', 'off');
            hold off;
        end
        
        if(isPlotOrbit)
            oColor = color;
            
            if(isfield(oScStruct,'linestyle'))
                oLineStyle = oScStruct.linestyle;
            else
                oLineStyle = '--';
            end
                
            if(ecc<1)
                minTru = 0;
                maxTru = 2*pi;
            else
                maxR = max(norm(rVect),10*bodyInfo.radius);
                baseTru = computeTrueAFromRadiusEcc(maxR, sma, ecc);
                minTru = -baseTru;
                maxTru = baseTru;
            end
            
            hOtherScO = plotOrbit(oColor, sma, ecc, inc, raan, arg, minTru, maxTru, bodyInfo.gm, hAxis, posOffset, 0.5, oLineStyle);
        end
    end
end