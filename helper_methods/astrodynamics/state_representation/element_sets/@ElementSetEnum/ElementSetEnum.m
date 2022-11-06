classdef ElementSetEnum < matlab.mixin.SetGet
    %ElementSetEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        CartesianElements('Cartesian Elements', ...
                         {'Rx','Ry','Rz','Vx','Vy','Vz'}, ...
                         {'km','km','km','km/s','km/s','km/s'});
        KeplerianElements('Keplerian Orbit Elements', ...
                         {'SMA','Eccentricity','Inclination','RAAN','Arg Peri','True Aomaly'}, ...
                         {'km','','deg','deg','deg','deg'});
        GeographicElements('Geographical Elements', ...
                          {'Latitude','Longitude','Altitude','Velocity Az','Velocity El','Velocity Mag'}, ...
                          {'degN','degE','km','deg','deg','km/s'});
        UniversalElements('Universal Orbit Elements', ...
                         {'C3','Rp','Inclination','RAAN','Arg Peri','Time Past Peri.'}, ...
                         {'km^2/s^2','km','deg','deg','deg','sec'});
    end
    
    properties
        name(1,:) char
        elemNames(6,1) cell
        unitNames(6,1) cell
    end
    
    methods
        function obj = ElementSetEnum(name, elemNames, unitNames)
            obj.name = name;
            obj.elemNames = elemNames;
            obj.unitNames = unitNames;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ElementSetEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ElementSetEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ElementSetEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end