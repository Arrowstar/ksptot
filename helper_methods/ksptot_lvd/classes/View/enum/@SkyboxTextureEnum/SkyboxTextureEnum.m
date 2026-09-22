classdef SkyboxTextureEnum < matlab.mixin.SetGet
    %SkyboxTextureEnum  Enumerated skybox textures for LVD 3D view.
    %
    %   Provides a typed, validated set of skybox textures located in
    %   images/skyboxes as 6-face cubemap folders (px,nx,py,ny,pz,nz.png).
    %   Includes a Custom value, which is reserved but not supported for
    %   rendering in this release (built-ins only).
    
    enumeration
        DarkStars    ('DarkStarsSkyBox.png',    'Dark Stars',    'DarkStarsSkyBox')
        DefaultKsp   ('DefaultKspSkyBox.png',   'Default KSP',   'DefaultKspSkyBox')
        MilkyWay     ('MilkyWaySkyBox.png',     'Milky Way',     'MilkyWaySkyBox')
        CrabNebula   ('CrabNebulaSkyBox.png',   'Crab Nebula',   'CrabNebulaSkyBox')
        Eso0932a     ('eso0932a.png',           'ESO 0932a',     'eso0932a')
        Custom       ('',                       'Custom...',     '')
    end
    
    properties(SetAccess=immutable)
        fileName(1,1) string % legacy equirect file (deprecated compat: dropdown + skyBoxImgFileName)
        displayName(1,1) string
        cubeFolderName(1,1) string % 6-face cubemap folder under images/skyboxes (px,nx,py,ny,pz,nz.png)
    end
    
    methods
        function obj = SkyboxTextureEnum(fileName, displayName, cubeFolderName)
            obj.fileName = string(fileName);
            obj.displayName = string(displayName);
            if nargin > 2
                obj.cubeFolderName = string(cubeFolderName);
            else
                obj.cubeFolderName = "";
            end
        end
        
        function tf = isCustom(obj)
            tf = obj == SkyboxTextureEnum.Custom;
        end
        
        function fullPath = getFullPath(obj, customPath)
            %getFullPath  Resolve absolute file path for the LEGACY single-file
            %equirect texture.  Deprecated: cubemap rendering uses
            %getCubemapDir/getFacePath instead.  Kept for migration compat.
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
            % (@SkyboxTextureEnum is 6 levels below the repo root)
            try
                classFolder = fileparts(mfilename('fullpath'));
                % classFolder = .../classes/View/enum/@SkyboxTextureEnum
                candidate = fullfile(classFolder, '..', '..', '..', '..', '..', '..', 'images', 'skyboxes', char(obj.fileName));
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
        
        function tf = hasCubemap(obj)
            %hasCubemap  True when this texture maps to a 6-face folder.
            arguments
                obj(1,1) SkyboxTextureEnum
            end
            tf = ~obj.isCustom() && strlength(obj.cubeFolderName) > 0;
        end
        
        function dirPath = getCubemapDir(obj)
            %getCubemapDir  Resolve absolute path of the 6-face folder
            %(px,nx,py,ny,pz,nz.png).  Returns "" when unavailable.
            arguments
                obj(1,1) SkyboxTextureEnum
            end
            dirPath = "";
            if ~obj.hasCubemap()
                return;
            end
            try
                classFolder = fileparts(mfilename('fullpath'));
                % classFolder = .../classes/View/enum/@SkyboxTextureEnum
                % (6 levels below the repo root, which holds images/)
                candidate = fullfile(classFolder, '..', '..', '..', '..', '..', '..', 'images', 'skyboxes', char(obj.cubeFolderName));
                candidate = string(GetFullPath(candidate));
                if isfolder(candidate)
                    dirPath = candidate;
                    return;
                end
            catch
            end
            % Fallback: folder resolvable from pwd or path
            try
                if exist(char(obj.cubeFolderName),'dir')==7
                    dirPath = string(GetFullPath(char(obj.cubeFolderName)));
                    return;
                end
            catch
            end
        end
        
        function facePath = getFacePath(obj, face)
            %getFacePath  Full path of one cubemap face ('px','nx','py','ny','pz','nz').
            arguments
                obj(1,1) SkyboxTextureEnum
                face(1,1) string {mustBeMember(face,["px","nx","py","ny","pz","nz"])}
            end
            facePath = "";
            d = obj.getCubemapDir();
            if strlength(d) > 0
                facePath = string(fullfile(char(d), char(face + ".png")));
            end
        end
        
        function previewPath = getPreviewFacePath(obj)
            %getPreviewFacePath  +X face path for settings-UI preview.
            arguments
                obj(1,1) SkyboxTextureEnum
            end
            previewPath = obj.getFacePath("px");
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
            % compare bare filename, legacy .png name, or cubemap folder/face path
            for i=1:numel(m)
                if m(i).fileName == fileName || endsWith(fileName, m(i).fileName, 'IgnoreCase',true)
                    enum = m(i);
                    ind = i;
                    return;
                end
                if strlength(m(i).cubeFolderName) > 0
                    cf = m(i).cubeFolderName;
                    if cf == fileName || endsWith(fileName, cf, 'IgnoreCase',true) || ...
                            endsWith(fileName, cf + "/px.png", 'IgnoreCase',true) || ...
                            endsWith(fileName, cf + "\px.png", 'IgnoreCase',true)
                        enum = m(i);
                        ind = i;
                        return;
                    end
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
