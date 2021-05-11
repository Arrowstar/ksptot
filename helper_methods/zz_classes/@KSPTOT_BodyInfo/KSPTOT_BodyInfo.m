classdef KSPTOT_BodyInfo < matlab.mixin.SetGet
    %KSPTOT_BodyInfo Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        epoch double
        sma double
        ecc double
        inc double
        raan double
        arg double
        mean double
        gm double
        radius double
        atmohgt double
        atmopresscurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        atmotempcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        atmotempsunmultcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        lattempbiascurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        lattempsunmultcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        axialtempsunbiascurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        axialtempsunmultcurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        ecctempbiascurve = griddedInterpolant([0 1]',[0 0]','spline', 'nearest');
        atmomolarmass double
        rotperiod double
        rotini double
        bodycolor char
        canbecentral double
        canbearrivedepart double
        parent
        parentid double
        name char
        id double
        
        %body surface textures
        surftexturefile (1,:) char = '';
        surftexturezrotoffset(1,1) double = 0; %degrees
        
        %orientation of inertial frame (spin axis handling)
        bodyZAxis(3,1) double = [0;0;1];
        bodyXAxis(3,1) double = [1;0;0];
        bodyRotMatFromGlobalInertialToBodyInertial = [];
    end
    
    properties
        celBodyData
        
        parentBodyInfo KSPTOT_BodyInfo
        parentBodyInfoNeedsUpdate logical = true;
        
        childrenBodyInfo KSPTOT_BodyInfo
        childrenBodyNames cell
        childrenBodyInfoNeedsUpdate logical = true;
    end
    
    properties(Transient)
        doNotUseAtmoTempSunMultCurve(1,1) logical = false;
        doNotUseLatTempSunMultCurve(1,1) logical = false;
        doNotUseAxialTempSunMultCurve(1,1) logical = false;
        doNotUseAxialTempSunBiasCurveGI(1,1) logical = false;
        doNotUseEccTempBiasCurveGI(1,1) logical = false;
        doNotUseAtmoPressCurveGI(1,1) logical = false;
        
        orbitElemsChainCache cell = {};
        fixedFrameFromInertialFrameCache cell = {};
        
        surfTextureCache uint8 = [];
        
        lastComputedTime(1,1) double = NaN;
        lastComputedRVect(3,1) double = NaN(3,1);
        lastComputedVVect(3,1) double = NaN(3,1);
    end
    
    properties(Access=private)
        bodyInertialFrameCache BodyCenteredInertialFrame = BodyCenteredInertialFrame.empty(1,0);
        bodyFixedFrameCache BodyFixedFrame = BodyFixedFrame.empty(1,0);
        
        atmoTempCache AtmoTempDataCache = AtmoTempDataCache.empty(1,0);
        sunDotNormalCache SunDotNormalDataCache = SunDotNormalDataCache.empty(1,0);
        parentGmuCache(1,1) double = NaN;
        
        soiRadiusCache(1,1) double = NaN;
    end
    
    methods
        function obj = KSPTOT_BodyInfo() 
            obj.sunDotNormalCache = SunDotNormalDataCache(obj);
            obj.atmoTempCache = AtmoTempDataCache(obj);
        end
        
        function set.atmotempsunmultcurve(obj,newValue)
            obj.atmotempsunmultcurve = newValue;
            obj.doNotUseAtmoTempSunMultCurve = isa(obj.atmotempsunmultcurve,'griddedInterpolant') && all(obj.atmotempsunmultcurve.Values == 0); %#ok<MCSUP>
        end
        
        function set.lattempsunmultcurve(obj,newValue)
            obj.lattempsunmultcurve = newValue;
            obj.doNotUseLatTempSunMultCurve = isa(obj.lattempsunmultcurve,'griddedInterpolant') && all(obj.lattempsunmultcurve.Values == 0); %#ok<MCSUP>
        end
        
        function set.axialtempsunmultcurve(obj,newValue)
            obj.axialtempsunmultcurve = newValue;
            obj.doNotUseAxialTempSunMultCurve = isa(obj.axialtempsunmultcurve,'griddedInterpolant') && all(obj.axialtempsunmultcurve.Values == 0); %#ok<MCSUP>
        end
        
        function set.axialtempsunbiascurve(obj,newValue)
            obj.axialtempsunbiascurve = newValue;
            obj.doNotUseAxialTempSunBiasCurveGI = isa(obj.axialtempsunbiascurve,'griddedInterpolant') && all(obj.axialtempsunbiascurve.Values == 0); %#ok<MCSUP>
        end
        
        function set.ecctempbiascurve(obj,newValue)
            obj.ecctempbiascurve = newValue;
            obj.doNotUseEccTempBiasCurveGI = isa(obj.ecctempbiascurve,'griddedInterpolant') && all(obj.ecctempbiascurve.Values == 0); %#ok<MCSUP>
        end

        function set.atmopresscurve(obj,newValue)
            obj.atmopresscurve = newValue;
            
            if(not(isempty(obj.atmohgt))) %#ok<MCSUP>
                obj.doNotUseAtmoPressCurveGI = logical(obj.atmohgt > 0 && isempty(obj.atmopresscurve)); %#ok<MCSUP>
            end
        end
        
        function parentBodyInfo = getParBodyInfo(obj, celBodyData)
            if(obj.parentBodyInfoNeedsUpdate || (obj.parentid > 0 && isempty(obj.parentBodyInfo)))
                pBodyInfo = getParentBodyInfo(obj, obj.celBodyData);
                
                if(not(isempty(pBodyInfo)))
                    obj.parentBodyInfo = pBodyInfo;
                end
                
                obj.soiRadiusCache = NaN;
                obj.parentBodyInfoNeedsUpdate = false;
            end
            
            parentBodyInfo = obj.parentBodyInfo;
        end
        
        function [childrenBodyInfo, cbNames] = getChildrenBodyInfo(obj, celBodyData)
            if(obj.childrenBodyInfoNeedsUpdate)
                [cBodyInfo,cbNames] = getChildrenOfParentInfo(celBodyData, obj.name);
                
                if(not(isempty(cBodyInfo)))
                    for(i=1:length(cBodyInfo))
                        obj.childrenBodyInfo(i) = cBodyInfo{i};
                    end
                    obj.childrenBodyNames = cbNames;
                end
                
                obj.childrenBodyInfoNeedsUpdate = false;
            end
            
            childrenBodyInfo = obj.childrenBodyInfo;
            cbNames = obj.childrenBodyNames;
        end
        
        function soiRadius = getCachedSoIRadius(obj)
            if(isnan(obj.soiRadiusCache))
                obj.soiRadiusCache = getSOIRadius(obj, obj.getParBodyInfo);
            end
            
            soiRadius = obj.soiRadiusCache;
        end
        
        function rotMat = get.bodyRotMatFromGlobalInertialToBodyInertial(obj)
            if(isempty(obj.bodyRotMatFromGlobalInertialToBodyInertial))
                obj.bodyZAxis = normVector(obj.bodyZAxis);
                obj.bodyXAxis = normVector(obj.bodyXAxis);
                
                rotY = normVector(crossARH(obj.bodyZAxis, obj.bodyXAxis));
                rotX = normVector(crossARH(rotY, obj.bodyZAxis));
                rotMat = [rotX, rotY, obj.bodyZAxis];
                
                obj.bodyRotMatFromGlobalInertialToBodyInertial = rotMat;
            else
                rotMat = obj.bodyRotMatFromGlobalInertialToBodyInertial;
            end
        end
        
        function frame = getBodyCenteredInertialFrame(obj)
            if(isempty(obj.bodyInertialFrameCache))
                obj.bodyInertialFrameCache = BodyCenteredInertialFrame(obj, obj.celBodyData);
            end
            
            frame = obj.bodyInertialFrameCache;
        end
        
        function frame = getBodyFixedFrame(obj)
            if(isempty(obj.bodyFixedFrameCache))
                obj.bodyFixedFrameCache = BodyFixedFrame(obj, obj.celBodyData);
            end
            
            frame = obj.bodyFixedFrameCache;
        end
        
        function states = getElementSetsForTimes(obj, times)
            parBodyInfo = obj.getParBodyInfo();
            if(not(isempty(parBodyInfo)))
                frame = parBodyInfo.getBodyCenteredInertialFrame();
                gmu = parBodyInfo.gm;

                [rVects, vVects] = getStateAtTime(obj, times, gmu);

                states = CartesianElementSet(times, rVects, vVects, frame);
