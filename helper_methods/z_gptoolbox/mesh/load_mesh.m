function [V,F] = load_mesh(filename,varargin)
  % read in vertices and faces from a .off or .obj file
  % 
  % [V,F] = load_mesh(filename)
  % [V,F] = load_mesh(filename,'ParameterName',ParameterValue, ...)
  %
  % Input:
  %   filename  file holding mesh
  %   Optional:
  %     'Quiet' followed by whether to be quiet {false}
  % Output:
  %   V (vertex list) 
  %   F (face list) fields
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
  % See also: readOBJ, readOBJfast, readOFF
  %

  % parse any optional input
  v = 1;
  quiet = false;
  while(v <= numel(varargin))
    switch varargin{v}
    case 'Quiet'
      v = v+1;
      assert(v<=nargin);
      quiet = varargin{v};
      quiet = quiet * 1;
    otherwise
      error(['Unsupported parameter: ' varargin{v}]);
    end
    v = v + 1;
  end

  % if mex libigl reader exists use that (up to 25x faster for .obj)
  if exist('read_triangle_mesh','file')==3
    try
      [V,F] = read_triangle_mesh(GetFullPath(filename));
      if ~isempty(V) && ~isempty(F)
        return;
      end
      % else keep trying below
    catch e
      warning(e.message);
      % else keep trying below
    end
  end
  
  [~,~,ext] = fileparts(filename);
  ext = lower(ext);
  switch ext
  case '.3ds'
    [V,F] = read3DS(filename);
  case '.obj'
    try
      [V,F] = readOBJfast(filename);
    catch exception
      if ~quiet
        fprintf('Fast reader failed, retrying with more robust, slower reader\n');
      end
      [V,F] = readOBJ(filename);
    end
  case '.off'
    [V,F] = readOFF(filename);
  case '.ply'
    [V,F] = readPLY(filename);
  case '.stl'
    [V,F] = readSTL(filename);
  case '.wrl'
    [V,F] = readWRL(filename);
  case '.xml'
    [V,F] = read_mesh_from_xml(filename);
  otherwise
    error('Unknown mesh format: %s',ext);
  end
end
