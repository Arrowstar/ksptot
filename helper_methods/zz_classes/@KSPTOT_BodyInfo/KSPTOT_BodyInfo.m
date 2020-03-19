classdef KSPTOT_BodyInfo < matlab.mixin.SetGet
    %KSPTOT_BodyInfo Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        epoch@double
        sma@double
        ecc@double
        inc@double
        raan@double
        arg@double
        mean@double
        gm@double
        radius@double
        atmohgt@double
        atmopresscurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        atmotempcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        atmotempsunmultcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        lattempbiascurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        lattempsunmultcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        axialtempsunbiascurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        axialtempsunmultcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        ecctempbiascurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        atmomolarmass@double
        rotperiod@double
        rotini@double
        bodycolor@char
        canbecentral@double
        canbearrivedepart@double
        parent
        parentid@double
        name@char
        id@double
    end
    
    properties
        celBodyData struct
        parentBodyInfo KSPTOT_BodyInfo
        parentBodyInfoNeedsUpdate logical = true;
    end
    
    methods
        function obj = KSPTOT_BodyInfo() 
        
        end
        
        function parentBodyInfo = getParBodyInfo(obj, celBodyData)
            if(obj.parentBodyInfoNeedsUpdate && isempty(obj.parentBodyInfo))
                pBodyInfo = getParentBodyInfo(obj, celBodyData);
                
                if(not(isempty(pBodyInfo)))
                    obj.parentBodyInfo = pBodyInfo;
                end
                
                obj.parentBodyInfoNeedsUpdate = false;
            end
            
            parentBodyInfo = obj.parentBodyInfo;
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
            
            if(isempty(tf))
                tf = false;
            end
        end
    end
    
	methods(Static)
        function bodyObj = getObjFromBodyInfoStruct(bodyInfo)
            bodyObj = KSPTOT_BodyInfo();
          
            bodyObj.epoch = bodyInfo.epoch;
            bodyObj.sma = bodyInfo.sma;
            bodyObj.ecc = bodyInfo.ecc;
            bodyObj.inc = bodyInfo.inc;
            bodyObj.raan = bodyInfo.raan;
            bodyObj.arg = bodyInfo.arg;
            bodyObj.mean = bodyInfo.mean;
            bodyObj.gm = bodyInfo.gm;
            bodyObj.radius = bodyInfo.radius;
            bodyObj.atmohgt = bodyInfo.atmohgt;
            bodyObj.atmopresscurve = bodyInfo.atmopresscurve;
            bodyObj.atmotempcurve = bodyInfo.atmotempcurve;
            bodyObj.atmotempsunmultcurve = bodyInfo.atmotempsunmultcurve;
            bodyObj.lattempbiascurve = bodyInfo.lattempbiascurve;
            bodyObj.lattempsunmultcurve = bodyInfo.lattempsunmultcurve;
            bodyObj.atmomolarmass = bodyInfo.atmomolarmass;
            bodyObj.rotperiod = bodyInfo.rotperiod;
            bodyObj.rotini = bodyInfo.rotini;
            bodyObj.bodycolor = bodyInfo.bodycolor;
            bodyObj.canbecentral = bodyInfo.canbecentral;
            bodyObj.canbearrivedepart = bodyInfo.canbearrivedepart;
            bodyObj.parent = bodyInfo.parent;
            bodyObj.parentid = bodyInfo.parentid;
            bodyObj.name = bodyInfo.name;
            bodyObj.id = bodyInfo.id;
        end
    end
end

