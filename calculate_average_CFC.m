function [] = calculate_average_CFC(SUBID, meta_ID, cond_string, start_window, end_window, phase_freq, amp_freq)

%function [] = calculate_average_CFC(SUBID, meta_ID, cond_string, start_window, end_window, phase_freq, amp_freq)
%
%
%     SUBID             - Subject's initials (ex- 'ST15'). taken in as a
%                         string
%
%     meta_ID           - meta_ID for subject (corresponds to block name.
%                         ex- 'ST15_B2'. Taken in as a string.
%
%     cond_string       - name of condition to load. taken in as a string.
%                         ex- 'attend_contra_hit_g'
%
%     start_window      - start of window in ms relative to event start
%
%     end_window        - end of window in ms relative to event end
%
%     phase_freq        - frequency to filter phase data
%
%     amp_freq          - frequency to filter amplitude data
%
%     Written by SMS 3/25/14
%


pth_data = ['/home/knight/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from cluster using ssh or NX
%pth_data = ['/Volumes/HWNI_Cluster/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from local machine with ECOG partition mounted on desktop.
%pth_data = ['/Volumes/sszczepa@macfuse.neuro.berkeley.edu/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running on lapop from home

cd(pth_data);

load subj_globals;

load gdat_CAR;

AVG_CFC_allelecs = [];

for e = 1:length(elecs) %for each electrode
    
    e_signal = gdat_car(elecs(e),:);
    
    %filtering
    
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
    
    
    %chunk out data for a particular condition AFTER*** filtering
    [chunked_low_phase chunked_high_phase] = get_session_data(lf_phase, hf_phase, ...
        cond_string, start_window, end_window);
    
    
    % calculate a single plv value across all trials for each electrode.
    plv = abs(mean(exp(1i*(chunked_high_phase - chunked_low_phase)))); %calculate a single PLV across trials for a single electrode
    
    AVG_CFC_allelecs  = [AVG_CFC_allelecs; elecs(e) plv];
    
end %end for


save('AVG_CFC_allelecs_ATT_Trial_Begin','AVG_CFC_allelecs');
