function [chunked_low chunked_high] = get_session_data(lf_phase, hf_phase, ...
                                                        cond_string, start_window,...
                                                        end_window)

%cd(['~/data/' subject '/gdat_CAR_by_elec/'])
%load(e_mat)                            % Loads electrode_signal.

%cd('..');

load(cond_string)

condition = eval(cond_string);%
%condition = stim_long_only; %for long_trials analysis

% Find time points to keep.
keepers = [];
for i=1:length(condition)
    event_start = round(condition(i)); % Make the time an integer.
    keepers = [keepers event_start+start_window:event_start+end_window];
end
% Make sure there are no repeated time points in keepers (due
% to overlaps of windows with preceding or succeeding trials).
keepers = unique(keepers);
% Make sure there are no indices in keepers beyond the length
% of signal.
while keepers(end) > length(lf_phase)
    keepers(end) = [];
end

chunked_low  = lf_phase(:, keepers);

if ~isempty(hf_phase) %in case get_session_data is only analyzing lf_phase
    chunked_high = hf_phase(:, keepers);
elseif isempty(hf_phase)
    chunked_high = [];
else
    error('chunked_high must either be [] or must exist!')
end

end

