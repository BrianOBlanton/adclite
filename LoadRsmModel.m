function [Model,TheGrid]=LoadRsmModel(ADCLHOME,ModelDir,ModelFile,ModelURL,ModelName,GridName)

global Debug
if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

MODELHOME=fullfile(ADCLHOME, ModelDir);
MODELPATH=fullfile(ADCLHOME, ModelFile);

if ~exist(MODELHOME,'dir')
    fprintf('\nAdcL++ Downloading model.  This may take several minutes ... \n')
    ModelTar=websave(MODELPATH, ModelURL)
    fprintf('\nAdcL++ Model downloaded.\n')
    fprintf('\nAdcL++ Expanding model data.\n')
    untar(ModelTar, ADCLHOME)
    fprintf('\nAdcL++ Model data expanded.\n')
else
    fprintf('\nAdcL++ Model aldready exists.\n')

end

temp=sprintf('%s/%s/%s.mat', ADCLHOME, ModelDir, ModelName);
temp=load(temp);
com=sprintf('Model=temp.%s;', ModelName);
eval(com);

temp=load(sprintf('%s/%s/%s.mat', ADCLHOME, ModelDir, GridName));
com=sprintf('TheGrid=temp.;', ModelName);
TheGrid=temp.fgs;

nm='large_group_of_indices_for_R';
temp=load(sprintf('%s/%s/%s.mat', ADCLHOME, ModelDir, nm));
com=sprintf('idx=temp.%s;',nm);
eval(com)
TheGrid.idx=idx';
