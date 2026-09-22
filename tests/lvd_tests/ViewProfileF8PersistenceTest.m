classdef ViewProfileF8PersistenceTest < KsptotTestCase
    %ViewProfileF8PersistenceTest The F8 settings hung off
    %LaunchVehicleViewProfile (camera mode, chase camera, camera script,
    %vehicle mesh, playback): per-profile independence, loadobj back-fill,
    %save/load round trips, and old missions loading with defaults.

    methods(Test)

        function freshProfilesHaveIndependentSettingsObjects(testCase)
            p1 = LaunchVehicleViewProfile();
            p2 = LaunchVehicleViewProfile();

            testCase.verifyClass(p1.vehicleMesh, 'LvdVehicleMeshSettings');
            testCase.verifyClass(p1.cameraScript, 'LvdCameraScript');
            testCase.verifyClass(p1.chaseCamera, 'LvdChaseCameraSettings');
            testCase.verifyClass(p1.fixedAnchorCamera, 'LvdFixedAnchorCameraSettings');
            testCase.verifyClass(p1.playbackSettings, 'LvdViewPlaybackSettings');
            testCase.verifyEqual(p1.cameraMode, LvdCameraModeEnum.Manual);

            %a shared handle default would make these the SAME object
            testCase.verifyNotSameHandle(p1.vehicleMesh, p2.vehicleMesh);
            testCase.verifyNotSameHandle(p1.cameraScript, p2.cameraScript);
            testCase.verifyNotSameHandle(p1.chaseCamera, p2.chaseCamera);
            testCase.verifyNotSameHandle(p1.fixedAnchorCamera, p2.fixedAnchorCamera);
            testCase.verifyNotSameHandle(p1.playbackSettings, p2.playbackSettings);

            p1.chaseCamera.azDeg = 123;
            testCase.verifyEqual(p2.chaseCamera.azDeg, 45, 'Editing one profile leaves the other alone');

            p1.fixedAnchorCamera.fixedPosition = [1 2 3];
            testCase.verifyEqual(p2.fixedAnchorCamera.fixedPosition, [0 0 0], 'Editing one profile''s anchor leaves the other alone');

            %and the view settings' default profile is independent too
            vs = LaunchVehicleViewSettings(LvdData.getDefaultLvdData(testCase.celBodyData));
            testCase.verifyNotSameHandle(vs.selViewProfile.cameraScript, p1.cameraScript);
        end

        function ensureF8DefaultsBackfillsEmptyObjects(testCase)
            p = LaunchVehicleViewProfile();
            p.vehicleMesh = LvdVehicleMeshSettings.empty(1,0);
            p.cameraScript = LvdCameraScript.empty(1,0);
            p.chaseCamera = LvdChaseCameraSettings.empty(1,0);
            p.fixedAnchorCamera = LvdFixedAnchorCameraSettings.empty(1,0);
            p.playbackSettings = LvdViewPlaybackSettings.empty(1,0);

            p2 = LaunchVehicleViewProfile.loadobj(p);
            testCase.verifySameHandle(p2, p);
            testCase.verifyNotEmpty(p.vehicleMesh);
            testCase.verifyNotEmpty(p.cameraScript);
            testCase.verifyNotEmpty(p.chaseCamera);
            testCase.verifyNotEmpty(p.fixedAnchorCamera);
            testCase.verifyClass(p.fixedAnchorCamera, 'LvdFixedAnchorCameraSettings');
            testCase.verifyNotEmpty(p.playbackSettings);

            existing = p.cameraScript;
            p.ensureF8Defaults();
            testCase.verifySameHandle(p.cameraScript, existing, 'ensureF8Defaults never replaces a live object');
        end

        function loadobjStructBranchAddsTheF8Fields(testCase)
            s = struct('name', 'old profile', 'skyBoxImgFileName', "DarkStarsSkyBox.png");
            out = LaunchVehicleViewProfile.loadobj(s);
            testCase.verifyTrue(isstruct(out));
            testCase.verifyEqual(out.cameraMode, LvdCameraModeEnum.Manual);
            testCase.verifyClass(out.chaseCamera, 'LvdChaseCameraSettings');
            testCase.verifyClass(out.fixedAnchorCamera, 'LvdFixedAnchorCameraSettings');
            testCase.verifyClass(out.cameraScript, 'LvdCameraScript');
            testCase.verifyClass(out.vehicleMesh, 'LvdVehicleMeshSettings');
            testCase.verifyClass(out.playbackSettings, 'LvdViewPlaybackSettings');
        end

        function saveLoadRoundTripPreservesMeshScriptAndSettings(testCase)
            [lvdData, evt2] = testCase.propagatedMission();
            profile = lvdData.viewSettings.selViewProfile;

            meshPath = [tempname(), '.stl'];
            cleanupMesh = onCleanup(@() deleteIfExists(meshPath)); %#ok<NASGU>
            ksptotWriteTestMesh('stl-binary', meshPath);
            profile.vehicleMesh.loadFromFile(meshPath);
            profile.vehicleMesh.scale = 0.002;
            profile.vehicleMesh.rotOffsetEulerDeg = [10 20 30];
            profile.vehicleMesh.faceColor = [0.1 0.2 0.3];

            kfA = LvdCameraKeyframe(); kfA.name = 'wide'; kfA.absTime = 0; kfA.holdDuration = 4;
            kfB = LvdCameraKeyframe(); kfB.name = 'chase';
            kfB.anchorType = LvdCameraKeyframeAnchorEnum.EventStart; kfB.event = evt2; kfB.timeOffset = 2;
            kfB.refType = LvdCameraKeyframeRefEnum.VehicleRelative; kfB.azDeg = 12; kfB.elDeg = 34; kfB.rangeKm = 56;
            kfC = LvdCameraKeyframe(); kfC.name = 'end'; kfC.absTime = 500; kfC.easing = LvdCameraEasingEnum.Linear;
            profile.cameraScript.addKeyframe(kfA);
            profile.cameraScript.addKeyframe(kfB);
            profile.cameraScript.addKeyframe(kfC);

            profile.cameraMode = LvdCameraModeEnum.Scripted;
            profile.chaseCamera.rangeKm = 77;
            profile.playbackSettings.fps = 12;
            profile.playbackSettings.videoFormat = "GIF";
            profile.playbackSettings.loop = true;

            matPath = [tempname(), '.mat'];
            cleanupMat = onCleanup(@() deleteIfExists(matPath)); %#ok<NASGU>
            save(matPath, 'lvdData');
            loaded = load(matPath, 'lvdData');
            l = loaded.lvdData;
            lp = l.viewSettings.selViewProfile;

            testCase.verifyEqual(lp.cameraMode, LvdCameraModeEnum.Scripted);
            testCase.verifyEqual(lp.vehicleMesh.vertices, profile.vehicleMesh.vertices);
            testCase.verifyEqual(lp.vehicleMesh.faces, profile.vehicleMesh.faces);
            testCase.verifyEqual(lp.vehicleMesh.sourcePath, string(meshPath));
            testCase.verifyEqual(lp.vehicleMesh.scale, 0.002);
            testCase.verifyEqual(lp.vehicleMesh.rotOffsetEulerDeg, [10 20 30]);
            testCase.verifyEqual(lp.vehicleMesh.faceColor, [0.1 0.2 0.3]);
            testCase.verifyTrue(lp.vehicleMesh.enabled);

            testCase.verifyEqual(lp.cameraScript.getNumKeyframes(), 3);
            testCase.verifyEqual({lp.cameraScript.keyframes.name}, {'wide','chase','end'});
            testCase.verifyEqual(lp.cameraScript.keyframes(1).holdDuration, 4);
            testCase.verifyEqual(lp.cameraScript.keyframes(2).anchorType, LvdCameraKeyframeAnchorEnum.EventStart);
            testCase.verifyEqual(lp.cameraScript.keyframes(2).refType, LvdCameraKeyframeRefEnum.VehicleRelative);
            testCase.verifyEqual(lp.cameraScript.keyframes(2).rangeKm, 56);
            testCase.verifySameHandle(lp.cameraScript.keyframes(2).event, l.script.getEventForInd(2), ...
                'The keyframe still points at the loaded mission''s own event 2');
            testCase.verifyEqual(lp.cameraScript.keyframes(3).easing, LvdCameraEasingEnum.Linear);

            testCase.verifyEqual(lp.chaseCamera.rangeKm, 77);
            testCase.verifyEqual(lp.playbackSettings.fps, 12);
            testCase.verifyEqual(lp.playbackSettings.videoFormat, "GIF");
            testCase.verifyTrue(lp.playbackSettings.loop);

            %the transient runtime objects are not saved
            testCase.verifyEmpty(lp.markerVehicleMeshData);
            testCase.verifyEmpty(lp.cameraDriver);
        end

        function fixedAnchorSurvivesSaveLoadForEachAnchorType(testCase)
            %A FixedAnchor profile round-trips through .mat for each anchor
            %type; the object anchors keep pointing at the RELOADED mission's
            %own ground object / geometric point (not the pre-save handles).
            [lvdData, ~] = testCase.propagatedMission();
            profile = lvdData.viewSettings.selViewProfile;
            frame = testCase.kerbin.getBodyFixedFrame();

            grdObj = LaunchVehicleGroundObject('Pad', "", 0, ...
                LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, deg2rad(5), deg2rad(30), 2, 0,0,0, frame), 100));
            lvdData.groundObjs.addGroundObj(grdObj);
            pt = FixedPointInFrame([700 -200 350], testCase.kerbinFrame, 'Pad Point', lvdData);
            lvdData.geometry.points.addPoint(pt);

            profile.cameraMode = LvdCameraModeEnum.FixedAnchor;
            fa = profile.fixedAnchorCamera;
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            fa.fixedPosition = [111 -222 333];
            fa.anchorFrame = testCase.kerbinFrame;
            fa.groundObject = grdObj;
            fa.geometricPoint = pt;
            fa.viewAngleDeg = 7.5;

            matPath = [tempname(), '.mat'];
            cleanupMat = onCleanup(@() deleteIfExists(matPath)); %#ok<NASGU>
            save(matPath, 'lvdData');
            l = load(matPath, 'lvdData').lvdData;
            lfa = l.viewSettings.selViewProfile.fixedAnchorCamera;

            testCase.verifyEqual(l.viewSettings.selViewProfile.cameraMode, LvdCameraModeEnum.FixedAnchor);
            testCase.verifyEqual(lfa.anchorType, LvdCameraAnchorTypeEnum.GroundObject);
            testCase.verifyEqual(lfa.fixedPosition, [111 -222 333]);
            testCase.verifyEqual(lfa.viewAngleDeg, 7.5);
            testCase.verifyTrue(ismember(lfa.groundObject, l.groundObjs.groundObjs), ...
                'The anchor still points at one of the reloaded mission''s own ground objects');
            testCase.verifyEqual(lfa.groundObject.name, 'Pad', 'and specifically at the one it was set to');
            [~, loadedPts] = l.geometry.points.getListboxStr();
            testCase.verifyTrue(ismember(lfa.geometricPoint, loadedPts), ...
                'The anchor still points at one of the reloaded mission''s own geometric points');

            %and the anchor resolves in the reloaded mission for each type
            viewFrame = l.viewSettings.selViewProfile.frame;
            testCase.verifyNotEmpty(lfa.getAnchorPosAtTime(0, viewFrame));
            lfa.anchorType = LvdCameraAnchorTypeEnum.GeometricPoint;
            testCase.verifyNotEmpty(lfa.getAnchorPosAtTime(0, viewFrame));
            lfa.anchorType = LvdCameraAnchorTypeEnum.FixedXYZ;
            testCase.verifyVectorEqual(lfa.getAnchorPosAtTime(0, viewFrame)', ...
                CartesianElementSet(0, [111;-222;333], [0;0;0], testCase.kerbinFrame).convertToFrame(viewFrame).rVect', 1e-6);
        end

        function preF8MissionLoadsWithDefaults(testCase)
            hits = dir(fullfile(ksptotTestRoot(), 'examples', 'LaunchVehicleDesigner', '**', 'lvdExample_SimpleHohmannTransfer.mat'));
            testCase.assumeNotEmpty(hits, 'Example mission not present in this checkout.');

            loaded = testCase.verifyWarningFree(@() load(fullfile(hits(1).folder, hits(1).name), 'lvdData'));
            lvdData = loaded.lvdData;
            profiles = lvdData.viewSettings.getProfilesArray();
            testCase.assertNotEmpty(profiles);
            for i = 1:numel(profiles)
                p = profiles(i);
                testCase.verifyEqual(p.cameraMode, LvdCameraModeEnum.Manual);
                testCase.verifyClass(p.vehicleMesh, 'LvdVehicleMeshSettings');
                testCase.verifyFalse(p.vehicleMesh.hasMesh());
                testCase.verifyFalse(p.vehicleMesh.enabled);
                testCase.verifyEqual(p.cameraScript.getNumKeyframes(), 0);
                testCase.verifyClass(p.chaseCamera, 'LvdChaseCameraSettings');
                testCase.verifyClass(p.playbackSettings, 'LvdViewPlaybackSettings');
            end
        end

        function cameraDriverIsLazyAndPerProfile(testCase)
            p1 = LaunchVehicleViewProfile();
            p2 = LaunchVehicleViewProfile();
            d1 = p1.getCameraDriver();
            testCase.verifyClass(d1, 'LvdSceneCameraDriver');
            testCase.verifySameHandle(p1.getCameraDriver(), d1, 'Same driver on repeated calls');
            testCase.verifyNotSameHandle(p2.getCameraDriver(), d1);
            testCase.verifyEqual(d1.activeMode, LvdCameraModeEnum.Manual);
        end

        function skyboxTexturesResolveToSixFaceFolders(testCase)
            %Every non-custom skybox texture must resolve to a folder with
            %all six cubemap faces (cube-only rendering has no fallback).
            m = enumeration('SkyboxTextureEnum');
            testCase.verifyNotEmpty(m);
            faces = ["px","nx","py","ny","pz","nz"];
            for i = 1:numel(m)
                if m(i).isCustom()
                    testCase.verifyFalse(m(i).hasCubemap(), 'Custom has no cubemap folder');
                    continue;
                end
                testCase.verifyTrue(m(i).hasCubemap(), ['hasCubemap: ' char(m(i).displayName)]);
                d = m(i).getCubemapDir();
                testCase.verifyTrue(strlength(d) > 0, ['cubemap dir: ' char(m(i).displayName)]);
                for f = faces
                    testCase.verifyTrue(isfile(m(i).getFacePath(f)), ...
                        ['face ' char(f) ' of ' char(m(i).displayName)]);
                end
                %legacy filename and folder name both map back to the enum
                [back, ~] = SkyboxTextureEnum.getEnumForFileName(m(i).fileName);
                testCase.verifyEqual(back, m(i));
                [back2, ~] = SkyboxTextureEnum.getEnumForFileName(m(i).cubeFolderName);
                testCase.verifyEqual(back2, m(i));
            end

            p = LaunchVehicleViewProfile();
            p.setSkyboxTextureAndSync(SkyboxTextureEnum.DefaultKsp);
            testCase.verifyEqual(p.skyboxTexture, SkyboxTextureEnum.DefaultKsp);
            testCase.verifyTrue(isfile(p.getSkyboxPreviewPath()), 'preview path resolves to a file');
        end
    end

    methods(Access = private)
        function [lvdData, evt2] = propagatedMission(testCase)
            bodyInfo = testCase.kerbin;
            frame = testCase.kerbinFrame;

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, bodyInfo.radius + 300, 0, 0.1, 0, 0, 0, frame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(30);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(30);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            lvdData.script.executeScript(false, evt1, false, false, false, false, false);
        end
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
