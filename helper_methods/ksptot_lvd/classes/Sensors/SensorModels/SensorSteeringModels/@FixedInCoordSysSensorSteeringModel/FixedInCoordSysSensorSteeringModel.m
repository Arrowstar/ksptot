classdef FixedInCoordSysSensorSteeringModel < AbstractSensorSteeringModel
    %FixedInCoordSysSensorSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rhtAsc(1,1) double
        dec(1,1) double
        roll(1,1) double
        coordSys AbstractGeometricCoordSystem
        
        lvdData LvdData
    end
    
    methods
        function obj = FixedInCoordSysSensorSteeringModel(rhtAsc, dec, roll, coordSys, lvdData)
            obj.rhtAsc = rhtAsc;
            obj.dec = dec;
            obj.roll = roll;
            obj.coordSys = coordSys;
            
            obj.lvdData = lvdData;
        end
        
        function [boreDir] = getBoresightVector(obj, time, vehElemSet, ~, inFrame)
            rotMat = obj.coordSys.getCoordSysAtTime(time, vehElemSet, inFrame);
            
            [x,y,z] = sph2cart(obj.rhtAsc, obj.dec, 1);
            v = [x;y;z];
            
            boreDir = rotMat * v;
        end
        
        function rollAngle = getBoresightRollAngle(obj)
            rollAngle = obj.roll;
        end
        
        function parentDcm = getSensorParentDcmToInertial(obj, time, vehElemSet, dcm, inFrame)
            parentDcm = obj.coordSys.getCoordSysAtTime(time, vehElemSet, inFrame);
        end
        
        %body to inertial
        function sensorDcm = getSensorDcmToInertial(obj, time, vehElemSet, dcm, inFrame)
%             sensorToParentDcm = eul2rotmARH([obj.rhtAsc,obj.dec,obj.roll],'zyx');
%             parentToInertialDcm = obj.getSensorParentDcmToInertial(time, vehElemSet, dcm, inFrame);
%             
%             sensorDcm = parentToInertialDcm * sensorToParentDcm;

            boreDir = obj.getBoresightVector(time, vehElemSet, dcm, inFrame);
            M1 = vrrotvec2mat(vrrotvec([1;0;0], boreDir));
            M2 = rotx(rad2deg(obj.getBoresightRollAngle()));
            
            sensorDcm = M2 * M1;
        end
        
        function tf = isVehDependent(obj)
            tf = obj.coordSys.isVehDependent();
        end
        
        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditFixedInCoordSysSensorSteeringModelGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function enum = getEnum(obj)
            enum = SensorSteeringModelEnum.FixedInCoordSys;
        end
    end
end