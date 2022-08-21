classdef (Abstract) AbstractControlFrame < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractControlFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract, Constant)
        enum
    end
    
    methods
        enum = getControlFrameEnum(obj);
    end
    
    methods(Access=protected)
        function rHat = computeRHat(~, rVect)
            rHat = normVector(rVect);
        end
        
        function vHat = computeVHat(~, vVect)
            vHat = normVector(vVect);
        end
        
        function hHat = computeHHat(~, rVect, vVect)
            hVect = crossARH(rVect, vVect);
            hHat = normVector(hVect);
        end
        
        function uHat = computeUHat(obj, rVect, vVect)
            uHat = normVector(crossARH(obj.computeHHat(rVect,vVect), obj.computeVHat(vVect)));
        end
        
        function lHat = computeLHat(obj, rVect, vVect)
            lHat = normVector(crossARH(obj.computeHHat(rVect,vVect), obj.computeRHat(rVect)));
        end
     
        %This is probably just wrong
%         function nHat = computeNHat(~, rVect)
%             eZ = [0;0;1];
%             nHat = normVector(eZ - (rVect(3)/norm(rVect)*rVect));
%         end
%         
%         function eHat = computeEHat(obj, rVect)
%             eHat = normVector(crossARH(obj.computeNHat(rVect), obj.computeRHat(rVect)));
%         end
        
        function pHat = computePHat(obj, rVect, vVect, gmu)
            hVect = crossARH(rVect, vVect);
            pHat = normVect(crossARH(vVect, hVect)/gmu - obj.computeRHat(rVect));
        end
        
        function qHat = computeQHat(obj, rVect, vVect, gmu)
            qHat = normVector(crossARH(obj.computeHHat(rVect, vVect), obj.computePHat(rVect, vVect, gmu)));
        end
    end
end