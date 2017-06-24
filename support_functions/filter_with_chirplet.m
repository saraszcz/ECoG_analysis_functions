function ...
    fs=filter_with_chirplet(varargin)

% function ...
%     fs=filter_with_chirplet(...
%     'signal_structure',s,...
%     'signal_parameters',sp,...
%     'chirplet',g);
% OR
%     fs=filter_with_chirplet(...
%     'raw_signal',raw_signal,...
%     'signal_parameters',sp,...
%     'chirplet',g);
%

% test to see if the cell varargin was passed directly from
% another function; if so, it needs to be 'unwrapped' one layer
if length(varargin)==1 % should have at least 2 elements
    varargin=varargin{1};
end

for n=1:2:length(varargin)-1
    switch lower(varargin{n})
        case 'signal_structure'
            s=varargin{n+1};
        case 'signal_parameters'
            sp=varargin{n+1};
        case 'chirplet'
            g=varargin{n+1};
    end
end

% in case raw, time-domain signal is input rather than signal structure
for n=1:2:length(varargin)-1
    switch lower(varargin{n})
        case 'raw_signal'
            raw_signal=varargin{n+1};
            if size(raw_signal,1)>size(raw_signal,2)
                raw_signal=raw_signal';
            end
    end
end
if exist('raw_signal','var')
    s=make_signal_structure(...
    'raw_signal',raw_signal,...
    'output_type','analytic',...
    'signal_parameters',sp);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%initialize
fs.time_domain=zeros(size(s.time_domain));
fs.frequency_domain=zeros(size(s.frequency_domain));

fs.frequency_domain(g.signal_frequency_support_indices)=...
    s.frequency_domain(g.signal_frequency_support_indices).*...
    g.filter;

fs.time_domain=ifft(fs.frequency_domain,sp.number_points_frequency_domain);
fs.time_domain=fs.time_domain(1:sp.number_points_time_domain);
