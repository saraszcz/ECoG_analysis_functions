function [] = pt_erp(SUBID,meta_ID,e_mat,phase_range,frequency_spacing)

%   function pt_erp(subject,meta_ID,e_mat,phase_range,frequency_spacing)
%
%   SUBJECT     - subject initials ex- 'ST15'
%
%   META_ID     - meta_ID/block number for subject. ex- 'ST15_B1'
%
%   E_MAT       - electrode name. ex- 'e1' or 'e1.mat'
%
%   PHASE_RANGE - 'delta' (1-4 Hz), '1-5_Hz', or 'theta' (4-8 Hz)
%
%   FREQUENCY SPACING - spacing on y axis. 'log' (logrithmic) or 'lin'
%                       (linear)
%
%   Usage: pt_erp('ST15', 'ST15_B1', 'e1', 'delta', 'lin');
%
%   Written by Sara Szczepanski 3/19/12
%

pth_data = ['/home/knight/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/single_elec_data/']; %for running from cluster using ssh or NX
%pth_data = ['/Volumes/HWNI_Cluster/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/single_elec_data/']; %for running from local machine with ECOG partition mounted on desktop.
%pth_data =
%['/Volumes/sszczepa@macfuse.neuro.berkeley.edu/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/single_elec_data/']; %for running on lapop from home

pth_anal = ['/home/knight/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from cluster using ssh or NX
%pth_anal = ['/Volumes/HWNI_Cluster/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from local machine with ECOG partition mounted on desktop.
%pth_anal =['/Volumes/sszczepa@macfuse.neuro.berkeley.edu/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running on lapop from home

cd(pth_data);

load(e_mat); %load up the electrode

e_signal = electrode_signal; %signal saved for each e_mat in a variable called 'electrode_signal'

cd(pth_anal);

load subj_globals; %this contains srate and elecs as variables

if ~exist([pth_anal 'trough_ERPS_SPEC/'],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir([pth_anal 'trough_ERPS_SPEC/']);
end

% if ~exist([pth_anal 'plv_graphs/' cond_string],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
%     mkdir([pth_anal 'plv_graphs/' cond_string]);
% end


%flip signal if data are from Stanford. NOTE: found out that signal comes out
%inverted (flipped on y axis) from amplifiers at Stanford!!!!!
if strcmp(SUBID(1:2),'ST')
    %flip signals on y axis
    disp('INVERTING SIGNAL');
    e_signal = e_signal * -1; %should flip so that troughs are peaks and peaks are troughs. 
end

% Band-pass filter to get a signal that will be used for the phase.
switch phase_range
  case 'delta'
    startpoint = 2;
    endpoint = 5;
  case '1-5_Hz'
    startpoint = 1;
    endpoint = 5;
  case 'theta'
    startpoint = 4;
    endpoint = 8;
end

%filter in low frequency band
lf_signal = eegfilt(e_signal,srate,startpoint,endpoint); 

% Get complex-valued analytic signal (analytic amplitude and phase info)
lf_analytic = hilbert(lf_signal);

% find phases to trigger on:
lf_phase = angle(lf_analytic);
[~,maxima_indices] = find_maxima(lf_phase);

% epoch indices, +/- 1 second
% as is, this assumes all data are at srate of 1000 hz, which is not the
% case. must fix. 
einds = round(-srate:srate);

% drop phase indices that are outside bounds of averaging epoch:
maxima_indices(maxima_indices<=abs(einds(1))) = [];
maxima_indices(maxima_indices>=length(lf_phase)-einds(end)) = [];

% (low freq) phase-triggered ERP of raw signal
pt_erp = zeros(size(einds));

for e = 1:length(maxima_indices)
    pt_erp = pt_erp + e_signal(maxima_indices(e) + einds);
end

pt_erp = pt_erp/length(maxima_indices); %average trough-triggered ERP of filtered raw signal

switch frequency_spacing
  case 'log'
    hf_array = logspace(1,log10(225)); %values for high frequency amplitude data
  case 'lin'
    hf_array = 10:2:224; %values for high frequency amplitude data
end

num_hfs = length(hf_array);

pt_power_matrix = zeros(num_hfs, length(einds));

for i_hf = 1:num_hfs
    hf = hf_array(i_hf);
    hf_signal = eegfilt(e_signal,srate,hf-2,hf+2); %way that Ryan filtered his data in Science 2006 paper
    hf_analytic = abs(hilbert(hf_signal)); %analytic amplitude signal
    hf_analytic = hf_analytic / mean(hf_analytic); % Normalize the signal
    hf_power = hf_analytic.^2; %calculate power

    % (low freq) phase-triggered spectrogram of high frequency amplitude 
    pt_hfa_erp = zeros(size(einds));
    
    for e = 1:length(maxima_indices)
        pt_hfa_erp = pt_hfa_erp + hf_power(maxima_indices(e) + einds);
    end
    pt_hfa_erp = pt_hfa_erp/length(maxima_indices); %average
    
    pt_power_matrix(i_hf, :) = pt_hfa_erp;
end

close all
figure;
h = subplot(2,1,1);
plot(einds,pt_erp);
xlim(einds([1 end]));

h = subplot(2,1,2);
% Note: contourf flips the matrix upside-down, so that the highest
% frequency for amplitude is the top row of the plot (even though
% it's the bottom row of the matrix).
[cv,ch] = contourf(pt_power_matrix); %returns matrix (cv) and handles (ch)

for q = 1:length(ch) %set handles to 0 so that the lines are not plotted. 
    set(ch(q),'LineStyle','none');
end

set(gca, 'XTick', 1:500:2001, 'XTickLabel', -1000:500:1000, ...
         'YTick', 10:10:length(hf_array), 'YTickLabel', hf_array(10:10:end));
elec = e_mat(2:end);
title([int2str(startpoint) '-' int2str(endpoint) [' Hz ' ...
                    'Phase-triggered ERP for Electrode '] elec]);
ylabel('frequency (Hz)');
c = colorbar;
set(get(c, 'ylabel'), 'string', 'normalized power');

print('-dpdf', [pth_anal 'trough_ERPS_SPEC/' 'Trough_Spec_hi_' elec 'v_lo_' elec]);

%print('-dpdf', [pth_anal 'trough_ERPS_SPEC/' phase_range  '/Trough_Spec_hi' elec 'v_lo_' elec]);
            
close all
            
end

            