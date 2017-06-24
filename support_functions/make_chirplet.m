function g = make_chirplet(varargin)
% function g=make_chirplet('chirplet_structure',g,'signal_parameters',sp);
%
% calls --
%   complete_chirplet_parameters.m
%
% inputs --
%     signal_parameters  : output from get_signal_parameters.m
%     chirplet_structure : structure g (usually incomplete with only
%                          minimal number of fields) 
%
% outputs --
%     g                  : structure with fields
%
% E.G.
% sp=get_signal_parameters('sampling_rate', 1000, ...
%                          'number_points_time_domain', 2^21);
% clear g
% g.center_frequency=30; % Hz
% g.fractional_bandwidth=0.15;
% g.chirp_rate=0;
% g=make_chirplet('chirplet_structure',g,'signal_parameters',sp);

% test to see if the cell varargin was passed directly from
% another function; if so, it needs to be 'unwrapped' one layer
if length(varargin)==1 % should have at least 2 elements
    varargin=varargin{1};
end

% see if partial chirplet structure has been given as input:
for n=1:2:length(varargin)-1
    switch lower(varargin{n})
        case 'signal_parameters'
            sp=varargin{n+1};
        case 'chirplet_structure'
            g=varargin{n+1};
    end
end

% fill in rest of values
g=complete_chirplet_parameters(g);

% use short variable names for equations
t0=g.center_time;
v0=g.center_frequency;
s0=g.duration_parameter; %this is realted to fractional bandwidth
c0=g.chirp_rate;
tstd=g.time_domain_standard_deviation;
vstd=g.frequency_domain_standard_deviation;

% time support:
% shift g.center_time to fall on sp.time_support
if (g.center_time<sp.time_support(1))||... % before signal
        (g.center_time>sp.time_support(end)) % after signal
    g.center_time=mod(g.center_time,sp.time_support(end));
end
temp1=abs(sp.time_support-g.center_time);
[trash,center_index]=min(temp1); % sp.time_support index closest to g.center_time

numinds=length(0:...
    sp.time_step_size:...
    tstd*g.std_multiple_for_support);
support_inds=center_index+(-numinds:numinds);
support_inds=mod(support_inds,sp.number_points_time_domain);
support_inds(support_inds==0)=sp.number_points_time_domain;
g.signal_time_support_indices=support_inds;

g.time_support=sp.time_support(g.signal_time_support_indices);
t=sp.time_support(center_index)+...
    sp.time_step_size*(-numinds:numinds);
g.ptime=t;

% chirplet in time domain:
g.time_domain=2^(1/4)*exp(-s0/4)*... % normalizer for R (not Z)
        exp(-exp(-s0)*pi*(t-t0).^2).*... % amplitude envelope
        exp(2*pi*1i*v0*(t-t0)).*... % frequency modulation
        exp(pi*1i*c0*(t-t0).^2);    % linear frequency chirp
g.time_domain=g.time_domain/norm(g.time_domain); % need to normalize due to discrete sampling

% frequency support
v=sp.frequency_support; % in Hz
g.signal_frequency_support_indices=find(...
    (v0-g.std_multiple_for_support*vstd<=v)&...
    (v<=v0+g.std_multiple_for_support*vstd));

% shorten to include only chirplet support
v=v(g.signal_frequency_support_indices);
g.frequency_support=v;
g.pfrequency=g.frequency_support;

% chirplet in frequency domain: 
Gk=2^(1/4)*sqrt(-1i*c0+exp(-s0))^-1*...
    exp(-s0/4+...
    (exp(s0)*pi*(v-v0).^2)/(-1+1i*c0*exp(s0)));
n1=sqrt(sp.number_points_frequency_domain)/norm(Gk);
Gk=n1*Gk; % because of discrete sampling and different time/freq sample numbers
g.filter=Gk; % at center time of zero, use this for convolution filtering
g.frequency_domain=Gk.*exp(-2*pi*1i*v*t0); % translation in time to tk
