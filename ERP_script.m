function ERP_script(SUBID,meta_ID,cond1,bl_cond1,cond2,bl_cond2,Atitle,Btitle,bank,power,f1,f2, with_stderr)

% function ERP_script(SUBID,meta_ID,cond1,bl_cond1,cond2,bl_cond2,Atitle,Btitle,bank,power,f1,f2, with_stderr)
%
%       Plots the mean power (for a predefined frequency range), or the mean raw ERP, averaged across trials for a
%       particular electrode for two predefined conditions. Allows normalization to a baseline condition that is separate from the two
%       conditions are are plotted.  (i.e., if you want to normalize to the
%       beginning of a trial but are plotting only the stimulus
%       presentation window).
%
%       SUBID            - subject ID, i.e.,'JH21'. taken in as string.
%
%       meta_ID         - meta ID for block (e.g., 'JH21_B1'). taken in as string
%
%       cond1           - the condition of interest, taken in as a string. ex - 'onsets_stim_attend_g'
%
%       bl_cond1        - baseline for condition 1. this is the condition that you want your baseline to be taken from,
%                         taken in as string. ex - 'onsets_trial_begin_attend_g'
%
%       cond2           - the condition that you want to compare it to, taken in as a string. ex - 'onsets_stim_unattend_g'
%
%       bl_cond2        - baseline for condition 2. this is the condition that you want your baseline to be taken from,
%                         taken in as string. ex - 'onsets_trial_begin_unattend_g'
%
%       Atitle           - name of condition 1 (e.g., 'Trial Begin Attend'). taken in as string. do not use underscores
%                         (program does not print them correctly).
%
%       Btitle           - name of condition 2 (e.g., 'Trial Begin Unattend'). taken in as string. do not use underscores
%                         (program does not print them correctly).
%
%       bank            - how the electrodes were collected (in full grid vs. in banks, etc).
%                         0 for gdat_car, 1 for gdat_car_bank, 2 for gdat_car_grid, 3 for gdat_bipolar
%
%       power           - 0 for raw ERP trace, 1 for power envelope of chosen frequency. default is to plot power envelope (analytic amplitude)
%
%       f1              - lowest frequency of interest
%
%       f2              - highest frequency of interest
%
%       Usage: ERP_script('JH21', 'JH21_B1', 'onsets_trial_begin_attend_g', 'onsets_trial_begin_attend_g', 'onsets_trial_begin_unattend_g', 'onsets_trial_begin_unattend_g', ...
%                           'Trial Begin Attend', 'Trial Begin Unattend', 0, 1, 80, 200)
%
%       Modified by Sara Szczepanski 6/29/11
%

