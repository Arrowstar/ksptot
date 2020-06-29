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
    
    properties(Constant)
        badWords(1,:) cell = {'rmdir', 'delete', 'copyfile', 'movefile', 'dos', ...
                              'unix', 'system', 'perl', 'winopen', '!', 'load', ...
                              'importdata', 'uiimport', 'matfile'}
    end
    
    methods
        function obj = LvdPlugin()
            obj.id = rand();
        end
        
        function executePlugin(obj, lvdData, stateLog, event, execLoc, t,y,flag)
            tfBadWords = contains(obj.pluginCode,LvdPlugin.badWords,'IgnoreCase',true);
            
            inds = [];
            if(tfBadWords)
                for(i=1:length(LvdPlugin.badWords))
                    if(contains(obj.pluginCode,LvdPlugin.badWords{i}))
                        inds(end+1) = i; %#ok<AGROW>
                    end
                end
                
                if(not(isempty(inds)))
                    quotedwords = cellfun(@(c) sprintf('"%s"', c), LvdPlugin.badWords(inds), 'UniformOutput',false);
                    wordList = grammaticalList(quotedwords);
                else
                    quotedwords = cellfun(@(c) sprintf('"%s"', c), LvdPlugin.badWords, 'UniformOutput',false);
                    wordList = grammaticalList(quotedwords);
                end
 
                errMsg = sprintf('String(s) %s is/are not allowed in LVD plugin code.', wordList);
                errStr = sprintf('An error was encountered executing plugin "%s" at location "%s".  Msg: %s', ...
                                 obj.pluginName, execLoc.name, errMsg);
                lvdData.validation.outputs(end+1) = LaunchVehicleDataValidationError(errStr);
            else
                try
                    eval(sprintf('%s',obj.pluginCode));
                catch ME
                    errStr = sprintf('An error was encountered executing plugin "%s" at location "%s".  Msg: %s', ...
                                     obj.pluginName, execLoc.name, ME.message);
                    lvdData.validation.outputs(end+1) = LaunchVehicleDataValidationError(errStr);
                end
            end
        end
    end
end