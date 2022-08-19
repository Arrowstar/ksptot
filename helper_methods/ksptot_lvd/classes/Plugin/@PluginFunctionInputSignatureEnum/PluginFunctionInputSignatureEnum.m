classdef PluginFunctionInputSignatureEnum < matlab.mixin.SetGet
    %PluginFunctionInptuSignatureEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        BeforeProp('Before Propagation','function userData = executePlugin(lvdData, stateLog, [], execLoc, [],[],[], userData, [], [], pluginVarValues)')
        BeforeEvents('Before Events','function userData = executePlugin(lvdData, stateLog, event, execLoc, [],[],[], userData, [], [], pluginVarValues)');
        AfterEvents('After Events','function userData = executePlugin(lvdData, stateLog, event, execLoc, [],[],[], userData, [], [], pluginVarValues)');
        AfterProp('After Propagation','function userData = executePlugin(lvdData, stateLog, [], execLoc, [],[],[], userData, [], [], pluginVarValues)');
        AfterTimeStep('After Time Steps','function userData = executePlugin(lvdData, [], eventInitStateLogEntry, execLoc, t,y,flag, userData, [], [], pluginVarValues)')
        
        Constraint('Plugin Constraint/Objective Function','function value = executePlugin(lvdData, stateLog, event, execLoc, [],[],[], userData, stateLogEntry, frame, pluginVarValues)');
        GraphicalAnalysis('Graphical Analysis Value','function value = executePlugin(lvdData, stateLog, event, execLoc, [],[],[], userData, stateLogEntry, frame, pluginVarValues)');
    end
    
    properties
        name(1,:) char
        functionSig(1,:) char
    end
    
    methods
        function obj = PluginFunctionInputSignatureEnum(name, functionSig)
            obj.name = name;
            obj.functionSig = functionSig;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PluginFunctionInputSignatureEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PluginFunctionInputSignatureEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PluginFunctionInputSignatureEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end

