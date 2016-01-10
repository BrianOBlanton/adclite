function zhat = central_ckv(Parameters, Response, c, k, weights, N_d, index, x)
% Call as: zhat = central_ckv(P, R, c, k, weights, n_d, index, x)

% there are three cells in this file
% first corresponds to parameters of surrogate model (that can be tuned)
% second one prepares the matrices needed
% third one selects a different input vector and runs the model

%%

v_aux=diag(1./mean(Parameters,1));             %normalization of model parameters 
Normalized_P=v_aux*Parameters';                %convert model parameters to normalised space

%n=size(Normalized_P,1);              % number of model paramaters
NSupportPoints=size(Normalized_P,2);  % number of support points

% Evaluate basis functiona at support points  
BasisFxns=[];
for i=1:NSupportPoints
    aux=[];
    for j=1:length(index)
        aux=[aux;Normalized_P(index(j),i)*Normalized_P(index(j:length(index)),i)];
    end
    BasisFxns=[BasisFxns;1 Normalized_P(:,i)' aux'];
end

%weights for norm used in surrogate model 
Weight_Matrix=diag(weights./std(Normalized_P,[],2)'); 

% normalize ouptut to be zero mean with unit standard deviation
mean_R=mean(Response,1); 
std_R=std(Response,[],1);
% orig statement
% Normalized_R=(Response-repmat(mean_R,NSupportPoints,1))*diag(1./std_R);
numer=Response-repmat(mean_R,NSupportPoints,1);
S = sparse(1:size(mean_R,2),1:size(mean_R,2),1./std_R);
Normalized_R=numer*S;

% call surrogate model to calculate response
% f=sur_model(x,v_aux,v,yb,n_d,c,k,B,F,mean_F,std_F,ns,index);
% x = P(i,:)';
% zhat(i, :) = sur_model(x,v_aux,v,yb,n_d,c,k,B,F,mean_F,std_F,ns,index);

% zhat is the surrogate response at x
zhat = sur_model(x,v_aux,...
                 Weight_Matrix,...
                 Normalized_P,...
                 N_d,c,k,...
                 BasisFxns,...
                 Normalized_R,...
                 mean_R,std_R,...
                 NSupportPoints,...
                 index);
