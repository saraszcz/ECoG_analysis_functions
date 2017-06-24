
function sp=get_signal_parameters(varargin)

% function ...
%     sp=get_signal_parameters(...
%               'sampling_rate',sampling_rate,...
%               'number_points_time_domain',number_points_time_domain,...
%               'time_at_first_point',time_at_first_point);
%
% inputs -- (can be entered in any order as key/value pairs)
%   sampling_rate: sampling rate of recording (Hz)
%   number_points_time_domain: number of sample points in signal (integer)
%
%   time_at_first_point: (optional) value of time at first sample point (seconds, defaults to 0)
%   time_at_center_point: (optional) value of time at
%       floor(number_points_time_domain/2) sample point (seconds, defaults to 0)
%
% outputs --
%   sp: structure of useful parameters which hold for all channels recorded during a particular session (block)
%       example:
% sp =
%                      sampling_rate: 2003  % Hz, from input
%          number_points_time_domain: 736391  % integer, from input
%     number_points_frequency_domain: 1048576  % next power of 2 up from sp.number_points_time_domain
%                frequency_step_size: 0.0019102  % Hz, interval between adjacent DFT frequencies
%                     time_step_size: 0.00049925  % seconds, interval between adjacent time-domain samples
%                       time_support: [1x736391 double] value of time at each sample point
%                  frequency_support: [1x1048576 double] value of frequency at each frequency-domain point
%
%
% E.G.,
% sampling_rate=2003;
% number_points_time_domain=length(signal);
% sp=get_signal_parameters(...
%     'sampling_rate',sampling_rate,...
%     'number_points_time_domain',number_points_time_domain);
%
% sp=get_signal_parameters('sampling_rate',1000,'number_points_time_domain',size(lfp,2));



% test to see if the cell varargin was passed directly from
% another function; if so, it needs to be 'unwrapped' one layer
if length(varargin)==1 % should have at least 2 elements
    varargin=varargin{1};
end

for n=1:2:length(varargin)-1
    switch lower(varargin{n})
        case 'sampling_rate'
            sp.sampling_rate=varargin{n+1};
        case 'number_points_time_domain'
            sp.number_points_time_domain=varargin{n+1};
    end
end

maxpower2=2^23; % to avoid out-of-memeory issues;
% check this on your machine, machine-specific threshold
if sp.number_points_time_domain<maxpower2
    sp.number_points_frequency_domain=2^ceil(log2(sp.number_points_time_domain)); % fixed parameter for computational ease
else
    sp.number_points_frequency_domain=sp.number_points_time_domain;
end
sp.time_step_size=1/sp.sampling_rate; % determined
sp.frequency_step_size=sp.sampling_rate/sp.number_points_frequency_domain; % determined

% raw time_support, need to shift if
% time_at_first_point or time_at_center_point provided by user
sp.time_support=sp.time_step_size*...
    (0:sp.number_points_time_domain-1);

for n=1:2:length(varargin)-1
    switch lower(varargin{n})
        case 'time_at_first_point'
            time_at_first_point=varargin{n+1};
            sp.time_support=sp.time_support+time_at_first_point;
        case 'time_at_center_point'
            % desired_time_at_center_point
            dct=varargin{n+1};
            % current_time_at_center_point
            cct=sp.time_support(floor(sp.number_points_time_domain/2));
            sp.time_support=sp.time_support-(cct-dct);
    end
end

sp.frequency_support=sp.frequency_step_size*...
    (0:sp.number_points_frequency_domain-1); % determined
inds=sp.frequency_support>(sp.sampling_rate/2);
sp.frequency_support(inds)=...
    sp.frequency_support(inds)-sp.sampling_rate;

sp.time_support=single(sp.time_support);
sp.frequency_support=single(sp.frequency_support);
