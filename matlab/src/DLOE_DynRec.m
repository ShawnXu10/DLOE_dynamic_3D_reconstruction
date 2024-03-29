function [Xopt,Lopt,sequence, caminput] = DLOE_DynRec(config)
%DLOE Summary of this function goes here
% param.data: caminput
%          caminput.x: 2D observations
%          caminput.K: camera intrinsic parameter for each frame
%          caminput.t: camera position for each frame
%          caminput.R: camera rotation matrix for each frame
%          caminput.cam_index: index of the frames belong to same video
% sequence. eg, [20 40 60] means 1~20 in video1, 21:40 in video2, and 41~60 in video3
%          caminput.order: global ordering or false for no sequencing information            
%   Output: Xopt: optimized structure
%           Lopt: optimized Laplacian matrix
%           sequence: optimized global sequencing information

param = ReadYaml(config);

load(param.data)
nframes = length(caminput.x);
njoints = size(caminput.x{1},2);

%======build viewing rays based on 2D observation and camera parameters====
disp('Preprocessing......')
caminput.ray = cell(nframes, 1);
for f = 1:nframes
    for p = 1:njoints
        ray_temp = caminput.R{f}'*inv(caminput.K{f})*caminput.x{f}(:,p);        
        ray_temp = ray_temp/norm(ray_temp);
        caminput.ray{f}(:,p) = ray_temp;
    end
end
disp('Preprocess done')

%==================initial structure by triangulation======================
disp('Initializing structure......')
[ X_init,~,~] = X_initial( caminput.ray, caminput.t, caminput.cam_index);
disp('Initialization done')

%=========================recontruct bt DLOE===============================
disp('Reconstructing by DLOE......')
[Xopt, Wopt, Dopt] = Triconvex_opt(X_init, caminput.ray, caminput.t, caminput.cam_index,param, caminput.order);
Lopt = Dopt*Wopt;
disp('Reconstruction done')

%=============compute sequecing the optimized structure ===================
if caminput.order
else
    param.cam_index = caminput.cam_index;
    [~, sequence, ~] = SequenceDReduce( Xopt', param );
end