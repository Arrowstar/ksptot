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
        badWords(1,:) cell = {'rmdir', 'delete', 'copyfile', 'movefile'}
    end
    
    methods
        function obj = LvdPlugin()
            obj.id = rand();
        end
        
        function executePlugin(obj, lvdData, stateLog, event, execLoc, t,y,flag)
            tfBadWords = contains(obj.pluginCode,LvdPlugin.badWords,'IgnoreCase',true);
            
            if(tfBadWords)
                errStr = sprintf('An error was encountered executing plugin "%s" at location "%s".  Msg: %s', ...
                                 obj.pluginName, execLoc.name, 'Strings "rmdir", "delete", "copyfile", and "movefile" are not allowed in LVD plugin code.');
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