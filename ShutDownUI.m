%%  ShutDownUI
%%% ShutDownUI
%%% ShutDownUI
function ShutDownUI(~,~)

    global Debug
    if Debug,fprintf('AdcL++  Function = %s\n',ThisFunctionName);end
    
    fprintf('\nAdcL++ Shutting Down AdcircLite GUI.\n');
   
    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    
    delete(Handles.MainFigure)
    
%     if isfield(Handles,'Timer')
%         if isvalid(Handles.Timer)
%             stop(Handles.Timer);
%             delete(Handles.Timer);
%         end
%     end

%     parent=get(get(Handles.MainAxes,'Parent'),'Parent');
%     delete(parent)
        
%     TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');       
%     if exist([TempDataLocation '/run.properties'],'file')
%         delete([TempDataLocation '/run.properties'])
%     end
%     if exist([TempDataLocation '/fort.22'],'file')
%         delete([TempDataLocation '/fort.22'])
%     end
%     if exist([TempDataLocation '/cat.tree'],'file')
%         delete([TempDataLocation '/cat.tree'])
%     end    
    
%     delete(FigThatCalledThisFxn)
    
    %delete(findobj(0,'Tag','HydrographFigure'))

end

