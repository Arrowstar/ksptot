function rotate(h,azel,alpha,origin)
%ROTATE Rotate objects about specified origin and direction.
%   ROTATE(H,[THETA PHI],ALPHA) rotates the objects with handles H
%   through angle ALPHA about an axis described by the 2-element
%   direction vector [THETA PHI] (spherical coordinates).  
%   All the angles are in degrees.  The handles in H must be children
%   of the same axes.
%
%   THETA is the angle in the xy plane counterclockwise from the
%   positive x axis.  PHI is the elevation of the direction vector
%   from the xy plane (see also SPH2CART).  Positive ALPHA is defined
%   as the righthand-rule angle about the direction vector as it
%   extends from the origin.
%
%   ROTATE(H,[X Y Z],ALPHA) rotates the objects about the direction
%   vector [X Y Z] (Cartesian coordinates). The direction vector
%   is the vector from the center of the plot box to (X,Y,Z).
%
%   ROTATE(...,ORIGIN) uses the point ORIGIN = [x0,y0,y0] as
%   the center of rotation instead of the center of the plot box.
%
%   See also SPH2CART, CART2SPH.

%   Copyright 1984-2009 The MathWorks, Inc. 

%   Bug fixed:  now rotates the vertexnormals property of surf objects
%               in order to correctly calculate the lighting.
%               Luc Masset, 2012 (luc.masset@heliodon.net)

% Determine the default origin (center of plot box).
if nargin < 4
  if ~ishghandle(h)
    error(id('InvalidHandle'),'H must contain axes children only.');
  end
  ax = ancestor(h(1),'axes');
  if isempty(ax) || ax==0,
    error(id('InvalidHandle'),'H must contain axes children only.');
  end
  origin = sum([get(ax,'xlim')' get(ax,'ylim')' get(ax,'zlim')'])/2;
end

% find unit vector for axis of rotation
if numel(azel) == 2 % theta, phi
    theta = pi*azel(1)/180;
    phi = pi*azel(2)/180;
    u = [cos(phi)*cos(theta); cos(phi)*sin(theta); sin(phi)];
elseif numel(azel) == 3 % direction vector
    u = azel(:)/norm(azel);
end

alph = alpha*pi/180;
cosa = cos(alph);
sina = sin(alph);
vera = 1 - cosa;
x = u(1);
y = u(2);
z = u(3);
rot = [cosa+x^2*vera x*y*vera-z*sina x*z*vera+y*sina; ...
       x*y*vera+z*sina cosa+y^2*vera y*z*vera-x*sina; ...
       x*z*vera-y*sina y*z*vera+x*sina cosa+z^2*vera]';

for i=1:numel(h),
  t = get(h(i),'type');
  skip = 0;
  if strcmp(t,'surface') || strcmp(t,'line') || strcmp(t,'patch')
    
    % If patch, rotate vertices  
    if strcmp(t,'patch')
       verts = get(h(i),'Vertices');
       x = verts(:,1); y = verts(:,2); 
       if size(verts,2)>2
          z = verts(:,3);
       else
          z = [];
       end
       
    % If surface or line, rotate {x,y,z}data   
    else
       x = get(h(i),'xdata');
       y = get(h(i),'ydata');
       z = get(h(i),'zdata');
    end
    
    if isempty(z)
       z = -origin(3)*ones(size(y));
    end
    [m,n] = size(z);
    if numel(x) < m*n
      [x,y] = meshgrid(x,y);
    end
  elseif strcmp(t,'text')
    p = get(h(i),'position');
    x = p(1); y = p(2); z = p(3);
  elseif strcmp(t,'image')
    x = get(h(i),'xdata');
    y = get(h(i),'ydata');
    z = zeros(size(x));
  else
    skip = 1;
  end
  
  if ~skip,
    [m,n] = size(x);
    newxyz = [x(:)-origin(1), y(:)-origin(2), z(:)-origin(3)];
    newxyz = newxyz*rot;
    newx = origin(1) + reshape(newxyz(:,1),m,n);
    newy = origin(2) + reshape(newxyz(:,2),m,n);
    newz = origin(3) + reshape(newxyz(:,3),m,n);

    if strcmp(t,'surface') || strcmp(t,'line')
      set(h(i),'xdata',newx,'ydata',newy,'zdata',newz);
      if strcmp(t,'surface')                    % bug fixed
        vn=get(h(i),'vertexnormals');           % bug fixed
        vnx=vn(:,:,1);                          % bug fixed
        vny=vn(:,:,2);                          % bug fixed
        vnz=vn(:,:,3);                          % bug fixed
        vnxyz=[vnx(:) vny(:) vnz(:)]*rot;       % bug fixed
        for j=1:3,                              % bug fixed
          vn(:,:,j)=reshape(vnxyz(:,j),m,n);    % bug fixed
        end                                     % bug fixed
        set(h(i),'vertexnormals',vn);           % bug fixed
      end                                       % bug fixed
    elseif strcmp(t,'patch')
      set(h(i),'Vertices',[newx,newy,newz]); 
    elseif strcmp(t,'text')
      set(h(i),'position',[newx newy newz])
    elseif strcmp(t,'image')
      set(h(i),'xdata',newx,'ydata',newy)
    end
  end
end

function str=id(str)
str = ['MATLAB:rotate:' str];
