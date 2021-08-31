classdef PluginConstraint < AbstractConstraint
    %PluginConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        plugin LvdPlugin
        event LaunchVehicleEvent
        eventNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
        stateCompNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
    end
    
    methods
        function obj = PluginConstraint(plugin, event, lb, ub)
            obj.plugin = plugin;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   
            
             obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum, valueStateComp] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            
            switch obj.eventNode
                case ConstraintStateComparisonNodeEnum.FinalState
                    stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
                    
                case ConstraintStateComparisonNodeEnum.InitialState
                    stateLogEntry = stateLog.getFirstStateLogForEvent(obj.event);
                
                otherwise
                    error('Unknown event node.');
            end
            
            if(not(isempty(obj.frame)))
                frame = obj.frame;
            else
                frame = stateLogEntry.centralBody.getBodyCenteredInertialFrame();
            end
            
            lvdData = stateLogEntry.lvdData;
            pluginSet = lvdData.plugins;
            value = obj.plugin.executePlugin(stateLogEntry.lvdData, stateLog, obj.event, LvdPluginExecLocEnum.Constraint, [],[],[], pluginSet.userData, stateLogEntry, frame);
            
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent);

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent);

                    otherwise
                        error('Unknown event node.');
                end

                valueStateComp = obj.plugin.executePlugin(lvdData, stateLog, obj.event, LvdPluginExecLocEnum.Constraint, [],[],[], pluginSet.userData, stateLogEntryStateComp, frame);
            else
                valueStateComp = NaN;
            end
            
            [c, ceq] = obj.computeCAndCeqValues(value, valueStateComp);  
            
            lwrBnd = obj.lb;
            uprBnd = obj.ub;
            
            eventNum = obj.event.getEventNum();
        end
        
        function sF = getScaleFactor(obj)
            sF = obj.normFact;
        end
        
        function setScaleFactor(obj, sF)
            obj.normFact = sF;
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesEvent(obj, event)
            tf = obj.event == event;
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                tf = tf || obj.stateCompEvent == event;
            end
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesGroundObj(obj, grdObj)
            tf = false;
        end

        function tf = usesPlugin(obj, plugin)
            tf = obj.plugin == plugin;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Plugin Value';
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = ''; %TODO: Need to come up with a way to populate this I think?
            lbLim = -Inf;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            if(lvdData.plugins.getNumPlugins() >= 1)
%                 addConstraintTf = lvd_EditPluginConstraintGUI(obj, lvdData);

                output = AppDesignerGUIOutput({false});
                lvd_EditPluginConstraintGUI_App(obj, lvdData, output);
                addConstraintTf = output.output{1};
            else
                errordlg('There are currently no plugins in this scenario.  Create at least one new plugin first.');
    
                addConstraintTf = false;
            end
        end
        
        function plugin = selectConstraintObj(obj, lvdData)
            [listBoxStr, plugins] = lvdData.plugins.getListboxStr();

            plugin = [];
            if(isempty(plugins))                
                warndlg('Cannot create plugin value object: no plugins have been created.  Create a plugin first.','Plugin Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select a plugin:'},...
                                'SelectionMode','single',...
                                'Name','Plugins',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    plugin = [];
                else
                    plugin = plugins(Selection);
                end
            end
        end
        
        function useObjFcn = setupForUseAsObjectiveFcn(obj,lvdData)
            pluginSel = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(pluginSel)))
                obj.plugin = pluginSel;
                useObjFcn = true;
            else
                useObjFcn = false;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = PluginConstraint(LvdPlugin.empty(1,0), LaunchVehicleEvent.empty(1,0), 0, 0);
        end
    end
end