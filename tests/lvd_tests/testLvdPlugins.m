classdef testLvdPlugins < matlab.unittest.TestCase
    % testLvdPlugins Unit tests for LVD Plugins, Constraints, and Objectives
    
    properties
        LvdData
        BaseEvent
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            % Load an example to get valid lvdData
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_ElecPowerExample.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
            
            % Get a base event to use
            testCase.BaseEvent = testCase.LvdData.script.getEventForInd(1);
        end
    end
    
    methods(Test)
        function testPluginDirectExecution(testCase)
            % Test that plugin code executes and returns 'value'
            lvdData = testCase.LvdData;
            plugin = LvdPlugin();
            plugin.pluginName = 'Test Plugin';
            plugin.pluginCode = "value = 42;";
            
            execLoc = LvdPluginExecLocEnum.Constraint;
            stateLogEntry = lvdData.initialState;
            frame = stateLogEntry.centralBody.getBodyCenteredInertialFrame();
            
            userData = [];
            [value] = plugin.executePlugin(lvdData, [], [], execLoc, [], [], [], userData, stateLogEntry, frame);
            
            testCase.verifyEqual(value, 42, 'Plugin should return the value assigned to "value" variable');
        end
        
        function testPluginUserDataPersistence(testCase)
            % Test that userData persists and can be modified
            lvdData = testCase.LvdData;
            plugin = LvdPlugin();
            
            % Plugin code that modifies userData
            plugin.pluginCode = "userData.x = 10; value = 0;";
            
            stateLogEntry = lvdData.initialState;
            frame = stateLogEntry.centralBody.getBodyCenteredInertialFrame();
            execLoc = LvdPluginExecLocEnum.Constraint;
            
            userData = struct('x', 0);
            [~] = plugin.executePlugin(lvdData, [], [], execLoc, [], [], [], userData, stateLogEntry, frame);
            
            % NOTE: LvdPlugin.executePlugin DOES NOT return userData. 
            % It returns 'value' if execLoc is Constraint/GraphAnalysis.
            % However, it modifies the local 'userData' variable in the eval context.
            % Looking at LvdPlugin.m, line 36:
            % function userData = executePlugin(obj, lvdData, stateLog, event, execLoc, t,y,flag, userData, stateLogEntry, frame)
            
            % Wait, the METHOD SIGNATURE says it returns userData!
            % Line 36: function userData = executePlugin(...)
            % Line 66: userData = value; (only if Constraint/GraphAnalysis)
            
            % If it's NOT a constraint, it returns the passed-in (and potentially modified) userData.
            plugin.pluginCode = "userData.x = 100;";
            execLocOther = LvdPluginExecLocEnum.BeforeProp;
            newData = plugin.executePlugin(lvdData, [], [], execLocOther, [], [], [], userData, stateLogEntry, frame);
            
            testCase.verifyEqual(newData.x, 100, 'userData should be updated and returned');
        end
        
        function testPluginConstraint(testCase)
            % Test PluginConstraint integration
            lvdData = testCase.LvdData;
            plugin = LvdPlugin();
            plugin.pluginCode = "value = stateLogEntry.time + 10;";
            
            event = testCase.BaseEvent;
            constraint = PluginConstraint(plugin, event, 0, 100);
            
            % Mock state log with one entry
            stateLog = LaunchVehicleStateLog(lvdData);
            entry = lvdData.initialState.deepCopy();
            entry.time = 50;
            entry.event = event;
            stateLog.appendStateLogEntries(entry);
            
            [~, ~, value, ~, ~, ~, ~] = constraint.evalConstraint(stateLog, lvdData.celBodyData);
            
            testCase.verifyEqual(value, 60, 'Constraint should extract value from plugin using state log entry');
        end
        
        function testPluginObjectiveFunction(testCase)
            % Test GenericObjectiveFcn wrapping a PluginConstraint
            lvdData = testCase.LvdData;
            plugin = LvdPlugin();
            plugin.pluginCode = "value = 500;";
            
            event = testCase.BaseEvent;
            constraint = PluginConstraint(plugin, event, 0, 1000);
            
            % Wrap in objective function
            % GenericObjectiveFcn(event, frame, fcn, scaleFactor, lvdOptim, lvdData)
            frame = testCase.LvdData.initialState.centralBody.getBodyCenteredInertialFrame();
            objFcn = GenericObjectiveFcn(event, frame, constraint, 1, lvdData.optimizer, lvdData);
            
            % Mock state log
            stateLog = LaunchVehicleStateLog(lvdData);
            entry = lvdData.initialState.deepCopy();
            entry.event = event;
            stateLog.appendStateLogEntries(entry);
            
            [f, fUnscaled] = objFcn.evalObjFcn(stateLog);
            
            testCase.verifyEqual(fUnscaled, 500, 'Objective function should return the plugin value');
            testCase.verifyEqual(f, 500, 'Scaled objective value should match unscaled when scale factor is 1');
        end
        
        function testPluginMissionIntegration(testCase)
            % Test that plugins are executed during script execution
            lvdData = testCase.LvdData;
            lvdData.plugins.plugins = LvdPlugin.empty(1,0); % Clear existing
            
            plugin = LvdPlugin();
            plugin.pluginName = 'Mission Plugin';
            plugin.pluginCode = "userData.called = true;";
            plugin.execBeforeEventsTF = true;
            lvdData.plugins.addPlugin(plugin);
            
            % Setup a simple one-event script if not already present
            if lvdData.script.getTotalNumOfEvents() == 0
                evt = LaunchVehicleEvent.getDefaultEvent(lvdData);
                lvdData.script.addEvent(evt);
            end
            
            % Execute script
            % executeScript(isSparseOutput, evtToStartScriptExecAt, evalConstraints, allowInterrupt, dispEvtPropTimes, notifyScriptEvents)
            lvdData.script.executeScript(true, LaunchVehicleEvent.empty(1,0), false, false, false, false);
            
            testCase.verifyTrue(lvdData.plugins.userData.called, 'Plugin should be executed during script propagation');
        end
    end
end
