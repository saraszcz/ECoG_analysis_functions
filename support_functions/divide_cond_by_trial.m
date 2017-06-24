function [chunked_low chunked_high] = divide_cond_by_trial(lf_phase, hf_phase, ...
    cond_string, start_window, end_window)

%cd(['~/data/' subject '/gdat_CAR_by_elec/'])
%load(e_mat)                            % Loads electrode_signal.

%cd('..');

load(cond_string)
condition = eval(cond_string);
chunked_low = [];
chunked_high = [];

%tm_st  = round(start_window./1000*srate); %time of trial start start
%tm_end  = round(end_window./1000*srate); %time of trial end

for i = 1:length(condition)
    event_start = round(condition(i)); % Make the time an integer.
    chunked_low  = [chunked_low ; lf_phase(event_start + start_window: event_start + end_window -1)]; %creates a n trials x n timepoints matrix
    chunked_high = [chunked_high; hf_phase(event_start + start_window: event_start + end_window -1)]; %creates a n trials x n timepoints matrix
end
   



