function fgs_R = transfer_to_grid(zhat, stormname)

load 'nc_inundation_v9.81_adjVAB_MSL.mat';
load 'large_group_of_points_for_R.mat';
load 'large_group_of_indices_for_R.mat';
fgs_R = fgs;

% What do we do about fgs_R.z??
fgs_R.zhat = fgs_R.z;
fgs_R.zhat(:) = NaN;
fgs_R.zhat(large_group_of_indices_for_R) = zhat;
fgs_R.tag = stormname;