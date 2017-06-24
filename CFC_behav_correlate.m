function [] = CFC_behav_correlate(SUBID, meta_ID, cond_string, stim_string, RT_string, e_mat, ...
    start_window, end_window, phase_freq, amp_freq)

pth_data = ['/home/knight/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/single_elec_data/']; %for running from cluster using ssh or NX
%pth_data = ['/Volumes/HWNI_Cluster/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/single_elec_data/']; %for running from local machine with ECOG partition mounted on desktop.
%pth_data = ['/Volumes/sszczepa@macfuse.neuro.berkeley.edu/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/single_elec_data/']; %for running on lapop from home

pth_anal = ['/home/knight/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from cluster using ssh or NX
%pth_anal = ['/Volumes/HWNI_Cluster/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from local machine with ECOG partition mounted on desktop.
%pth_anal =['/Volumes/sszczepa@macfuse.neuro.berkeley.edu/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running on lapop from home

cd(pth_data);

load (e_mat); %load up the electrode

e_signal = electrode_signal; %signal saved for each e_mat in a variable called 'electrode_signal'

cd(pth_anal);

load subj_globals; %this contains srate and elecs as variables

if ~exist([pth_anal 'CFC_behav_corr_new/'],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir([pth_anal 'CFC_behav_corr_new/']);
end

if ~exist([pth_anal 'CFC_behav_corr_new/' cond_string],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir([pth_anal 'CFC_behav_corr_new/' cond_string]);
end

% get_signal_parameters, which returns the structure 'sp':
sp = get_signal_parameters('sampling_rate',srate,... % Hz
    'number_points_time_domain',length(e_signal));

% phase data parameters:
g.center_frequency = phase_freq;
g.fractional_bandwidth = 0.25;
g.chirp_rate = 0;
g1 = make_chirplet('chirplet_structure', g, 'signal_parameters', sp);

% filter raw signal at low frequency, extract phase:
fs = filter_with_chirplet('raw_signal', e_signal, ...
    'signal_parameters', sp, ...
    'chirplet', g1);
lf_phase = angle(fs.time_domain);
clear g.center_frequency

% amp data parameters:
g.center_frequency = amp_freq;
g2 = make_chirplet('chirplet_structure', g, 'signal_parameters', sp);

% filter raw signal at high frequency, extract amplitude:
fs = filter_with_chirplet('raw_signal', e_signal, ...
    'signal_parameters', sp, ...
    'chirplet', g2);

hf_amp = abs(fs.time_domain);
% filter high frequency amplitude time-series at low
% frequency, extract phase:
fs = filter_with_chirplet('raw_signal', hf_amp, ...
    'signal_parameters', sp, ...
    'chirplet', g1);%filter at low frequency
hf_phase = angle(fs.time_domain); %extract phase of high frequency amplitude


% chunk out data for a particular condition AFTER*** filtering
% returns an trials x timepoints matrix for the phase data and for the
% amplitude data
[chunked_low_phase chunked_high_phase] = divide_cond_by_trial(lf_phase, hf_phase, ...
    cond_string, start_window, end_window);

% calculate the plv value for each trial
plv = abs(mean(exp(1i*(chunked_high_phase - chunked_low_phase)),2)); %should be left with a single PLV value for each trial. plv = 1 x trial (column vector)

%load in the RT data and calculate RT
load(stim_string); %i.e., 'onsets_stim_attend_contra_hit_g'
stim_condition = eval(stim_string);

load(RT_string);   %i.e., 'onsets_RTs_attend_contra_hit_g'
RT_condition = eval(RT_string);

RT = RT_condition - stim_condition; % RTs for each trial in msec (column vector)
%NOTE: you should have the same number of RTs as plv values.


if ~isempty(find(RT >= 1000))
    outliers = find(RT >= 1000); %find index values that are outliers
    RT(outliers) = nan; %set outliers to nan (so that they are not plotted)
    plv(outliers) = nan; %set outliers to nan
    
    RT  = RT(~isnan(RT)); %collapse across the nan values in the vector
    plv = plv(~isnan(plv));
   

end


%remove trials with CFC/PLV magnitude values above a particular threshold
if ~isempty(find(plv >= 0.95))
    outliers = find(plv >= 0.95); %find index values that are outliers
    RT(outliers) = nan; %set outliers to nan (so that they are not plotted)
    plv(outliers) = nan; %set outliers to nan
    
    RT  = RT(~isnan(RT)); %collapse across the nan values in the vector
    plv = plv(~isnan(plv));
    
end


if ~isequal(size(RT),size(plv));
    error('You must have the same number of RTs and PLV values!!')
end


% correlate the RT and PLV values
% below is from Matar's code
figure

%if nploty>1
%    set(gcf,'Position', [1000 170 630 1150])
%else set(gcf,'Position', [500   500   550   450])
%end
elec = e_mat(2:end); %elec = string

%set(gcf,'Position', [500   500   550   450])

%for j = 1:size(data,2) % for each electrode
    %wind = [siglist.(elec){j,1} '-' siglist.(elec){j,2}];
    
    rsq  = regstats(RT, plv,'linear', 'rsquare'); %computes R squared
    correlation = corr2(RT, plv); %computes correlation between RTs and data
    [correlation2,pval] = corrcoef(RT, plv); %to calculate p value of correlation
    
    pval = pval(1,2);
    
    %stats.(elec).tm{j} = wind;
    %stats.(elec).rsquared{j} = rsq.rsquare;
    
    
    %bot = bottom + (j - 1)*(h + gapy); % defines each y origin.
    %axes('Position',[left bot width h]) % positions the axis
    
    p    = polyfit(RT, plv, 1);
    lin1 = polyval(p, RT); 
    scatter(RT, plv, 250, '.') %draw a scatter plot. can also specify color here.
    hold on;
    plot(RT, lin1, 'r') %plot the regression line?
    %         title(sprintf('%s    r^2 = %2.2f',wind ,rsq.rsquare))
    title(['Electrode ' elec ' PLV vs. Reaction Time']);
  
    xlabel('RT (ms)')
    ylabel('PLV')
    
%end

set(gcf, 'PaperPositionMode','auto')
print('-dpdf',[pth_anal 'CFC_behav_corr_new/' cond_string '/PLV_' elec '_RT_correlation']);
save([pth_anal 'CFC_behav_corr_new/' cond_string '/PLV_' elec '_RT_corr_vals'], 'rsq', 'correlation', 'pval');

close





