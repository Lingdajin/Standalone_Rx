function Sim_Add_Path_Minimal()
global MainFileAddress
% 只添加独立项目内部路径，保证整个目录可直接迁移。
root = fileparts(mfilename('fullpath'));
MainFileAddress = struct();
MainFileAddress.address = root;

addpath(root);
addpath(genpath(fullfile(root, 'lib')));
end