pth_data = ['/home/knight/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from cluster using ssh or NX
%pth_data = ['/Volumes/HWNI_Cluster/sszczepa/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running from local machine with ECOG partition mounted on desktop.
%pth_data = ['/Volumes/sszczepa@macfuse.neuro.berkeley.edu/Desktop/ECOG_data_Starry/' SUBID '/analysis/' meta_ID '/']; %for running on lapop from home

cd(pth_data);

load subj_globals;


%LOAD DATA
if bank==0
    load gdat_CAR;
    bandx = gdat_car;
    clear gdat_car;
    
elseif bank ==1
    load gdat_CAR_bank;
    bandx = gdat_car_bank;
    clear gdat_car_bank;
    
elseif bank==2
    load gdat_CAR_grid;
    bandx = gdat_car_grid;
    clear gdat_car_grid;
    
elseif bank==3
    load gdat_bipolar;
    bandx = gdat_bipolar;
    clear gdat_bipolar;
end


%Power envelope or ERP.
if power == 1 %plot power envelope
    
    if f1 >= 70
        FilePrefix = 'Mean_Power_High_Gamma_e';
    elseif f1 >= 30 && (f2 <= 70)
        FilePrefix = 'Mean_Power_Low_Gamma_e';
    elseif (f1 >= 13) && (f2 <= 30)
        FilePrefix = 'Mean_Power_Beta_e';
    elseif (f1 >= 8) && (f2 <= 13)
        FilePrefix ='Mean_Power_Alpha_e';
    elseif (f1 >= 4) && (f2 <= 8)
        FilePrefix = 'Mean_Power_Theta_e';
    elseif (f1 >= 1) && (f2 <= 4)
        FilePrefix = 'Mean_Power_Delta_e';
    else
        error('Your frequency is not in the correct range')
    end
    
    
elseif power == 0 %plot ERPs
    
    FilePrefix = 'Mean_ERP_e';
end


if ~exist([pth_data 'ERPs/'],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir([pth_data 'ERPs/']);
end


if cond1(8:12) == 'trial' %if the data are time-locked to beginning of trials
    
    start_time_window = -200; %ms
    end_time_window   = 2000; %ms
    
elseif cond1(8:12) == 'stim_' %if the data are time-locked to beginning of stimulus
    
    start_time_window = -200; %ms
    end_time_window   = 600; %ms
    
    
    %start_time_window = -1200; %ms %to look back in time before stimulus onset
    %end_time_window   = 0; %ms %onset of stimulus
    
else
    error('Your condition must either be time-locked to a trial or a stimulus');
    
end

bl_st =  round(start_time_window ./1000*srate);
%bl_st =  round((end_time_window -199) ./1000*srate);

bl_en =  round(0 ./1000*srate);
%bl_en =  round((start_time_window + 199) ./1000*srate);
%bl_en =  round(end_time_window ./1000*srate);

tm_st  = round(start_time_window ./1000*srate);
tm_en  = round(end_time_window ./1000*srate);


plot_jump = 200; % time bins, ms
jm = round(plot_jump./1000*srate);

load(cond1);
onsets_cond1 = round(eval(cond1)); %first event to plot: trial begin. why rounding??
load(cond2);
onsets_cond2 = round(eval(cond2)); %second event to plot: stimulus appearance. why rounding??

load(bl_cond1);
onsets_blcond1 = round(eval(bl_cond1)); %first event to plot: trial begin. why rounding??
load(bl_cond2);
onsets_blcond2 = round(eval(bl_cond2)); %second event to plot: stimulus appearance. why rounding??


% load([ANdir dlm Aa]);
% eval(['onsets_cond1a =round(' Aa ');']);
% load([ANdir dlm Bb]);
% eval(['onsets_cond2b =round(' Bb ');']);


for elec = elecs %for each electrode
    
    clear band;
    band = bandx(elec,:); %get the data from one electrode
    
    
    %flip signal if data are from Stanford. NOTE: found out that signal comes out
    %inverted (flipped on y axis) from amplifiers at Stanford!!!!!
    if strcmp(meta_ID(1:4),'ST15') || strcmp(meta_ID(1:4),'ST18') || strcmp(meta_ID(1:4),'ST19') || strcmp(meta_ID(1:4),'ST23')
        %flip signals on y axis
        disp(['INVERTING SIGNAL ' SUBID]);
        band = band * -1; %should flip so that troughs are peaks and peaks are troughs.
    end
    
    
    if (power) % if you want to plot power (power = 1)
        band = abs(my_hilbert(band,srate,f1,f2)).^2; %take the analytical amplitude
        band = band_pass(band,srate,0.1,8);
    else       % plot the raw ERP
        band =  band_pass(band,srate,0.1,8);
    end
    
    %condition 1
    for i = 1:length(onsets_cond1)
        tm_stmps  = (onsets_cond1(i)+tm_st):(onsets_cond1(i)+tm_en);
        bl_stmps  = (onsets_blcond1(i)+bl_st):(onsets_blcond1(i)+bl_en); %this is if you want to use a baseline from a different condition
        ERP_cond1(i,:) = (band(tm_stmps) - mean(band(bl_stmps))); %normalizing to its baseline
        %save('ERP_cond1','ERP_cond1');
    end
    
    %condition 2
    for i = 1:length(onsets_cond2)
        tm_stmps  = (onsets_cond2(i)+tm_st):(onsets_cond2(i)+tm_en);
        bl_stmps2  = (onsets_blcond2(i)+bl_st):(onsets_blcond2(i)+bl_en); %this is if you want to use a baseline from a different condition
        ERP_cond2(i,:) = (band(tm_stmps) - mean(band(bl_stmps2))); %normalizing to its baseline
        %save('ERP_cond2','ERP_cond2');
    end
    
    
    %calculate standard error across trials
    stderrs_cond1 = std(ERP_cond1 ,1)/(sqrt(size(ERP_cond1,1)));
    stderrs_cond2 = std(ERP_cond2 ,1)/(sqrt(size(ERP_cond2,1)));
    
    
    fgrid=figure;
    
    %title(elec);
    
    if with_stderr
        %shade_plot(x_points,y,dy,facecolor,transparency,plot_y)
        shade_plot(tm_st:tm_en,mean(ERP_cond1),stderrs_cond1,'b',0.3,1);
    else
        plot(tm_st:tm_en,mean(ERP_cond1),'LineWidth',3); %plot condition 1 
    end
    
    %remove title for ERP paper figure:
%     if (power) %if you are plotting the analytic amplitude
%  
%         title(sprintf('%s, %d, Power %d->%d uV^2, %s blue %s red',SUBID,elec,f1,f2,Atitle,Btitle));
%     else %if you are plotting the ERP
%         title(sprintf('%s, %d, ERP, %s blue %s red',SUBID,elec,Atitle,Btitle));
%     end
    
    %remove labels for ERP paper figure:
    %xlabel('ms');
    %ylabel('uV');
    hold on;
    
    if with_stderr
        %shade_plot(x_points,y,dy,facecolor,transparency,plot_y)
        shade_plot(tm_st:tm_en,mean(ERP_cond2),stderrs_cond2,'r',0.3,1);
    else
        plot(tm_st:tm_en,mean(ERP_cond2),'r','LineWidth',3); %plot condition 2
    end
    
    
    for z = 1:length([tm_st:jm:tm_en])
        plot_str{z} = start_time_window+(z-1)*plot_jump;
    end
    
    set(gca,'XTick',[tm_st:jm:tm_en],'XTickLabel',plot_str,'XTickMode', 'manual','Layer','top');
    xlim([tm_st tm_en]);
    ylim([-35 40]);
    
    set(fgrid,'PaperPositionMode','auto');
    
    if with_stderr
        print(fgrid,'-djpeg',[pth_data 'ERPs/' SUBID '_' FilePrefix num2str(elec) '_' Atitle '_' Btitle '_stderr.jpg']);
    else
        print(fgrid,'-djpeg',[pth_data 'ERPs/' SUBID '_' FilePrefix num2str(elec) '_' Atitle '_' Btitle '.jpg']);
        %print(fgrid,'-djpeg',[pth_data 'ERPs/' SUBID '_' FilePrefix num2str(elec) '_' Atitle '_' Btitle '_before_stim.jpg']);
    end
    
    close(fgrid);
    
    % p=input(['Next']);
end


end

