function f=sur_model(x,v_aux,Weight_Matrix,Normalized_P,N_d,c,k,...
                     BasisFxns,Normalized_R,mean_R,std_R,NSupportPoints,index) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function for evaluation of surrogate model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% f=sur_model(x,v_aux,v,yb,n_d,c,k,B,F,mean_F,std_F,ns,index);
%
% x = parameters at which to compute the surrogate response
% v_aux = "mean of model parameters"
% Weight_Matrix
% Normalized_P
% n_d = number of points to retain in local estimate
% c
% k
% BasisFxns
% Normalized_R
% mean_R
% std_R
% NSupportPoints
% index


% normalize input
Normalized_X=v_aux*x;

% calculate distance, here performed component wise
Parameter_Diffs=repmat(Normalized_X,1,NSupportPoints)-Normalized_P;
Parameter_Diffs_Weighted=Weight_Matrix*Parameter_Diffs;
Distance=sqrt(sum(Parameter_Diffs_Weighted.^2));

% select D so that it includes n_d points
[SortedDistance,SortedDistanceIndex]=sort(Distance); 
D=SortedDistance(N_d);
SelectedStorms=SortedDistanceIndex(1:N_d);


%%% Debug statement!!! 
%disp('Debugging statement in sur_model.m !!')
%SelectedStorms=sort(SelectedStorms);
%%% Debug statement!!! 


% calculate weights, here performed component-wise
aux1=(exp(-(Distance./D/c).^k)-exp(-(1/c)^k))./(1-exp(-(1/c)^k));
W=diag(aux1(SelectedStorms)); 
Ba=BasisFxns(SelectedStorms,:);

% evaluation of basis functions at new point
aux=[];
for j=1:length(index)
    aux=[aux;Normalized_X(index(j))*Normalized_X(index(j:length(index)))];
end
b=[1 Normalized_X' aux'];

% auxiliary matrices
M=Ba'*W*Ba; 
L=Ba'*W; 
% auxM are the b'*inv(M)*L coefficients in eqn 24 of Taflanidis 2012
auxM=b/M*L;
%auxM=b*inv(M)*L;

% [ M ]    = [ Nb x Ns ] * [ Ns x Ns ] * [ Ns x Nb ] = [ Nb x Nb ]
% [ L ]    = [ Nb x Ns ] * [ Ns x Ns ]               = [ Nb x Ns ]
% [ auxM ] = [ 1  x Nb ] / [ Nb x Nb ] * [ Nb x Ns ] = [ 1  x Ns ]
% [ temp ] = [ 1  x Ns ] * [ Ns x Np ]               = [ 1  x Np ] 

% calculate response and convert to initial space
Fi=Normalized_R(SelectedStorms,:);
temp=auxM*Fi;
f=temp.*std_R+mean_R;


% for debugging/understanding
global TAG
if ~isempty(TAG)
    save([TAG '.mat'])
end

% % implement robust inversion
% rd=1;
% dM=eye(size(M,1))*(10+size(M,1))*eps;
% while rd
%     M=M+dM;
%     [C rd]=chol(M);
% end
% auxM=(b/C)/C'*L;