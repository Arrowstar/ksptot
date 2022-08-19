classdef OrbitStateEnum < matlab.mixin.SetGet
    %OrbitStateEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        KeplerianOrbit('Keplerian Orbit','KeplerianOrbitStateModel', ...
                       {'SMA','Eccentricity','Inclination','RAAN','Arg Peri','True Aomaly'}, ...
                       {'km','','deg','deg','deg','deg'}, ...
                       'KeplerianOrbitVariable', ...
                       'Central Body', ...
                       'The body around which this orbit is defined.')
        BodyFixed('Body Fixed Orbit','BodyFixedOrbitStateModel', ...
                  {'Latitude','Longitude','Altitude','Velocity Az','Velocity El','Velocity Mag'}, ...
                  {'degN','degE','km','deg','deg','km/s'}, ...
                  'BodyFixedOrbitVariable', ...
                  'Central Body', ...
                  'The body upon which this body-fixed state is defined.  If launching from the surface, the body being launched from.')
        CR3BP('Primary-centered Circular Restricted 3 Body Problem Orbit','CR3BPOrbitStateModel', ...
                  {'Position (X)','Position (Y)','Position (Z)','Velocity (X)','Velocity (Y)','Velocity (Z)'}, ...
                  {'km','km','km','km/s','km/s','km/s'}, ...
                  'BodyFixedOrbitVariable', ...
                  'Secon. Body', ...
                  'The secondary body in the 3 body rotating frame.  The actual orbit will be defined w.r.t. the parent of this body.  E.G. if you want a Kerbin-Mun rotating frame, select "Mun" here.')
    end
    
    properties
        name char = ''
        class char = ''
        elemNames(6,1) cell
        unitNames(6,1) cell
        varClass char = '';
        cbLabel char = 'Central Body';
        cbTooltip char = '';
    end
    
    methods
        function obj = OrbitStateEnum(name,class,elemNames,unitNames,varClass,cbLabel,cbTooltip)
            obj.name = name;
            obj.class = class;
            obj.elemNames = elemNames;
            obj.unitNames = unitNames;
            obj.varClass = varClass;
            obj.cbLabel = cbLabel;
            obj.cbTooltip = cbTooltip;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('OrbitStateEnum');
            listBoxStr = {m.name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('OrbitStateEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [ind, enum] = getIndForClass(class)
            m = enumeration('OrbitStateEnum');
            ind = find(ismember({m.class},class),1,'first');
            enum = m(ind);
        end
    end
end

