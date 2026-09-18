classdef MeshFileReaderTest < KsptotTestCase
    %MeshFileReaderTest lvd_readMeshFile (F8 vehicle mesh import): binary
    %and ASCII STL, Wavefront OBJ, vertex welding, fan triangulation and
    %the error identifiers the UI relies on.

    methods(Test)

        function readsABinaryStlCube(testCase)
            [path, cleanup] = testCase.tempFile('.stl'); %#ok<ASGLU>
            [Vcube, Fcube] = ksptotWriteTestMesh('stl-binary', path);

            [V, F, info] = lvd_readMeshFile(path);

            testCase.verifyEqual(info.format, 'stl-binary');
            testCase.verifyCubeGeometry(V, F, Vcube, Fcube);
            testCase.verifyEqual(info.numVertices, 8);
            testCase.verifyEqual(info.numFaces, 12);
            testCase.verifyEqual(info.bbox, [0 0 0; 1 1 1]);
        end

        function readsAnAsciiStlCube(testCase)
            [path, cleanup] = testCase.tempFile('.stl'); %#ok<ASGLU>
            [Vcube, Fcube] = ksptotWriteTestMesh('stl-ascii', path);

            [V, F, info] = lvd_readMeshFile(path);

            testCase.verifyEqual(info.format, 'stl-ascii');
            testCase.verifyCubeGeometry(V, F, Vcube, Fcube);
        end

        function binaryAndAsciiStlAgree(testCase)
            [pathB, cleanupB] = testCase.tempFile('.stl'); %#ok<ASGLU>
            [pathA, cleanupA] = testCase.tempFile('.stl'); %#ok<ASGLU>
            ksptotWriteTestMesh('stl-binary', pathB);
            ksptotWriteTestMesh('stl-ascii', pathA);

            [VB, FB] = lvd_readMeshFile(pathB);
            [VA, FA] = lvd_readMeshFile(pathA);

            testCase.verifyEqual(VA, VB, 'AbsTol', 1e-12, 'Both STL flavours produce the same welded vertices');
            testCase.verifyEqual(FA, FB, 'Both STL flavours produce the same faces');
        end

        function readsObjWithQuadsTextureAndNormalTokens(testCase)
            [path, cleanup] = testCase.tempFile('.obj'); %#ok<ASGLU>
            [Vcube, Fcube] = ksptotWriteTestMesh('obj', path);

            [V, F, info] = lvd_readMeshFile(path);

            testCase.verifyEqual(info.format, 'obj');
            testCase.verifyEqual(V, Vcube, 'OBJ vertices are read verbatim in file order');
            testCase.verifyEqual(F, Fcube, 'Quads fan-triangulate as [1 2 3],[1 3 4]');
        end

        function readsObjTrianglesAndRelativeIndices(testCase)
            [path, cleanup] = testCase.tempFile('.obj'); %#ok<ASGLU>
            fid = fopen(path, 'w');
            fprintf(fid, 'v 0 0 0\nv 1 0 0\nv 0 1 0\nv 0 0 1\n');
            fprintf(fid, '# a comment line\n\n');
            fprintf(fid, 'f 1 2 3\n');
            fprintf(fid, 'f -4 -3 -1\n');        % relative: 1 2 4
            fprintf(fid, 'f 2//1 3//1 4//1\n');  % v//vn form
            fclose(fid);

            [V, F] = lvd_readMeshFile(path);
            testCase.verifySize(V, [4 3]);
            testCase.verifyEqual(F, [1 2 3; 1 2 4; 2 3 4]);
        end

        function polygonWithFiveVerticesFansIntoThreeTriangles(testCase)
            [path, cleanup] = testCase.tempFile('.obj'); %#ok<ASGLU>
            fid = fopen(path, 'w');
            for k = 1:5
                fprintf(fid, 'v %g %g 0\n', cos(2*pi*k/5), sin(2*pi*k/5));
            end
            fprintf(fid, 'f 1 2 3 4 5\n');
            fclose(fid);

            [~, F] = lvd_readMeshFile(path);
            testCase.verifyEqual(F, [1 2 3; 1 3 4; 1 4 5]);
        end

        function rejectsUnknownExtensionAndMissingFile(testCase)
            [path, cleanup] = testCase.tempFile('.ply'); %#ok<ASGLU>
            fid = fopen(path, 'w'); fprintf(fid, 'ply\n'); fclose(fid);

            testCase.verifyError(@() lvd_readMeshFile(path), 'lvd_readMeshFile:badExtension');
            testCase.verifyError(@() lvd_readMeshFile([tempname(), '.stl']), 'lvd_readMeshFile:fileNotFound');
        end

        function rejectsTruncatedBinaryStl(testCase)
            [path, cleanup] = testCase.tempFile('.stl'); %#ok<ASGLU>
            ksptotWriteTestMesh('stl-binary', path);

            bytes = fileread(path);
            fid = fopen(path, 'w');
            fwrite(fid, bytes(1:end-25), 'uint8');   % chop half a facet off
            fclose(fid);

            testCase.verifyError(@() lvd_readMeshFile(path), 'lvd_readMeshFile:badStl');
        end

        function rejectsAnEmptyMesh(testCase)
            [path, cleanup] = testCase.tempFile('.obj'); %#ok<ASGLU>
            fid = fopen(path, 'w');
            fprintf(fid, 'v 0 0 0\nv 1 0 0\n');
            fclose(fid);
            testCase.verifyError(@() lvd_readMeshFile(path), 'lvd_readMeshFile:emptyMesh');

            [pathS, cleanupS] = testCase.tempFile('.stl'); %#ok<ASGLU>
            fid = fopen(pathS, 'w');
            fprintf(fid, 'solid empty\nendsolid empty\n');
            fclose(fid);
            testCase.verifyError(@() lvd_readMeshFile(pathS), 'lvd_readMeshFile:emptyMesh');
        end

        function rejectsObjFaceReferencingMissingVertex(testCase)
            [path, cleanup] = testCase.tempFile('.obj'); %#ok<ASGLU>
            fid = fopen(path, 'w');
            fprintf(fid, 'v 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 9\n');
            fclose(fid);
            testCase.verifyError(@() lvd_readMeshFile(path), 'lvd_readMeshFile:badObj');
        end
    end

    methods(Access = private)
        function verifyCubeGeometry(testCase, V, F, Vcube, Fcube)
            testCase.verifySize(V, [8 3], 'The 36 facet vertices weld down to the 8 cube corners');
            testCase.verifySize(F, [12 3]);
            testCase.verifyEqual(sortrows(V), sortrows(Vcube), 'AbsTol', 1e-12, 'Welded vertices are the cube corners');
            testCase.verifyTrue(all(F(:) >= 1 & F(:) <= 8), 'Face indices are in range');

            %Every triangle, resolved to coordinates, matches one of the
            %reference triangles regardless of vertex numbering.
            for i = 1:size(F,1)
                tri = V(F(i,:),:);
                found = false;
                for j = 1:size(Fcube,1)
                    refTri = Vcube(Fcube(j,:),:);
                    if(isequal(sortrows(tri), sortrows(refTri)))
                        found = true;
                        break;
                    end
                end
                testCase.verifyTrue(found, sprintf('Triangle %u is one of the reference cube triangles', i));
            end
        end

        function [path, cleanup] = tempFile(~, ext)
            path = [tempname(), ext];
            cleanup = onCleanup(@() deleteIfExists(path));
        end
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
