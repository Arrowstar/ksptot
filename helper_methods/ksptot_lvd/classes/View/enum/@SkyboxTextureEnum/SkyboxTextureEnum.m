classdef SkyboxTextureEnum < matlab.mixin.SetGet
    %SkyboxTextureEnum  Enumerated skybox textures for LVD 3D view.
    %
    %   Provides a typed, validated set of skybox images located in
    %   images/skyboxes.  Includes a Custom value for user-supplied files.
    
    enumeration
        DarkStars    ('DarkStarsSkyBox.png',    'Dark Stars')
        DefaultKsp   ('DefaultKspSkyBox.png',   'Default KSP')
        MilkyWay     ('MilkyWaySkyBox.png',     'Milky Way')
        CrabNebula   ('CrabNebulaSkyBox.png',   'Crab Nebula')
        Eso0932a     ('eso0932a.png',           'ESO 0932a')
        Custom       ('',                       'Custom...')
    end
    
    properties(SetAccess=immutable)
        fileName(1,1) string
        displayName(1,1) string
    end
    
    methods
        function obj = SkyboxTextureEnum(fileName, displayName)
            obj.fileName = string(fileName);
            obj.displayName = string(displayName);
        end
        
        function tf = isCustom(obj)
            tf = obj == SkyboxTextureEnum.Custom;
        end
        
        function fullPath = getFullPath(obj, customPath)
            %getFullPath  Resolve absolute file path for this texture.
            arguments
                obj(1,1) SkyboxTextureEnum
                customPath(1,1) string = ""
            end
            if obj.isCustom()
                if strlength(customPath) == 0
                    fullPath = string.empty(1,0);
                    return;
                end
                fullPath = customPath;
                return;
            end
            
            % Try relative to this class folder -> images/skyboxes
            try
                classFolder = fileparts(mfilename('fullpath'));
                % classFolder = .../classes/View/enum/@SkyboxTextureEnum
                candidate = fullfile(classFolder, '..', '..', '..', '..', '..', 'images', 'skyboxes', char(obj.fileName));
                candidate = string(GetFullPath(candidate));
                if isfile(candidate)
                    fullPath = candidate;
                    return;
                end
            catch
                % fall through
            end
            
            % Fallback: which on bare filename
            w = which(char(obj.fileName));
            if ~isempty(w)
                fullPath = string(w);
                return;
            end
            
            % Last resort: search images/skyboxes via relative to pwd
            fullPath = obj.fileName;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('SkyboxTextureEnum');
            listBoxStr = string({m.displayName});
            listBoxStr = cellstr(listBoxStr);
        end
        
        function [ind, enum] = getIndForDisplayName(displayName)
            m = enumeration('SkyboxTextureEnum');
            ind = find(string({m.displayName}) == string(displayName), 1, 'first');
            if isempty(ind)
                ind = 1;
            end
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SkyboxTextureEnum');
            ind = find(string({m.displayName}) == string(nameStr), 1, 'first');
            if isempty(ind)
                ind = 1;
            end
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForFileName(fileName)
            m = enumeration('SkyboxTextureEnum');
            fileName = string(fileName);
            % compare bare filename
            for i=1:numel(m)
                if m(i).fileName == fileName || endsWith(fileName, m(i).fileName, 'IgnoreCase',true)
                    enum = m(i);
                    ind = i;
                    return;
                end
            end
            % Unknown -> Custom
            enum = SkyboxTextureEnum.Custom;
            ind = find(m == enum, 1, 'first');
        end
        
        function [ind, enum] = getIndForName(name)
            % legacy compat: name is enumeration member name
            m = enumeration('SkyboxTextureEnum');
            ind = find(string({m.displayName}) == string(name), 1, 'first');
            if isempty(ind)
                [enum, ind] = SkyboxTextureEnum.getEnumForFileName(name);
            else
                enum = m(ind);
            end
        end
        
        function allFiles = getAllFileNames()
            m = enumeration('SkyboxTextureEnum');
            allFiles = string({m.fileName});
            allFiles(allFiles == "") = [];
        end
    end
end

function p = GetFullPath(p)
    % portable full path canonicalization without java dependency
    try
        p = char(java.io.File(p).getCanonicalPath());
    catch
        % fallback: just return as-is
    end
end
