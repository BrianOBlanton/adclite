% This is the remote InstanceDefaults.m file that sets instance-specific parameters
% this file is slated to go away soon.

switch SSVizOpts.Instance
    case {'asgs1'}
        %SSVizOpts.DefaultBoundingBox=[ -88.6050  -88.5420   30.3270   30.3720];  
        SSVizOpts.DefaultBoundingBox=[-100 -78 17 33];
    case {'hindfor','nodcorps','hfip','gomex'}
        SSVizOpts.DefaultBoundingBox=[-100 -78 17 33];
    case {'hfip_ec95','hfip_R3','2'}
        SSVizOpts.DefaultBoundingBox=[-84 -60 20 45];
    case {'wfl'}
        SSVizOpts.DefaultBoundingBox=[-88 -75 20 31];
    case {'ncfs','hfip_NC'}
        SSVizOpts.DefaultBoundingBox=[ -83 -63 20 45];
    otherwise
        SSVizOpts.DefaultBoundingBox=[];
end

