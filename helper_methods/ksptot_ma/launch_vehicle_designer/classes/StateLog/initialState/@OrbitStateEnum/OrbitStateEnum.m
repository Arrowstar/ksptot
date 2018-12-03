classdef OrbitStateEnum < matlab.mixin.SetGet
    %OrbitStateEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        KeplerianOrbit('Keplerian Orbit','KeplerianOrbitStateModel', ...
                       {'SMA','Eccentricity','Inclination','RAAN','Arg Peri','True Aomaly'}, ...
                       {'km','','deg','deg','deg','deg'}, ...
                       'KeplerianOrbitVariable')
        BodyFixed('Body Fixed Orbit','BodyFixedOrbitStateModel', ...
                  {'Latitude','Longitude','Altitude','Body Fixed Vx','Body Fixed Vy','Body Fixed Vz'}, ...
                  {'degN','degE','km','km/s','km/s','km/s'}, ...
                  'BodyFixedOrbitVariable')
    end
    
    properties
        name(1,:) char = ''
        class(1,:) char = ''
        elemNames(6,1) cell
        unitNames(6,1) cell
        varClass(1,:) char = '';
    end
    
    methods
        function obj = OrbitStateEnum(name,class,elemNames,unitNames,varClass)
            obj.name = name;
            obj.class = class;
            obj.elemNames = elemNames;
            obj.unitNames = unitNames;
            obj.varClass = varClass;
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

