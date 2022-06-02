function [CV,CF] = cylinder_mesh(R,N,varargin);
  % CYLINDER_MESH  
  %
  %[CV,CQ] = cylinder_mesh(R,N);
  %[CV,CF] = cylinder_mesh(R,N,'ParameterName',ParameterValue, ...)
  %
  % Inputs:
  %   R  radius
  %   N number of vertices around axs
  %   Optional:
  %     'Quads'  whether to output quads instead of triangles {false}
  %     'Caps'  whether to include caps to close the mesh (doesn't apply to
  %       quads) {false}
  %     'Stacks' number of face rings on the side of the cylinder {1}
  % Outputs:
  %   CV  #CV by 3 list of mesh vertex positions
  %   CF  #CF by 3 list of mesh triangle indices into rows of CV
  %
  % See also: cylinder

  if nargin<1
    R = 1;
  end
  if nargin<2
    N = 20;
  end

  quads = false;
  caps = false;
  stacks = 1;
  % Map of parameter names to variable names
  params_to_variables = containers.Map( ...
    {'Caps','Quads','Stacks'}, ...
    {'caps','quads','stacks'});
  v = 1;
  while v <= numel(varargin)
    param_name = varargin{v};
    if isKey(params_to_variables,param_name)
      assert(v+1<=numel(varargin));
      v = v+1;
      % Trick: use feval on anonymous function to use assignin to this workspace
      feval(@()assignin('caller',params_to_variables(param_name),varargin{v}));
    else
      error('Unsupported parameter: %s',varargin{v});
    end
    v=v+1;
  end
  CV = [];
  CF = [];
  for stack = 1:stacks
    [X,Y,Z] = cylinder(R,N);
    if quads
      surf2patch_params = {};
    else
      surf2patch_params = {'triangles'};
    end
    [CFs,CVs] = surf2patch(X,Y,Z,surf2patch_params{:});
    CF = [CF;size(CV,1)+CFs];
    CV = [CV;CVs+[0 0 stack-1]];
  end

  if caps
    assert(~quads,'Caps only available for triangles');
    % 13/11/2018
    %CF = [CF;fill_holes(CV,CF)];
    OB = [1:2:2*N      ; 2*N-1 1:2:2*N-3]';
    OT = 2*(N+1)*(stacks-1)+[2*N 2:2:2*N-2; 2:2:2*N        ]';
    CF = [ ...
      CF; ...
      repmat(size(CV,1)+1,size(OB,1),1) OB; ...
      repmat(size(CV,1)+2,size(OT,1),1) OT];
    CV = [CV;0 0 0;0 0 stacks];
  end

  [CV,~,I] = remove_duplicate_vertices(CV,eps);
  CV = CV./[1 1 stacks];
  CF = I(CF);
end
