classdef LvdPlugin < matlab.mixin.SetGet
    %LvdPlugin Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %plugin execution location switches
        execBeforePropTF(1,1) logical = false;
        execBeforeEventsTF(1,1) logical = false;
        execAfterTimeStepsTF(1,1) logical = false;
        execAfterEventsTF(1,1) logical = false;
        execAfterPropTF(1,1) logical = false;
        
        %plugin info
        pluginName(1,:) char = 'Untitled LVD Plugin';
        pluginDesc(:,:) char = '';
        
        %plugin code
        pluginCode(1,1) string = "";
        
        %plugin id
        id(1,1) double
    end
    
    properties(Constant, Access=private)
        badWords(1,:) cell = {'rmdir', 'delete', 'copyfile', 'movefile', 'dos', ...
                              'unix', 'system', 'perl', 'winopen', '!', 'load', ...
                              'importdata', 'uiimport', 'matfile', 'input', 'inputdlg', ...
                              'inputname'}
    end
    
    methods
        function obj = LvdPlugin()
            obj.id = rand();
        end
        
        function userData = executePlugin(obj, lvdData, stateLog, event, execLoc, t,y,flag, userData, stateLogEntry, frame)
            %Detection and itemization must use the SAME predicate, otherwise a
            %code string can trip the detector while producing an empty index
            %list.  Word boundaries keep ordinary identifiers such as
            %"payloadMass", "inputCount" and "deleteFlag" from being rejected
            %just because they contain a forbidden word as a substring.
            inds = [];
            for(i=1:length(LvdPlugin.badWords))
                if(LvdPlugin.codeUsesBadWord(obj.pluginCode, LvdPlugin.badWords{i}))
                    inds(end+1) = i; %#ok<AGROW>
                end
            end

            if(not(isempty(inds)))
                quotedwords = cellfun(@(c) sprintf('"%s"', c), LvdPlugin.badWords(inds), 'UniformOutput',false);
                wordList = grammaticalList(quotedwords);

                errMsg = sprintf('String(s) %s is/are not allowed in LVD plugin code.', wordList);
                errStr = sprintf('An error was encountered executing plugin "%s" at location "%s".  Msg: %s', ...
                                 obj.pluginName, execLoc.name, errMsg);
                lvdData.validation.outputs(end+1) = LaunchVehicleDataValidationError(errStr);
            else
                pluginVarValues = lvdData.pluginVars.getPluginVarValues(); %gets used by the plugin code itself

                try
                    eval(sprintf('%s',obj.pluginCode));
                    
                    if(execLoc == LvdPluginExecLocEnum.Constraint || execLoc == LvdPluginExecLocEnum.GraphAnalysis)
                        userData = value;
                    end
                catch ME
                    errStr = sprintf('An error was encountered executing plugin "%s" at location "%s".  Msg: %s', ...
                                     obj.pluginName, execLoc.name, ME.message);
                    lvdData.validation.outputs(end+1) = LaunchVehicleDataValidationError(errStr);
                end
            end
        end
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesPlugin(obj);
        end
    end
    
    methods(Static)
        function badWords = getDisallowedStrings()
            badWords = LvdPlugin.badWords;
        end

        function tf = codeUsesBadWord(pluginCode, badWord)
            %Matches badWord as a whole token so that identifiers which merely
            %contain it ("payloadMass" vs "load") are not flagged.  Purely
            %symbolic entries such as "!" have no word boundary, so those are
            %matched as escaped literals instead.
            escaped = regexptranslate('escape', badWord);

            if(all(isstrprop(badWord, 'alphanum') | badWord == '_'))
                pattern = ['\<', escaped, '\>'];
            else
                pattern = escaped;
            end

            tf = not(isempty(regexpi(pluginCode, pattern, 'once')));
        end
    end
end