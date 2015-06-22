function [Model,TheGrid]=LoadRsmModel(ADCLHOME,ModelDir,ModelFile,ModelURL,ModelName,GridName)

global Debug
if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

MODELHOME=fullfile(ADCLHOME, ModelDir);
MODELPATH=fullfile(ADCLHOME, ModelFile);

if ~exist(MODELHOME,'dir')
    fprintf('\nSSViz++ Downloading model.  This may take several minutes ... \n')
    ModelTar=websave(MODELPATH, ModelURL)
    fprintf('\nSSViz++ Model downloaded.\n')
    fprintf('\nSSViz++ Expanding model data.\n')
    untar(ModelTar, ADCLHOME)
    fprintf('\nSSViz++ Model data expanded.\n')
else
    fprintf('\nSSViz++ Model aldready exists.\n')

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
