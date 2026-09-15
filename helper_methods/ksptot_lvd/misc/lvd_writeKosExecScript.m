function [ksFilePath, msg] = lvd_writeKosExecScript(csvFilePath, kosScriptsDir)
%LVD_WRITEKOSEXECSCRIPT Writes a ready-to-run kOS control script next to an LVD control CSV.
%
%   [ksFilePath, msg] = lvd_writeKosExecScript(csvFilePath) copies the
%   exec_lvd_control.ks template into the folder that holds csvFilePath,
%   with its "set fPath to ..." line pointed at the CSV file name, and
%   copies the KSLib libraries the script depends on (lib_navball.ks,
%   lib_num_to_formatted_str.ks) alongside it.  This removes the manual
%   "edit fPath by hand" step from the kOS export workflow.
%
%   [...] = lvd_writeKosExecScript(csvFilePath, kosScriptsDir) reads the
%   template and libraries from kosScriptsDir instead of searching the
%   default locations (the repository's kos_scripts folder relative to this
%   file, the deployed CTF root, and the current folder).
%
%   ksFilePath is the full path of the written script, or '' if the
%   template could not be located (msg then explains why; nothing is
%   written in that case).  msg is always a human-readable status string.

    arguments
        csvFilePath char
        kosScriptsDir char = ''
    end

    templateName = 'exec_lvd_control.ks';
    libNames = {'lib_navball.ks', 'lib_num_to_formatted_str.ks'};

    ksFilePath = '';

    if(isempty(kosScriptsDir))
        kosScriptsDir = lvd_writeKosExecScript_findScriptsDir(templateName);
    end

    templatePath = fullfile(kosScriptsDir, templateName);
    if(isempty(kosScriptsDir) || not(isfile(templatePath)))
        msg = sprintf(['The kOS execution script template "%s" could not be found, so only the CSV was written.  ', ...
                       'Copy the CSV into your KSP Ships/Script folder and set the fPath variable in %s to "%s" manually.'], ...
                       templateName, templateName, lvd_writeKosExecScript_nameWithExt(csvFilePath));
        return;
    end

    [outDir, ~, ~] = fileparts(csvFilePath);
    if(isempty(outDir))
        outDir = pwd;
    end

    csvName = lvd_writeKosExecScript_nameWithExt(csvFilePath);

    templateText = fileread(templatePath);
    [scriptText, numReplaced] = lvd_writeKosExecScript_setFPath(templateText, csvName);
    if(numReplaced ~= 1)
        msg = sprintf(['The kOS execution script template "%s" does not contain exactly one "set fPath to ..." line (found %u), so only the CSV was written.  ', ...
                       'Set fPath to "%s" manually.'], templatePath, numReplaced, csvName);
        return;
    end

    ksFilePath = fullfile(outDir, templateName);
    fid = fopen(ksFilePath, 'w');
    if(fid < 0)
        ksFilePath = '';
        msg = sprintf('Could not open "%s" for writing, so only the CSV was written.', fullfile(outDir, templateName));
        return;
    end
    fprintf(fid, '%s', scriptText);
    fclose(fid);

    copiedLibs = {};
    missingLibs = {};
    for(i=1:length(libNames)) %#ok<*NO4LP>
        libSrc = fullfile(kosScriptsDir, libNames{i});
        if(isfile(libSrc))
            copyfile(libSrc, fullfile(outDir, libNames{i}), 'f');
            copiedLibs{end+1} = libNames{i}; %#ok<AGROW>
        else
            missingLibs{end+1} = libNames{i}; %#ok<AGROW>
        end
    end

    msg = sprintf('Wrote %s (fPath = "%s")', ksFilePath, csvName);
    if(not(isempty(copiedLibs)))
        msg = sprintf('%s and copied %s.', msg, strjoin(copiedLibs, ', '));
    else
        msg = sprintf('%s.', msg);
    end
    if(not(isempty(missingLibs)))
        msg = sprintf('%s  KSLib file(s) not found and not copied: %s.', msg, strjoin(missingLibs, ', '));
    end
end

function [scriptText, numReplaced] = lvd_writeKosExecScript_setFPath(templateText, csvName)
%Replaces the single `set fPath to "<anything>".` assignment with the CSV name,
%preserving whatever trailing comment the template line carried.
    pattern = '^\s*set\s+fPath\s+to\s+"[^"\r\n]*"';
    [startInds, endInds] = regexp(templateText, pattern, 'start', 'end', 'lineanchors');
    numReplaced = numel(startInds);

    if(numReplaced == 1)
        %Splice the new name between the two quotes of the single match so no
        %regexprep token/escape rules can mangle an arbitrary file name.
        matchStr = templateText(startInds:endInds);
        openQuote = startInds + find(matchStr == '"', 1, 'first') - 1;
        closeQuote = startInds + find(matchStr == '"', 1, 'last') - 1;
        scriptText = [templateText(1:openQuote), csvName, templateText(closeQuote:end)];
    else
        scriptText = templateText;
    end
end

function nameWithExt = lvd_writeKosExecScript_nameWithExt(filePath)
    [~, name, ext] = fileparts(filePath);
    nameWithExt = [name, ext];
end

function scriptsDir = lvd_writeKosExecScript_findScriptsDir(templateName)
%Searches the locations the template can live in and returns the first hit.
    scriptsDir = '';

    thisDir = fileparts(mfilename('fullpath'));
    candidates = {fullfile(thisDir, '..', '..', '..', 'kos_scripts')}; %source tree: helper_methods/ksptot_lvd/misc -> repo root

    if(isdeployed())
        candidates{end+1} = fullfile(ctfroot(), 'kos_scripts');
    end

    candidates{end+1} = fullfile(pwd(), 'kos_scripts');
    candidates{end+1} = fullfile(pwd(), 'Ships', 'Script');
    candidates{end+1} = pwd();

    for(i=1:length(candidates))
        if(isfile(fullfile(candidates{i}, templateName)))
            scriptsDir = candidates{i};
            return;
        end
    end
end
