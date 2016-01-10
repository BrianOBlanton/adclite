function MouseReleasedCallback(h,e)
%disp(get(h,'Value'));
fprintf('%5.2f\n',h.getDoubleValue);
h.setToolTipText(num2str(h.getDoubleValue));
