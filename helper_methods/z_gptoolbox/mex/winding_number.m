function [W] = winding_number(V,F,O,varargin)
  % WINDING_NUMBER Compute the sum of solid angles of a triangle (tetrahedron)
  % described by points (vectors) V
  % 
  % [W] = winding_number(V,F,O)
  % [W] = winding_number(V,F,O,'ParameterName',ParameterValue, ...)
  %
  % Inputs:
  %  V  #V by 3 list of vertex positions
  %  F  #F by 3 list of triangle indices
  %  O  #O by 3 list of origin positions
  %  Optional inputs:
  %    'Hierarchical'  followed by true or false. Use hierarchical evaluation.
  %      for mex: {true}, for matlab this is not supported 
  %    'Fast' followed by whether to use fast-winding-number {false}
  %    'RayCast' followed by true or flase. Use ray cast version of approximate
  %      evaluation: {false}
  %    'TwoDRays' followed by true or false. Use 2d rays only.
  %    'NumRays' followed by the number of rays to cast for each origin
  % Outputs:
  %  W  no by 1 list of winding numbers
  %

  warning('not mex...');
  S = solid_angle(V,F,O);
  W = sum(S,2);
  switch size(F,2)
  case 3
    W = W/(2*pi);
  case 4
    W = W/(4*pi);
  end

end
