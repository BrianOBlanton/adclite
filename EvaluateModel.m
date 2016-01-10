%%  EvaluateModel
%%% EvaluateModel
%%% EvaluateModel
function EvaluateModel(varargin)

   global  Debug Model  ADCLOPTS TheGrid
   
   if nargin==1  % called as function
       FigHandle=varargin{1};
   else  % called as callback
       %hObj=varargin{1};
       %event=varargin{2};
       FigHandle=gcbf;
   end
       
   if Debug
       fprintf('AdcL++ Function = %s\n',ThisFunctionName)
       %hObj;
   end
   
   Handles=get(FigHandle,'UserData');
    
   P=getRsmParameters(Handles);
   
    Lon_South_Offset = Model.CrossingLines.LatitudeInterceptionParallel1.lon(1);
    %Lat_South_Offset = Model.CrossingLines.LatitudeInterceptionParallel1.lat(1);
    Lon_North_Offset = Model.CrossingLines.LatitudeInterceptionParallel4.lon(1);
    %Lat_North_Offset = Model.CrossingLines.LatitudeInterceptionParallel4.lat(1);
    
   % remove longitude 
   P(5)=P(5)-Lon_South_Offset;
   P(6)=P(6)-Lon_North_Offset;
  
   zhat = central_ckv(Model.P, Model.R, Model.c, Model.k, Model.weights, Model.n_d, Model.index, P');
   
   ThisData=NaN*ones(TheGrid.nn,1);
   ThisData(TheGrid.idx)=zhat;
   Handles=DrawTriSurf(Handles,1,ADCLOPTS.Units,ThisData);
   
   fc=get(Handles.FixCMap,'Value');
   if ~fc
       SetColors(Handles,min(ThisData),max(ThisData),ADCLOPTS.NumberOfColors,ADCLOPTS.ColorIncrement);
   end
   
   set(FigHandle,'UserData',Handles);
    
   UpdateUI(FigHandle);
   
end
