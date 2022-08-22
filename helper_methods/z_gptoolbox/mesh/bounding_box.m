function [BB,BF,BQ] = bounding_box(V,varargin)
  % BOUNDING_BOX  Compute the bounding box of a set of points
  % 
  % [BB,BF] = bounding_box(V)
  % [BB,BF,BQ] = bounding_box(V,'ParameterName',ParameterValue, ...)
  %
  % Inputs:
  %   V  #V by dim list of points
  %   Optional:
  %     'Epsilon' followed by epsilon to offset min and max by {0}
  % Outputs:
  %   BB 2^dim list of boundary box vertices
  %   BF #BF by #dim list of facets
  %   BQ  #BQ by 4 list of quads (only if dim == 3)
  %

  epsilon = 0;
  params_to_variables = containers.Map( ...
    {'Epsilon'}, ...
    {'epsilon'});
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


  dim = size(V,2);
  minV = min(V)-epsilon;
  maxV = max(V)+epsilon;
  C = combn([0 1],dim) == 1;
  BB = bsxfun(@times,C,minV) + bsxfun(@times,~C,maxV);
  
  switch size(BB,2)
  case 2
    BF = [2,1;4,2;1,3;3,4];
  case 3
    BF = [2,1,3;4,2,3;1,2,5;5,3,1;4,6,2;5,2,6;4,3,7;5,7,3;5,6,7;4,8,6;8,4,7;7,6,8];
    BQ = [1 3 4 2;7 5 6 8;1 5 7 3;6 2 4 8;3 7 8 4;5 1 2 6];
  otherwise
    error('Only 2D and 3D objects are supported.');
  end
  

end
