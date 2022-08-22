function [VV,FF,WrV,WrF,JJ,WV,PE,mbV,mbF,WrJ,HJ] = joints(V,E,varargin)
  % JOINTS Construct joints around a wire mesh given as a graph
  % 
  % [VV,FF] = joints(V,E);
  % [VV,FF,WrV,WrF,JJ,WV,PE] = joints(V,E,'ParameterName',ParameterValue, ...)
  %
  % Inputs:
  %   V  #V by 3 list of wire graph vertex positions in mm
  %   E  #E by 2 list of edge indices into V
  %   Optional:
  %     'EmbossHeight' followed by height of embossed letters
  %       {0.5*JointThickness}
  %     'LabelSockets'  followed by whether to label sockets with an engraved
  %        number
  %     'JointThickness' followed by thickness of joints {0.25*Radius}
  %     'Overhang'  followed by amount of overhang passed end of joint
  %       {2*Radius}
  %     'PolySize'  followed by number of sides on dowel rod cross-sectional
  %       polygon
  %     'Radius'  followed by dowel rod radius
  %     'Tol'  followed by engineering tolerance
  % Outputs:
  %   VV  #VV by 3 list of vertex positions of joint mesh
  %   FF  #FF by 3 list of triangle indices into VV of joint mesh
  %   WrV  #WrV by 3 list of vertex positions of rod mesh
  %   WrF  #WrF by 3 list of triangle indices into VV of rod mesh
  %   JJ  #FF list of indices into rows of V indicating about which vertex this
  %     joint is.
  %   WV  #E*2 by 2 list of rod edge endpoint positions
  %   PE  #E by 2 list of rod edge indices into WV
  %   

  % default values
  poly = 5;
  r = 0.05;
  tol = 0.01;
  hang = [];
  th = [];
  emboss_height = [];
  label_sockets = false;
  save_all = [];
  % Map of parameter names to variable names
  params_to_variables = containers.Map( ...
    {'EmbossHeight','JointThickness','LabelSockets','Overhang','PolySize','Radius','SaveAll','Tol'}, ...
    {'emboss_height','th','label_sockets','hang','poly','r','save_all','tol'});
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

  if isempty(r)
    assert(size(poly,2) == 2,'poly should contain a 2d polyon');
    assert(size(poly,1) > 2,'poly should contain a 2d polyon');
    r = max(normrow(poly));
    % now poly is unit length
    poly = poly/r;
  end
  if numel(poly)>1
    assert(size(poly,2) == 2,'poly should contain a 2d polyon');
    assert(size(poly,1) > 2,'poly should contain a 2d polyon');
    npoly = size(poly,1);
  else
    npoly = poly;
  end

  if isempty(th)
    th = 0.25*r;
  end
  if isempty(emboss_height)
    emboss_height = 0.5*th;
  end
  if isempty(hang)
    hang = 2*r;
  end

  % R: outer thickness of cylindrical part of bar
  R = (r+tol);

  U = normalizerow(V(E(:,2),:)-V(E(:,1),:));
  A = adjacency_matrix(E);
  n = size(V,1);
  ne = size(E,1);
  %theta = inf(ne,2);
  cos_theta = -inf(ne,2);
  E2V = sparse(repmat(1:ne,2,1)',E,[ones(ne,1),-ones(ne,1)],ne,n);

  % loop over edges
  for ei = 1:ne
    % loop over each direction
    for c = 1:2
      i = E(ei,c);
      j = E(ei,3-c);
      % other edges
      N = setdiff(find(E2V(:,i)),ei);
      for nei = reshape(N,1,[])
        flip = (E(nei,c) == i)*2-1;
        %theta(ei,c) = min(theta(ei,c),acos(flip*sum(U(ei,:).*U(nei,:),2)));
        cos_theta(ei,c) = max(cos_theta(ei,c),(flip*sum(U(ei,:).*U(nei,:),2)));
      end
    end
  end
  %assert(min(theta(:))>eps,'All angles should be >0. Degenerate/co-linear edge(s)?');
  assert(1-max(cos_theta(:))>eps,'All angles should be >0. Degenerate/co-linear edge(s)?');
  %% WTF!?! atan of an angle?
  %J = R./atan(theta./2);
  %theta(abs(theta)>(pi/2)) = pi/2;
  cos_theta( cos_theta < 0 ) = 0;
  theta = acos(cos_theta);
  %min(abs(theta(theta~=0)))*180/pi
  J = R.*sqrt((1+cos_theta)./(1-cos_theta));
  %J = R./tan(abs(theta./2));
  %assert(all(max(imag(J)) < 1e-9),'J should be real-ish');
  %J = real(J);
  assert(~any(isinf(J(:))),'All offsets should be finite');

  offset = @(V,E,J) [ ...
    V(E(:,1),:)+U.*J(:,1); ...
    V(E(:,2),:)-U.*J(:,2)];
  HV = offset(V,E,J+hang);
  %% Q: Why is there a +th here? 
  %% A: The +th means we're _shrinking_ the rods, but, still, shouldn't it be
  %%    +tol/2 if anything? Or better, shouldn't JV account for -tol/2 ?
  %WV = offset(V,E,J+th);
  %JV = offset(V,E,J);
  WV = offset(V,E,J);
  JV = offset(V,E,J-tol/2);
  %% Q: Why did I introduce this complicated min(J...) ?
  %% A: Because otherwise there can be a sharp angle directly behind the hole.
  %%                 ___________________
  %% thin wall --->/*__________________
  %%              / |
  %%             /  |__________________
  %%            /   ___________________
  %%           /    |
  %%          / __  |
  %%         | |  | |
  %% Q: I still don't understand the sqrt(2) though, is it just an extra scale
  %%    factor >1?
  ZV = offset(V,E,min(J-tol/2-th*sqrt(2),2*R));
  PE = [1:ne;ne+(1:ne)]';


  % Geometry of rods + tolerance that will be subtracted
  [JRV,JRF,JRJ,JRI] = edge_cylinders(JV,PE,'Thickness',2*R,'PolySize',poly);
  % The actual geometry of the rods
  [WrV,WrF,WrJ,WrI] = edge_cylinders(WV,PE,'Thickness',2*r,'PolySize',poly);
  %[HOV,HOF,HOH,HOI] = edge_cylinders(HV,PE,'Thickness',2*(1+2*(1-cos(pi/poly)))*(r+th+tol),'PolySize',poly);
  %[ZOV,ZOF,ZOZ,ZOI] = edge_cylinders(ZV,PE,'Thickness',2*(1+2*(1-cos(pi/poly)))*(r+th+tol),'PolySize',poly);

  HZE = (1:size(HV,1))' +[0 size(HV,1)];
  % Avoid extra spin for edges going the other direction (the fact that I have
  % to do this hints that my axisanglebetween in edge_cylinders is not finding
  % the minimal twist solution...)
  HZE(1:end/2,:) = fliplr(HZE(1:end/2,:));
  HZV = [HV;ZV];
  %hr = (1+2*(1-cos(pi/npoly)))*(r+th+tol)
  hr = r+th+tol;
  [HZOV,HZOF,HZJ,HZI] = edge_cylinders( ...
    HZV,HZE, ...
    'Thickness',2*hr,'PolySize',poly);

  CV = [];
  CF = [];
  CJ = [];
  % Annoying bug if there's just one edge
  vec = @(X) X(:);
  % Loop over vertices
  for i = 1:n
    if sum(A(:,i))>1
      Vi = [V(i,:);  ...
        HZOV(vec(E(mod(HZI-1,2*ne)+1)==i) & HZI>size(HV,1),:)];
      Fi = convhull(Vi);
      CF = [CF;size(CV,1)+Fi];
      CV = [CV;Vi];
      CJ = [CJ;repmat(i,size(Fi,1),1)];
    end
  end

  %clf;
  %hold on;
  %%tsurf(JRF,JRV,'FaceColor',[1 0 0],falpha(0.5,0));
  %%tsurf(WrF,WrV,'FaceColor',[0 1 0],falpha(0.5,0));
  %tsurf(HOF,HOV,'FaceColor',[0 0 1],falpha(0.1,0));
  %tsurf(ZOF,ZOV,'FaceColor',[1 1 0],falpha(0.1,0));
  %tsurf(HZOF,HZOV,'FaceColor',[0 1 1],falpha(0.1,0));
  %scatter3(HV(:,1),HV(:,2),HV(:,3),'.','SizeData',1000);
  %scatter3(ZV(:,1),ZV(:,2),ZV(:,3),'.','SizeData',500);
  %scatter3(HZV(:,1),HZV(:,2),HZV(:,3),'.','SizeData',500);
  %plot_edges(HZV,HZE,'LineWidth',3);
  %%tsurf(FF,VV,'FaceColor',[1 0 1],falpha(1,1));
  %hold off;
  %axis equal;view(2);
  %error

  % Build labels at the end of each piece of wood
  LV = [];
  LF = [];
  if label_sockets
    fprintf('labeling sockets...\n');
    % loop over edges
    for ei = 1:ne
      % loop over each direction
      [LVei,LFei] = text_to_mesh(sprintf('%02d',ei),'TriangleFlags',' ');
      LVei = LVei-0.5*(max(LVei)-min(LVei));
      LVei = LVei/max(normrow(LVei));
      LVei(:,3) = LVei(:,3)/max(LVei(:,3));
      LVei = LVei*diag([r-th r-th emboss_height]);
      for c = 1:2
        i = E(ei,c);
        j = E(ei,3-c);
        Evec = normalizerow(V(j,:)-V(i,:));
        [w,a] = axisanglebetween(Evec,repmat([0 0 1],size(Evec,1),1));
        R = axisangle2matrix(w,a);
        LVi = (LVei+[0 0 J(ei,c)])*R+V(i,:);
        LF = [LF;LFei+size(LV,1)];
        LV = [LV;LVi];
      end
    end
  end

  fprintf('boolean...\n')
  JJ = [CJ;E(HZJ)];
  mbV = [CV;HZOV];
  mbF = [CF;size(CV,1)+HZOF];
  HJ = [zeros(numel(CJ),1);HZJ;-ones(size([JRF;size(JRV,1)+LF],1),1)];

  [VV,FF,mJJ] = mesh_boolean(mbV,mbF,[JRV;LV],[JRF;size(JRV,1)+LF],'minus');
  [~,C] = connected_components(FF);
  CJ = zeros(max(C),1);
  CJ(C(mJJ<=numel(JJ))) = JJ(mJJ(mJJ<=numel(JJ)));
  JJ = CJ(C);
  HJ = HJ(mJJ);
 
  

  if ~isempty(save_all)
    save(save_all);
  end


  % sanity check only makes sense if tol is positive
  if tol>0
    fprintf('check...\n')
    assert(isempty(intersect_other(VV,FF(doublearea(VV,FF)>0,:),WrV,WrF)));
  end
end
