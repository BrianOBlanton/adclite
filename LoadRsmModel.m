function [Model,TheGrid]=LoadRsmModel(HOME,ModelName,GridName)

temp=sprintf('%s/Model/%s.mat',HOME,ModelName);
temp=load(temp);
com=sprintf('Model=temp.%s;',ModelName);
eval(com);

temp=load(sprintf('%s/Model/%s.mat',HOME,GridName));
com=sprintf('TheGrid=temp.;',ModelName);
TheGrid=temp.fgs;

nm='large_group_of_indices_for_R';
temp=load(sprintf('%s/Model/%s.mat',HOME,nm));
com=sprintf('idx=temp.%s;',nm);
eval(com)
TheGrid.idx=idx';
