classdef CelestialBodyData < matlab.mixin.SetGet & dynamicprops
    %CelestialBodyData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access=private)
        bodies(1,:) KSPTOT_BodyInfo
        
        bodyIdCacheArr(1,:) double = [];
    end
    
    properties(Transient,Access=private)
        topLvlBodyCache KSPTOT_BodyInfo
    end
    
    methods
        function obj = CelestialBodyData(celBodyData)
            if(isstruct(celBodyData))
                bodyNameFields = fields(celBodyData);
                
                for(i=1:length(bodyNameFields))
                    bodyName = bodyNameFields{i};
                    
                    if(not(isprop(obj,bodyName)))
                        addprop(obj,bodyName);
                        bodyInfo = celBodyData.(bodyName);
                        
                        obj.(bodyName) = bodyInfo;
                        obj.bodies(end+1) = bodyInfo;
                    else
                        error('The following body already exists in CelestialBodyData when trying to instantiate the class from the celestial body data structure: %s', bodyName);
                    end
                end
                
            elseif(isa(celBodyData,'CelestialBodyData'))
                obj = celBodyData;
                
            else
                error('Input to CelestialBodyData must be the structure representation of celestial body data.');
            end
            
            for(i=1:length(obj.bodies))
                if(isstruct(obj.bodies(i).celBodyData) || isempty(obj.bodies(i).celBodyData))
                    obj.bodies(i).celBodyData = obj;
                end
            end
            
            obj.bodyIdCacheArr = [obj.bodies.id];
        end
        
        function resetAllParentNeedsUpdateFlags(obj)
            for(i=1:length(obj.bodies))
                obj.bodies(i).parentBodyInfoNeedsUpdate = true;
            end
        end
        
        function bodyInfo = getBodyInfoById(obj, bodyId)
%             arr = [obj.bodies.id];
            bodyInfo = obj.bodies(obj.bodyIdCacheArr == bodyId);
            bodyInfo = bodyInfo(1);
        end
        
        %Override the following structure methods for backwards
        %compatibility with structure celBodyData
        function f = fields(obj)
            f = {};
            
            for(i=1:length(obj.bodies))
                f{end+1} = lower(obj.bodies(i).name); %#ok<AGROW>
            end
            
            f = f(:);
        end
        
        function f = fieldnames(obj)
            f = obj.fields();
        end
        
        function tf = isfield(obj,field)
            tf = isprop(obj,field);
        end
        
        function allBodyInfo = getAllBodyInfo(obj)
            allBodyInfo = obj.bodies;
        end
        
        function topLvlBody = getTopLevelBody(obj)
            if(isempty(obj.topLvlBodyCache))
                obj.topLvlBodyCache = getTopLevelCentralBody(obj);
            end
            
            topLvlBody = obj.topLvlBodyCache;
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            obj.bodyIdCacheArr = [obj.bodies.id];
            
            if(isprop(obj,'sun'))
                obj.topLvlBodyCache = getTopLevelCentralBody(obj);
            end
        end
    end
end

