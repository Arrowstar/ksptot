classdef KSPTOT_BodyInfo < matlab.mixin.SetGet
    %KSPTOT_BodyInfo Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Orbit
        epoch double
        sma double
        ecc double
        inc double
        raan double
        arg double
        mean double
        
        %Physical
        gm double
        radius double
        
        %Atmo
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
        
        %Rotation
        rotperiod double
        rotini double
        
        %Display
        bodycolor char
        
        %Others
        canbecentral double
        canbearrivedepart double
        parent
        parentid double
        name char
        id double
        
        %body surface textures
        surftexturefile (1,:) char = '';
        surftexturezrotoffset(1,1) double = 0; %degrees

        %body height map
        heightmapfile(1,:) char = '';
        heightmapoffset(1,1) double = 0; %m
        heightmapdeformity(1,1) double = 0; %m
        
        %orientation of inertial frame (spin axis handling)
        bodyzaxis(3,1) double = [0;0;1];
        bodyxaxis(3,1) double = [1;0;0];
        bodyRotMatFromGlobalInertialToBodyInertial = [];
        
        %Propagation type
        proptype(1,:) char = 'analytic_two_body';
        propTypeEnum(1,1) BodyPropagationTypeEnum = BodyPropagationTypeEnum.TwoBody
        numIntStateCache CelestialBodySunRelStateDataCache

        %non-spherical gravity
        usenonsphericalgrav(1,1) logical = false;
        nonsphericalgavdatafile(1,:) char = '';
        nonsphericalgravmaxdeg(1,1) double = 0;
        nonSphericalGravC double = [];
        nonSphericalGravS double = [];
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
        heightMapCache
        
        lastComputedTime = NaN;
        lastComputedRVect = NaN(3,1);
        lastComputedVVect = NaN(3,1);
        
        lastComputedRVectVVect = [];

        lastComputedSunTime = NaN;
        lastComputedSunRVect = NaN(3,1);
        lastComputedSunVVect = NaN(3,1);
        
        propTypeIsTwoBody(1,1) logical = true;
        propTypeIsNumerical(1,1) logical = false;
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
            obj.numIntStateCache = CelestialBodySunRelStateDataCache(obj);
            
            obj.bodyInertialFrameCache = BodyCenteredInertialFrame(obj, obj.celBodyData);
            obj.bodyFixedFrameCache = BodyFixedFrame(obj, obj.celBodyData);
            
            if(obj.propTypeEnum == BodyPropagationTypeEnum.TwoBody)
                obj.propTypeIsTwoBody = true;
                obj.propTypeIsNumerical = false;
            elseif(obj.propTypeEnum == BodyPropagationTypeEnum.Numerical)
                obj.propTypeIsTwoBody = false;
                obj.propTypeIsNumerical = true;
            end
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
        
        function set.propTypeEnum(obj, newValue)
            obj.propTypeEnum = newValue;
            
            if(obj.propTypeEnum == BodyPropagationTypeEnum.TwoBody)
                obj.propTypeIsTwoBody = true; %#ok<MCSUP>
                obj.propTypeIsNumerical = false; %#ok<MCSUP>
            elseif(obj.propTypeEnum == BodyPropagationTypeEnum.Numerical)
                obj.propTypeIsTwoBody = false; %#ok<MCSUP>
                obj.propTypeIsNumerical = true; %#ok<MCSUP>
            end 
        end
        
        function parentBodyInfo = getParBodyInfo(obj, ~)
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
                    for(i=1:length(cBodyInfo)) %#ok<*NO4LP> 
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
%             if(isnan(obj.soiRadiusCache))
%                 obj.soiRadiusCache = getSOIRadius(obj, obj.getParBodyInfo);
%             end
            
            soiRadius = [obj.soiRadiusCache];
        end

        function setCachedSoIRadius(obj)
            obj.soiRadiusCache = getSOIRadius(obj, obj.getParBodyInfo);
        end
        
        function rotMat = get.bodyRotMatFromGlobalInertialToBodyInertial(obj)
            if(isempty(obj.bodyRotMatFromGlobalInertialToBodyInertial))
                obj.bodyzaxis = normVector(obj.bodyzaxis);
                obj.bodyxaxis = normVector(obj.bodyxaxis);
                
                rotY = normVector(crossARH(obj.bodyzaxis, obj.bodyxaxis));
                rotX = normVector(crossARH(rotY, obj.bodyzaxis));
                rotMat = [rotX, rotY, obj.bodyzaxis];
                
                obj.bodyRotMatFromGlobalInertialToBodyInertial = rotMat;
            else
                rotMat = obj.bodyRotMatFromGlobalInertialToBodyInertial;
            end
        end
        
        function frame = getBodyCenteredInertialFrame(obj)
