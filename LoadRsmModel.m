function [Model,TheGrid]=LoadRsmModel(ADCLHOME,ModelDir,ModelFile,ModelURL,ModelName,GridName)

global Debug
if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

MODELHOME=fullfile(ADCLHOME, ModelDir);
MODELPATH=fullfile(MODELHOME, ModelFile);
addpath(MODELHOME)

if ~exist(MODELHOME,'dir')
    fprintf('\nAdcL++ Making Model directory... \n')
    mkdir(MODELHOME)
end

if ~exist(MODELPATH,'file')
    fprintf('\nAdcL++ Downloading model.  This may take several minutes ... \n')
    ModelTar=websave(MODELPATH, ModelURL);
    fprintf('AdcL++ Model downloaded.\n')
    fprintf('AdcL++ Expanding model data.\n')
    untar(ModelTar, MODELHOME)
    fprintf('AdcL++ Model data expanded.\n')
else
    fprintf('\nAdcL++ Model files already exist.\n')
end

fprintf('AdcL++ Loading model ...\n')
temp=sprintf('%s/%s/%s.mat', ADCLHOME, ModelDir, ModelName);
temp=load(temp);
com=sprintf('Model=temp.%s;', ModelName);
eval(com);
%Model.CrossingLines=CrossingLatLines;

%temp=load(sprintf('%s/%s/%s.mat', ADCLHOME, ModelDir, GridName));
%com=sprintf('TheGrid=temp.;', ModelName);
TheGrid=Model.TheGrid; 
TheGrid.nn=length(TheGrid.x);

% nm='large_group_of_indices_for_R';
% temp=load(sprintf('%s/%s/%s.mat', ADCLHOME, ModelDir, nm));
% com=sprintf('idx=temp.%s;',nm);
% eval(com)
% TheGrid.idx=idx';
TheGrid.idx=Model.NodeIndices;

% set X vector to mean of parameters
%Model.X=mean(Model.P);
Model.minP=min(Model.P);
Model.maxP=max(Model.P);
Model.X=mean([Model.minP' Model.maxP']');