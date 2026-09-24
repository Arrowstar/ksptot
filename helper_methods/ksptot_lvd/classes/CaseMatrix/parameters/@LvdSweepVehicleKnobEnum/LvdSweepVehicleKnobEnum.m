classdef LvdSweepVehicleKnobEnum < matlab.mixin.SetGet
    %LvdSweepVehicleKnobEnum The vehicle and environment quantities a sweep
    %can turn that are not optimization variables.
    %
    %   These are the things a trade study almost always wants and that LVD
    %   otherwise makes the user wire through a plugin variable first: how
    %   heavy the stage is, how much propellant it carries, how good the
    %   engine turned out to be, and how draggy the vehicle is.
    %
    %   The two engine knobs are MULTIPLIERS on the thrust and Isp pressure
    %   curves rather than absolute values, because thrust and Isp are curves
    %   over ambient pressure, not numbers -- and because scaling a curve is
    %   what "this engine came in 2% under spec" actually means.  Nothing is
    %   added to LaunchVehicleEngine for this; the sweep scales the curve
    %   elements in the case's own copy of the mission.

    enumeration
        StageDryMass('Stage Dry Mass', 'mT', 'stage')
        TankInitialMass('Tank Initial Mass', 'mT', 'tank')
        TankCapacity('Tank Capacity', 'mT', 'tank')
        EngineThrustMultiplier('Engine Thrust Multiplier', '', 'engine')
        EngineIspMultiplier('Engine Isp Multiplier', '', 'engine')
        InitStateDragMultiplier('Initial State Drag Multiplier', '', 'initState')
        EventDragMultiplier('Event Drag Multiplier', '', 'action')
    end

    properties
        name char = '';
        unit char = '';

        %What kind of object this knob hangs off, which is what tells
        %resolve() where to go looking for the target id.
        targetKind char = '';
    end

    methods
        function obj = LvdSweepVehicleKnobEnum(name, unit, targetKind)
            obj.name = name;
            obj.unit = unit;
            obj.targetKind = targetKind;
        end

        function tf = isMultiplier(obj)
            %isMultiplier True for the knobs that scale a baseline rather
            %than setting an absolute value.  Those are the ones that need
            %captureBaseline and that must be applied idempotently.
            tf = ismember(obj, [LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ...
                                LvdSweepVehicleKnobEnum.EngineIspMultiplier]);
        end
    end

    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            enums = enumeration('LvdSweepVehicleKnobEnum');
            listBoxStr = {enums.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdSweepVehicleKnobEnum');
            ind = find(ismember({m.name}, name), 1, 'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdSweepVehicleKnobEnum');
            ind = find(ismember({m.name}, nameStr), 1, 'first');
            enum = m(ind);
        end
    end
end
