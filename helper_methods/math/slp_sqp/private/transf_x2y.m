function [gradfy,gradgy,y,dylb,dyub]=transf_x2y(p,gradf,gradg,x,dxlb,dxub,TolX)
% Transform x to y intermediate variables
if nargin<7 || isempty(TolX), TolX=1e-8; end
if all( p==1 )
   y = x;
   if nargin>4
      dylb = dxlb;
      dyub = dxub;
   end
   gradfy = gradf;
   gradgy = gradg;
else
   dxdy = x.^(1-p)./p;
   gradfy = gradf.*dxdy;
   gradgy = repmat(dxdy,1,size(gradg,2)).*gradg;
   y = x.^p;
   if nargin>4
      dylb = dxlb;
      dyub = dxub;
      i = p>0 & p~=1;
      dylb(i) = (max(TolX,x(i)+dxlb(i))).^p(i) - y(i);
      dyub(i) =          (x(i)+dxub(i) ).^p(i) - y(i);
      i = p<0;
      dylb(i) =           (x(i)+dxub(i)).^p(i) - y(i);
      dyub(i) = (max(TolX,x(i)+dxlb(i))).^p(i) - y(i);
      if any(dylb>dyub),     error('mpea:dylub','wrong bound'), end
      if any(~isreal(dylb)), error('mpea:dylb','complex dylb'), end
      if any(~isreal(dyub)), error('mpea:dyub','complex dyub'), end
   end
end
end