%             if(isempty(obj.bodyInertialFrameCache))
%                 obj.bodyInertialFrameCache = BodyCenteredInertialFrame(obj, obj.celBodyData);
%             end
            
            frame = obj.bodyInertialFrameCache;
        end
        
        function frame = getBodyFixedFrame(obj)
%             if(isempty(obj.bodyFixedFrameCache))
%                 obj.bodyFixedFrameCache = BodyFixedFrame(obj, obj.celBodyData);
%             end
            
            frame = obj.bodyFixedFrameCache;
        end
        
        function states = getElementSetsForTimes(obj, times)
            parBodyInfo = obj.getParBodyInfo();
            if(not(isempty(parBodyInfo)))
                frame = parBodyInfo.getBodyCenteredInertialFrame();
                gmu = obj.getParentGmuFromCache();

                [rVects, vVects] = getStateAtTime(obj, times, gmu);

                states = CartesianElementSet(times, rVects, vVects, frame);
            else
                frame = obj.getBodyCenteredInertialFrame();
                
                for(i=1:length(times))
                    states(i) = CartesianElementSet(times(i), [0;0;0], [0;0;0], frame); %#ok<AGROW>
                end
            end
        end

        function [rVect, vVect] = getCachedPositionVelWrtSun(obj, time)
            if(numel(time) == 1)
                if(time == obj.lastComputedTime)
                    rVect = obj.lastComputedRVect;
                    vVect = obj.lastComputedVVect;
                else
                    [rVect, vVect] = getPositOfBodyWRTSun(time, obj, obj.celBodyData);
    
                    obj.lastComputedRVect = rVect;
                    obj.lastComputedVVect = vVect;
                end
            else
                [rVect, vVect] = getPositOfBodyWRTSun(time, obj, obj.celBodyData);
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
        
        % function chain = getOrbitElemsChain(obj)
        %     if(isempty(obj.orbitElemsChainCache) || obj.orbitElemsChainCache{1}(end) ~= 0)
        %         obj.generateOrbitChainCache();
        %     end
        % 
        %     chain = obj.orbitElemsChainCache;
        % end

        function chain = getOrbitElemsChain(obj) %claude generated this function: https://claude.ai/chat/716a66cc-f4cd-43c5-983c-adeda985397b
            cache = obj.orbitElemsChainCache;
            
            if isempty(cache) || cache{1}(end) ~= 0
                obj.generateOrbitChainCache();
                cache = obj.orbitElemsChainCache;
            end
            
            chain = cache;
        end

        function generateOrbitChainCache(obj)
            smas = [];
            eccs = [];
            incs = [];
            raans = [];
            args = [];
            means = [];
            epochs = [];
            parentGMs = [];
            rotFramesBodyToGI = zeros(3,3,0);

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
                rotFramesBodyToGI(:,:,end+1)  = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial'; %#ok<AGROW>

                try
                    thisParentBodyInfo = bodyInfo.getParBodyInfo(obj.celBodyData);
                catch 
                    thisParentBodyInfo = getParentBodyInfo(bodyInfo, obj.celBodyData);
                end

                if(isempty(thisParentBodyInfo))
                    parentGMs(end+1) = 0; %#ok<AGROW> 
                    
                    break;
                else
                    parentGMs(end+1) = bodyInfo.getParentGmuFromCache(); %#ok<AGROW>

                    bodyInfo = thisParentBodyInfo;
                end
            end
            
            obj.orbitElemsChainCache = {smas, eccs, incs, raans, args, means, epochs, parentGMs, rotFramesBodyToGI};
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

        function heightMapGI = getHeightMap(obj)
            if(isempty(obj.heightMapCache))
                if(not(isempty(obj.heightmapfile)))
                    try
                        [I,~] = imread(obj.heightmapfile);
                        I = double(rgb2gray(I))/255;

                        y1 = obj.heightmapoffset;
                        y2 = obj.heightmapoffset + obj.heightmapdeformity;
                        heightMapPts = (((y2 - y1)/(1 - 0)) .* (I - 0) + y1) / 1000;

                        gi = griddedInterpolant({linspace(-pi/2,pi/2,height(heightMapPts)), linspace(-pi,pi,width(heightMapPts))}, heightMapPts);
                    catch ME
                        gi = griddedInterpolant({[-pi/2 pi/2], [-pi pi]}, zeros(2,2));

                        warning('Could not load height map for "%s".  Message: \n\n%s', obj.name, ME.message);
                    end

                    obj.heightMapCache = gi;
                else
                    obj.heightMapCache = griddedInterpolant({[-pi/2 pi/2], [-pi pi]}, zeros(2,2));
                end
            end
            
            heightMapGI = obj.heightMapCache;
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
            
            if(isempty(tf))
                tf = false;
            end
        end
        
        function setPropTypeEnum(obj)
            switch obj.proptype
                case 'analytic_two_body'
                    obj.propTypeEnum = BodyPropagationTypeEnum.TwoBody;
                case 'numerical_integration'
                    obj.propTypeEnum = BodyPropagationTypeEnum.Numerical;
                otherwise
                    error('Unknown Body Prop Type: %s', obj.propType);
            end
        end
        
        function setStateCacheData(obj, times, stateVects, frame)
            obj.numIntStateCache.setStateData(times, stateVects, frame);
        end
    end
    
    methods
        function setBaseBodySurfaceTexture(obj)
            if(isempty(obj.surftexturefile) && strcmpi(obj.name,'Sun') && obj.id == 0)
                obj.surftexturefile = 'images/body_textures/surface/sunSurface.jpg';

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Kerbin') && obj.id == 1)
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

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Jool') && obj.id == 8)
                obj.surftexturefile = 'images/body_textures/surface/joolSurface.png';
                
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

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Mercury') && obj.id == 199)
                obj.surftexturefile = 'images/body_textures/surface/mercurySurface.png';

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Venus') && obj.id == 299)
                obj.surftexturefile = 'images/body_textures/surface/venusSurface.png';

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Earth') && obj.id == 399)
                obj.surftexturefile = 'images/body_textures/surface/earthSurface.png';

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Moon') && obj.id == 301)
                obj.surftexturefile = 'images/body_textures/surface/moonSurface.png';

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Mars') && obj.id == 499)
                obj.surftexturefile = 'images/body_textures/surface/marsSurface.png';

            elseif(isempty(obj.surftexturefile) && strcmpi(obj.name,'Pluto') && obj.id == 999)
                obj.surftexturefile = 'images/body_textures/surface/plutoSurface.png';
            end
        end

        function setBaseBodyHeightMap(obj)
            if(isempty(obj.heightmapfile) && strcmpi(obj.name,'Kerbin') && obj.id == 1)
                obj.heightmapfile = 'images/body_textures/heightmap/kerbinheightmap.png';
                obj.heightmapoffset = -1985;
                obj.heightmapdeformity = 10720;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Mun') && obj.id == 2)
                obj.heightmapfile = 'images/body_textures/heightmap/munheightmap.png';
                obj.heightmapoffset = -400;
                obj.heightmapdeformity = 8700;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Minmus') && obj.id == 3)
                obj.heightmapfile = 'images/body_textures/heightmap/minmusheightmap.png';
                obj.heightmapoffset = 0;
                obj.heightmapdeformity = 6000;

            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Moho') && obj.id == 4)
                obj.heightmapfile = 'images/body_textures/heightmap/mohoheightmap.png';
                obj.heightmapoffset = -700;
                obj.heightmapdeformity = 8900;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Eve') && obj.id == 5)
                obj.heightmapfile = 'images/body_textures/heightmap/eveheightmap.png';
                obj.heightmapoffset = -2000;
                obj.heightmapdeformity = 11000;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Gilly') && obj.id == 13)
                obj.heightmapfile = 'images/body_textures/heightmap/gillyheightmap.png';
                obj.heightmapoffset = -8000;
                obj.heightmapdeformity = 16150;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Duna') && obj.id == 6)
                obj.heightmapfile = 'images/body_textures/heightmap/dunaheightmap.png';
                obj.heightmapoffset = -500;
                obj.heightmapdeformity = 11000;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Ike') && obj.id == 7)
                obj.heightmapfile = 'images/body_textures/heightmap/ikeheightmap.png';
                obj.heightmapoffset = -12100;
                obj.heightmapdeformity = 25800;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Dres') && obj.id == 15)
                obj.heightmapfile = 'images/body_textures/heightmap/dresheightmap.png';
                obj.heightmapoffset = -2100;
                obj.heightmapdeformity = 9200;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Laythe') && obj.id == 9)
                obj.heightmapfile = 'images/body_textures/heightmap/laytheheightmap.png';
                obj.heightmapoffset = -2900;
                obj.heightmapdeformity = 10800;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Vall') && obj.id == 10)
                obj.heightmapfile = 'images/body_textures/heightmap/vallheightmap.png';
                obj.heightmapoffset = -3100;
                obj.heightmapdeformity = 11200;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Tylo') && obj.id == 12)
                obj.heightmapfile = 'images/body_textures/heightmap/tyloheightmap.png';
                obj.heightmapoffset = -3000;
                obj.heightmapdeformity = 20000;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Bop') && obj.id == 11)
                obj.heightmapfile = 'images/body_textures/heightmap/bopheightmap.png';
                obj.heightmapoffset = -24000;
                obj.heightmapdeformity = 48600;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Pol') && obj.id == 14)
                obj.heightmapfile = 'images/body_textures/heightmap/polheightmap.png';
                obj.heightmapoffset = -3800;
                obj.heightmapdeformity = 10200;
                
            elseif(isempty(obj.heightmapfile) && strcmpi(obj.name,'Eeloo') && obj.id == 16)
                obj.heightmapfile = 'images/body_textures/heightmap/eelooheightmap.png';
                obj.heightmapoffset = -900;
                obj.heightmapdeformity = 5840;
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
            
            obj.setBaseBodySurfaceTexture();
            obj.setBaseBodyHeightMap();
            
            if(isempty(obj.sunDotNormalCache))
                obj.sunDotNormalCache = SunDotNormalDataCache(obj);
            end
            
            if(isempty(obj.atmoTempCache))
                obj.atmoTempCache = AtmoTempDataCache(obj);
            end
            
            if(isempty(obj.numIntStateCache))
                obj.numIntStateCache = CelestialBodySunRelStateDataCache(obj);
            end
                        
            obj.setPropTypeEnum();
            
            if(isempty(obj.bodyInertialFrameCache))
                obj.bodyInertialFrameCache = BodyCenteredInertialFrame(obj, obj.celBodyData);

            elseif(isempty(obj.bodyInertialFrameCache.getOriginBody()))
                obj.bodyInertialFrameCache.setOriginBody(obj);
            end
            
            if(isempty(obj.bodyFixedFrameCache))
                obj.bodyFixedFrameCache = BodyFixedFrame(obj, obj.celBodyData);
            elseif(isempty(obj.bodyFixedFrameCache.getOriginBody()))
                obj.bodyFixedFrameCache.setOriginBody(obj);
            end
            
            if(obj.propTypeEnum == BodyPropagationTypeEnum.TwoBody)
                obj.propTypeIsTwoBody = true;
                obj.propTypeIsNumerical = false;
            elseif(obj.propTypeEnum == BodyPropagationTypeEnum.Numerical)
                obj.propTypeIsTwoBody = false;
                obj.propTypeIsNumerical = true;
            end

            if(obj.usenonsphericalgrav && obj.nonsphericalgravmaxdeg > 0 && exist(obj.nonsphericalgavdatafile,'file'))
                [obj.nonSphericalGravC, obj.nonSphericalGravS, maxOrderDeg] = getSphericalHarmonicsMatricesFromFile(obj.nonsphericalgavdatafile);

                if(obj.nonsphericalgravmaxdeg > maxOrderDeg)
                    obj.nonsphericalgravmaxdeg = maxOrderDeg;
                end
            elseif(obj.usenonsphericalgrav == true)
                obj.usenonsphericalgrav = false;
                msg = sprintf('Non-spherical gravity for body %s is enabled but either the max degree/order is less than 1 or the gravity model data file does not exist.  Reverting to standard spherical gravity.', obj.name);
                warning(msg);
                msgbox(msg, 'Sperhical Harmonics Gravity Error.', 'error', 'non-modal');
            end

            obj.setCachedSoIRadius();
            obj.generateOrbitChainCache();
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

