function EvaluateModel(hObj,~)
   global  Debug
   if Debug
       fprintf('SSViz++ Function = %s\n',ThisFunctionName)
       hObj;
   end
   
   FigHandle=gcbf;
   Handles=get(FigHandle,'UserData');
    
   P1=get(Handles.ParameterControlsParameter(1),'String');P1=str2double(P1);
   P2=get(Handles.ParameterControlsParameter(2),'String');P2=str2double(P2);
   P3=get(Handles.ParameterControlsParameter(3),'String');P3=str2double(P3);
   P4=get(Handles.ParameterControlsParameter(4),'String');P4=str2double(P4);
   P5=get(Handles.ParameterControlsParameter(5),'String');P5=str2double(P5);
   P6=get(Handles.ParameterControlsParameter(6),'String');P6=str2double(P6);
   
   
   
end