%                 for(i=1:length(times))
%                     states(i) = CartesianElementSet(times(i), rVects(:,i), vVects(:,i), frame); %#ok<AGROW>
%                 end
            else
                frame = obj.getBodyCenteredInertialFrame();
                
                for(i=1:length(times))
                    states(i) = CartesianElementSet(times(i), [0;0;0], [0;0;0], frame); %#ok<AGROW>
                end
            end
        end
        
        function bColorRGB = getBodyRGB(obj)
            bColor = obj.bodycolor;
            
%             cmap = colormap(bColor);
            try
                cmap = feval(bColor);
            catch
                cmap = feval('gray');
                warning('Could not find a colormap for body color "%s".  Defaulting to grey.', bColor);
            end
            
            midRow = round(size(cmap,1)/2);
            bColorRGB = cmap(midRow,:);
        end
        
        function temperature = getBodyAtmoTemperature(obj, time, lat, long, alt)
            temperature = getTemperatureAtAltitude(obj, alt, lat, time, long);
        end
        
        function pressure = getBodyAtmoPressure(obj, altitude)
            pressure = getPressureAtAltitude(obj, altitude);
        end
        
        function sunDotNormal = getCachedSunDotNormal(obj, time, long)
            sunDotNormal = obj.sunDotNormalCache.getCachedBodyStateAtTimeAndLong(time, long);
        end
        
        function parentGM = getParentGmuFromCache(obj)
            if(isnan(obj.parentGmuCache) || obj.parentBodyInfoNeedsUpdate == true)
                obj.parentGmuCache = getParentGM(obj, obj.celBodyData);
                obj.parentBodyInfoNeedsUpdate = false;
            end
            
            parentGM = obj.parentGmuCache;
        end
        
        function chain = getOrbitElemsChain(obj)
            if(isempty(obj.orbitElemsChainCache))
                smas = [];
                eccs = [];
                incs = [];
                raans = [];
                args = [];
                means = [];
                epochs = [];
                parentGMs = [];

                loop = true;
                bodyInfo = obj;
                while(loop)
                    smas(end+1) = bodyInfo.sma; %#ok<AGROW>
                    eccs(end+1) = bodyInfo.ecc; %#ok<AGROW>
                    incs(end+1) = bodyInfo.inc; %#ok<AGROW>
                    raans(end+1) = bodyInfo.raan; %#ok<AGROW>
                    args(end+1) = bodyInfo.arg; %#ok<AGROW>
                    means(end+1) = bodyInfo.mean; %#ok<AGROW>
                    epochs(end+1) = bodyInfo.epoch; %#ok<AGROW>

                    try
                        thisParentBodyInfo = bodyInfo.getParBodyInfo(obj.celBodyData);
                    catch 
                        thisParentBodyInfo = getParentBodyInfo(bodyInfo, obj.celBodyData);
                    end

                    if(isempty(thisParentBodyInfo))
                        break;
                    else
                        parentGMs(end+1) = bodyInfo.getParentGmuFromCache(); %#ok<AGROW>

                        bodyInfo = thisParentBodyInfo;
                    end
                end
                
                obj.orbitElemsChainCache = {smas, eccs, incs, raans, args, means, epochs, parentGMs};
            end
            
            chain = obj.orbitElemsChainCache;
        end
        
        function inputs = getFixedFrameFromInertialFrameInputsCache(obj)
            if(isempty(obj.fixedFrameFromInertialFrameCache))
                obj.fixedFrameFromInertialFrameCache = {obj.rotperiod, obj.rotini};
            end
            
            inputs = obj.fixedFrameFromInertialFrameCache;
        end
        
        function [surfTexture] = getSurfaceTexture(obj)
            if(isempty(obj.surfTextureCache))
                if(not(isempty(obj.surftexturefile)))
                    try
                        [I,~] = imread(obj.surftexturefile);
                        I = flip(I, 1);
                    catch ME
                        I = NaN;
                        warning('Could not load surface texture for "%s".  Message: \n\n%s', obj.name, ME.message);
                    end

                    obj.surfTextureCache = I;
                else
                    obj.surfTextureCache = NaN;
                end
            end
            
            surfTexture = obj.surfTextureCache;
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
            
            if(isempty(tf))
                tf = false;
            end
        end
    end
    
	methods(Static)
        function obj = loadobj(obj)   
            if(isempty(obj.epoch))
                return; %this should only happen if something is bugged out
            end
            
            obj.doNotUseAtmoTempSunMultCurve = isa(obj.atmotempsunmultcurve,'griddedInterpolant') && all(obj.atmotempsunmultcurve.Values == 0);
            obj.doNotUseLatTempSunMultCurve = isa(obj.lattempsunmultcurve,'griddedInterpolant') && all(obj.lattempsunmultcurve.Values == 0);
            obj.doNotUseAxialTempSunMultCurve = isa(obj.axialtempsunmultcurve,'griddedInterpolant') && all(obj.axialtempsunmultcurve.Values == 0);
            obj.doNotUseAxialTempSunBiasCurveGI = isa(obj.axialtempsunbiascurve,'griddedInterpolant') && all(obj.axialtempsunbiascurve.Values == 0);
            obj.doNotUseEccTempBiasCurveGI = isa(obj.ecctempbiascurve,'griddedInterpolant') && all(obj.ecctempbiascurve.Values == 0);
            obj.doNotUseAtmoPressCurveGI = (obj.atmohgt > 0 && isempty(obj.atmopresscurve));
            
            obj.parentBodyInfoNeedsUpdate = true;
            obj.getParBodyInfo(obj.celBodyData);
            
            obj.childrenBodyInfoNeedsUpdate = true;
            obj.getChildrenBodyInfo(obj.celBodyData);
            
            if(isempty(obj.sunDotNormalCache))
                obj.sunDotNormalCache = SunDotNormalDataCache(obj);
            end
            
            if(isempty(obj.atmoTempCache))
                obj.atmoTempCache = AtmoTempDataCache(obj);
            end
            
            if(isempty(obj.surftexturefile) && strcmpi(obj.name,'Kerbin') && obj.id == 1)
                obj.surftexturefile = 'images/body_textures/surface/kerbinSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Mun') && obj.id == 2)
                obj.surftexturefile = 'images/body_textures/surface/munSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Minmus') && obj.id == 3)
                obj.surftexturefile = 'images/body_textures/surface/minmusSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Moho') && obj.id == 4)
                obj.surftexturefile = 'images/body_textures/surface/mohoSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Eve') && obj.id == 5)
                obj.surftexturefile = 'images/body_textures/surface/eveSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Gilly') && obj.id == 13)
                obj.surftexturefile = 'images/body_textures/surface/gillySurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Duna') && obj.id == 6)
                obj.surftexturefile = 'images/body_textures/surface/dunaSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Ike') && obj.id == 7)
                obj.surftexturefile = 'images/body_textures/surface/ikeSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Dres') && obj.id == 15)
                obj.surftexturefile = 'images/body_textures/surface/dresSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Laythe') && obj.id == 9)
                obj.surftexturefile = 'images/body_textures/surface/laytheSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Vall') && obj.id == 10)
                obj.surftexturefile = 'images/body_textures/surface/vallSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Tylo') && obj.id == 12)
                obj.surftexturefile = 'images/body_textures/surface/tyloSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Bop') && obj.id == 11)
                obj.surftexturefile = 'images/body_textures/surface/bopSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Pol') && obj.id == 14)
                obj.surftexturefile = 'images/body_textures/surface/polSurface.png';
                
            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Eeloo') && obj.id == 16)
                obj.surftexturefile = 'images/body_textures/surface/eelooSurface.png';
                
            end
        end
        
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
            bodyObj.celBodyData = bodyInfo.celBodyData;
            
            bodyObj.bodyZAxis = bodyInfo.bodyZAxis;
            bodyObj.bodyXAxis = bodyInfo.bodyXAxis;
            bodyObj.bodyRotMatFromGlobalInertialToBodyInertial = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial;
        end
    end
end

