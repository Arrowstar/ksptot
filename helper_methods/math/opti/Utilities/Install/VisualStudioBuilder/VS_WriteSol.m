function solPath = VS_WriteSol(projStruct,vsver)
%VS_WriteSol  Create a Visual Studio Solution from Passed Project Structures
%
%   This function attempts to automatically create a Visual Studio Solution
%   from supplied project description structures.

if(~isstruct(projStruct))
    error('The supplied argument must be a structure');
end
if(nargin < 2), vsver = 'VS2017'; end
len = numel(projStruct);
PATHS = cell(len,1);
IDS = cell(len,1);
s = warning('off','MATLAB:MKDIR:DirectoryExists');
%Convert toolset into MS ver
switch(lower(vsver))
    case {'vs2010','2010','v100'}
        toolset = 'v100';
    case {'vs2012','2012','v110'}
        toolset = 'v110';
    case {'vs2013','2013','v120'}
        toolset = 'v120';
    case {'vs2015','2015','v140'}
        toolset = 'v140';
    case {'vs2017','2017','v141'}
        toolset = 'v141';
    otherwise
        error('Unknown Visual Studio Version! Only VS2010, VS2012, VS2013, VS2015, VS2017 accepted');
end

fprintf('Generating Visual Studio Projects and Solution:\n');
try
    %For each structure
    for i = 1:len
        %Check required fields
        pStr = projStruct(i);
        checkProjStruct(pStr,i);
        %Add required fields
        if(~isfield(pStr,'hdrs')), pStr.hdrs = []; end
        if(~isfield(pStr,'opts')), pStr.opts = []; end
        if(~isfield(pStr.opts,'toolset') || isempty(pStr.opts.toolset))
            pStr.opts.toolset = toolset; %configure compiler
        end
        %Build Each Project
        fprintf('Writing Project ''%s'' (%d of %d)... ',pStr.name,i,len);
        [PATHS{i},IDS{i}] = VS_WriteProj(pStr.sdir,pStr.name,pStr.hdrs,pStr.opts);
        fprintf('Done\n');
    end
catch ME
    warning(s);
    rethrow(ME);
end
warning(s);

%Create Solution File
fprintf('Writing Solution ''%s''...',projStruct(1).name);
solPath = [PATHS{1} filesep projStruct(1).name '.sln'];
fid = fopen(solPath,'w+');
if(fid < 0), error('Error writing solution file'); end  
try
    if(strcmpi(toolset,'v141'))
        fprintf(fid,'Microsoft Visual Studio Solution File, Format Version 12.00\n# Visual Studio 15\n'); 
    elseif(strcmpi(toolset,'v140'))
        fprintf(fid,'Microsoft Visual Studio Solution File, Format Version 14.00\n# Visual Studio 2015\n'); 
    elseif(strcmpi(toolset,'v120'))
        fprintf(fid,'Microsoft Visual Studio Solution File, Format Version 12.00\n# Visual Studio 2013\n');  
    elseif(strcmpi(toolset,'v110'))
        fprintf(fid,'Microsoft Visual Studio Solution File, Format Version 12.00\n# Visual Studio 2012\n');        
    elseif(strcmpi(toolset,'v100'))
        fprintf(fid,'Microsoft Visual Studio Solution File, Format Version 11.00\n# Visual Studio 2010\n');
    else
        error('Unknown toolset');
    end
    %Get Solution ID
    solID = getProjGUID;
    %Declare Each Project
    for i = 1:len
        %See if Fortran Project
        if(~isfield(projStruct(i),'opts') || ~isfield(projStruct(i).opts,'cpp') || projStruct(i).opts.cpp == true)
            isFort = false;
        else
            isFort = true;
        end
        if(i==1)
            if(isFort)
                fprintf(fid,'Project("{%s}") = "%s", "%s.vfproj", "{%s}"\n',solID,projStruct(1).name,projStruct(1).name,IDS{i});
            else
                fprintf(fid,'Project("{%s}") = "%s", "%s.vcxproj", "{%s}"\n',solID,projStruct(1).name,projStruct(1).name,IDS{i});
            end
        else
            if(isFort)
                fprintf(fid,'Project("{%s}") = "%s", "%s%s%s.vfproj", "{%s}"\n',solID,projStruct(i).name,PATHS{i},filesep,projStruct(i).name,IDS{i});
            else
                fprintf(fid,'Project("{%s}") = "%s", "%s%s%s.vcxproj", "{%s}"\n',solID,projStruct(i).name,PATHS{i},filesep,projStruct(i).name,IDS{i});
            end
        end
        fprintf(fid,'EndProject\nGlobal\n');
    end
    fprintf(fid,'\tGlobalSection(SolutionConfigurationPlatforms) = preSolution\n');
    fprintf(fid,'\t\tDebug|Win32 = Debug|Win32\n\t\tDebug|x64 = Debug|x64\n\t\tRelease|Win32 = Release|Win32\n\t\tRelease|x64 = Release|x64\n');
    fprintf(fid,'\tEndGlobalSection\n');
    fprintf(fid,'\tGlobalSection(ProjectConfigurationPlatforms) = postSolution\n');
    %Declare each project build type with reference to GUID
    for i = 1:len
        fprintf(fid,'\t\t{%s}.Debug|Win32.ActiveCfg = Debug|Win32\n',IDS{i});
        fprintf(fid,'\t\t{%s}.Debug|Win32.Build.0 = Debug|Win32\n',IDS{i});
        fprintf(fid,'\t\t{%s}.Debug|x64.ActiveCfg = Debug|x64\n',IDS{i});
        fprintf(fid,'\t\t{%s}.Debug|x64.Build.0 = Debug|x64\n',IDS{i});
        fprintf(fid,'\t\t{%s}.Release|Win32.ActiveCfg = Release|Win32\n',IDS{i});
%         if(~isfield(projStruct(i),'opts') || ~isfield(projStruct(i).opts,'empty') || ~projStruct(i).opts.empty)
            fprintf(fid,'\t\t{%s}.Release|Win32.Build.0 = Release|Win32\n',IDS{i});
%         end
        fprintf(fid,'\t\t{%s}.Release|x64.ActiveCfg = Release|x64\n',IDS{i});
%         if(~isfield(projStruct(i),'opts') || ~isfield(projStruct(i).opts,'empty') || ~projStruct(i).opts.empty)
            fprintf(fid,'\t\t{%s}.Release|x64.Build.0 = Release|x64\n',IDS{i});
%         end
    end
    fprintf(fid,'\tEndGlobalSection\n\tGlobalSection(SolutionProperties) = preSolution\n\t\tHideSolutionNode = FALSE\n\tEndGlobalSection\n');
    fprintf(fid,'EndGlobal\n');
catch ME    
    fclose(fid);
    rethrow(ME);
end
fclose(fid);
fprintf('Done\n\n');

function checkProjStruct(str,i)
if(~isfield(str,'sdir')), error('Project Structure %d should contain the field ''sdir''',i); end
if(~isfield(str,'name')), error('Project Structure %d should contain the field ''name''',i); end
    
%Function to get a GUID from .EXE
function str = getProjGUID()
cdir = cd;
cd(GETCD);
dos(['"' GETCD 'genGUID" 1']);
cd(cdir);
fh = fopen([GETCD 'guids.txt']);
str = fgetl(fh);
if(length(str) < 5)
    error('Error reading GUID');
end
fclose(fh);

%Get cwd of this file
function str = GETCD()
str = which('VS_WriteProj.m');
ind = strfind(str,'\');
str(ind(end)+1:end) = [];