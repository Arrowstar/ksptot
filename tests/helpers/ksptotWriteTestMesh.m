function [Vcube, Fcube] = ksptotWriteTestMesh(kind, filePath)
%ksptotWriteTestMesh Writes a unit cube (corners at 0/1) as a mesh file
%for the LVD mesh import tests, returning the cube's canonical geometry.
%
%   [V, F] = ksptotWriteTestMesh('stl-binary', path)
%   [V, F] = ksptotWriteTestMesh('stl-ascii',  path)
%   [V, F] = ksptotWriteTestMesh('obj',        path)   % 6 quad faces
%   [V, F] = ksptotWriteTestMesh('obj-tri',    path)   % 12 triangles
%
%   V is 8 x 3, F is 12 x 3 (the triangulation used for the STL variants and
%   the one 'obj' fan-triangulates into).

    Vcube = [0 0 0;
             1 0 0;
             1 1 0;
             0 1 0;
             0 0 1;
             1 0 1;
             1 1 1;
             0 1 1];

    %quad faces, consistently wound
    Q = [1 4 3 2;   % bottom (z=0)
         5 6 7 8;   % top (z=1)
         1 2 6 5;   % front (y=0)
         2 3 7 6;   % right (x=1)
         3 4 8 7;   % back (y=1)
         4 1 5 8];  % left (x=0)

    Fcube = zeros(12,3);
    for i = 1:6
        Fcube(2*i-1,:) = Q(i,[1 2 3]);
        Fcube(2*i,:)   = Q(i,[1 3 4]);
    end

    switch(lower(kind))
        case 'stl-binary'
            fid = fopen(filePath, 'w');
            header = zeros(1,80,'uint8');
            header(1:numel('ksptot test cube')) = uint8('ksptot test cube');
            fwrite(fid, header, 'uint8');
            fwrite(fid, size(Fcube,1), 'uint32');
            for i = 1:size(Fcube,1)
                tri = Vcube(Fcube(i,:),:);
                n = cross(tri(2,:)-tri(1,:), tri(3,:)-tri(1,:));
                n = n / norm(n);
                fwrite(fid, single(n), 'float32');
                fwrite(fid, single(tri'), 'float32');
                fwrite(fid, 0, 'uint16');
            end
            fclose(fid);

        case 'stl-ascii'
            fid = fopen(filePath, 'w');
            fprintf(fid, 'solid ksptot_test_cube\n');
            for i = 1:size(Fcube,1)
                tri = Vcube(Fcube(i,:),:);
                n = cross(tri(2,:)-tri(1,:), tri(3,:)-tri(1,:));
                n = n / norm(n);
                fprintf(fid, '  facet normal %g %g %g\n', n);
                fprintf(fid, '    outer loop\n');
                for j = 1:3
                    fprintf(fid, '      vertex %g %g %g\n', tri(j,:));
                end
                fprintf(fid, '    endloop\n');
                fprintf(fid, '  endfacet\n');
            end
            fprintf(fid, 'endsolid ksptot_test_cube\n');
            fclose(fid);

        case 'obj'
            fid = fopen(filePath, 'w');
            fprintf(fid, '# ksptot test cube (quads)\n');
            fprintf(fid, 'o cube\n');
            for i = 1:size(Vcube,1)
                fprintf(fid, 'v %g %g %g\n', Vcube(i,:));
            end
            fprintf(fid, 'vn 0 0 1\n');
            fprintf(fid, 'vt 0 0\n');
            for i = 1:size(Q,1)
                fprintf(fid, 'f %d/1/1 %d/1/1 %d/1/1 %d/1/1\n', Q(i,:));
            end
            fclose(fid);

        case 'obj-tri'
            fid = fopen(filePath, 'w');
            for i = 1:size(Vcube,1)
                fprintf(fid, 'v %g %g %g\n', Vcube(i,:));
            end
            for i = 1:size(Fcube,1)
                fprintf(fid, 'f %d %d %d\n', Fcube(i,:));
            end
            fclose(fid);

        otherwise
            error('ksptotWriteTestMesh:badKind', 'Unknown mesh kind "%s".', kind);
    end
end
