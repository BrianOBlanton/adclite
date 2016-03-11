function h=PlotHurs(H,varargin)
%PlotHurs plot ARA hur tracks
% PlotHurs(H,varargin)
h=NaN*ones(size(H));
for i=1:length(H)
   h(i)=line(H(i).lon,H(i).lat,varargin{:},'Tag',H(i).name,varargin{:});
   %text(H(i).lon,H(i).lat,datestr(H(i).t),varargin{:})
   %text(H(i).lon(end),H(i).lat(end),strrep(H(i).name,'_','\_'))
end


