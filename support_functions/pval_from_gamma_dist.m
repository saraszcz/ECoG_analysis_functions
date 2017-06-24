function [x_vals, x_vals_all] = pval_from_gamma_dist(surr_matrix)
%   FUNCTION [X_VALS, X_VALS_ALL] = PVAL_FROM_GAMMA_DIST(SURR_MATRIX)
%
%   Takes in a matrix of surrogate values (n frequencies x n frequencies x
%   n surrogates), fits a gamma distribution to each surrogate distribution
%   for each frequency pair, and then calculates the X value that is
%   associated with a particular p-value for each gamma distribution. Then,
%   the largest x value (presumably from the most conservative
%   distribution) is chosen as the significance value.  These significance
%   values will then be used in contourf.m to mark significant isolines in
%   a plot of PLV values. 
%
%   SURR_MATRIX = n frequency x n frequency x n surrogate matrix of PLV
%                 values.
%
%   X_VALS      = chosen x values from the gamma distributions that are equivalent to p values of .1, .05, and .01
%
%   X_VALS_ALL  = all the x values returned from every gamma distribution
%                 (there are a total of n freq x n freq of gamma distributions)
%
%   Written by Sara Szczepanski 6/2012
%
%   Questions:
%
%   1. I will have n phase frequencies x n amp frequencies, which means that
%       there will be n x n total distributions. How to choose a single p value
%       from multiple (~5K) distributions? Most conservative distribution?  
%
%   2. What to shuffle over? Frequency by frequency VS. condition by
%       condition? Each answers different questions: are these two frequencies
%       significantly coupled vs. is this condition different from
%       zero/baseline. Kris prefers frequency x frequency. 
%
%

%n = 500;          % Number of test values
%gamma_shape = 3;  % First gamma parameter for test values
%gamma_scale = 2;  % Second " "

p_vals = [0.5 0.1 0.05 0.01 0.005]; % Desired p-values for plotting
%p_vals = [0.8 0.5 0.2 0.1 0.05]; % Desired p-values for plotting

% The cumulative distribution function is the probability that a value will be found that is less than 'x'.
% So, for example, with a p-value of 0.05 we want to find an 'x' where the probability is 0.95 that a random value from
% the distribution is less than 'x'
inv_p_vals = 1 - p_vals;


%%% Generate a bunch of test values according to a gamma distribution.
%%% These would correspond to the results from your shuffled data
% test_vals = gamrnd(gamma_shape,gamma_scale,[1 numsurrogate]);

gamma_params = nan(size(surr_matrix,1),size(surr_matrix,2),2); %initialize a matrix that has the same number of amp frequencies,
                                                                %the same number of phase frequencies and two parameters for each gamma distribution

x_vals_all = nan(size(surr_matrix,1),size(surr_matrix,2),5); %initialize a matrix that has the same number of amp frequencies & phase frequencies and three
                                                         %values from the gamma distribution for each p value

for a = 1:size(surr_matrix,1) %for each amplitude frequency value in the surrogate matrix
    
    for p = 1:size(surr_matrix,2) %for each phase frequency value in the surrogate matrix
        
        % Fit surrogate PLV values to a gamma distribution- do this for each pair of
        % frequencies (each pair of frequencies has it's own distribution).
        % gamma_params is a two element vector with (1) = gamma_shape' and (2) = gamma_scale'
        gamma_params(a,p,:) = gamfit(surr_matrix(a,p,:)); 
        
        % Calculate the x values that correspond to desired p-values using the inverse CDF
        x_vals_all(a,p,:) = gaminv(inv_p_vals, gamma_params(a,p,1), gamma_params(a,p,2));
        
    end
end


x_vals_1 = x_vals_all(:,:,1); %all x values associated with p value of 0.50
x_vals_2 = x_vals_all(:,:,2); %all x values associated with p value of 0.10
x_vals_3 = x_vals_all(:,:,3); %all x values associated with p value of 0.05
x_vals_4 = x_vals_all(:,:,4); %all x values associated with p value of 0.01
x_vals_5 = x_vals_all(:,:,5); %all x values associated with p value of 0.005


% Choose which distribution to use to calculate p values: Find the distribution with the largest x value (the
% most converative estimate) and use these values as contours in the graph (to mark significance boundaries). 

%NOTE: I think I can do it this way, since the largest x value for p = 0.1
%will come from the same distribution as the largest x value for p = 0.05,
%etc...

max_x_val_1 = max(x_vals_1(:));

max_x_val_2 = max(x_vals_2(:));

max_x_val_3 = max(x_vals_3(:));

max_x_val_4 = max(x_vals_4(:));

max_x_val_5 = max(x_vals_5(:));

x_vals = [max_x_val_1 max_x_val_2 max_x_val_3 max_x_val_4 max_x_val_5]; % x vals = values to use as significance boundaries in contourf.m

% Print results

fprintf('\n');
% fprintf('\tReal parameters: [%2.2f %2.2f]\n', gamma_shape, gamma_scale);
% fprintf('\tEst parameters:  [%2.2f %2.2f]\n', gamma_params(1), gamma_params(2));
% fprintf('\n');

for p_val_n = 1:length(p_vals)
  fprintf('\t\t%2.2f corresponds to p=%1.2f\n', x_vals(p_val_n), p_vals(p_val_n));
end
fprintf('\n');



% Plot everything

% x_min = 0;
% x_max = 25;
% plot_x_vals = linspace(x_min,x_max,1000);
% hist_x_vals = linspace(x_min,x_max,20);
% figure('Position', [200 100 500 800]);
% 
% % Plot distribution of test values
% subplot(2,1,1);
% hist(test_vals, hist_x_vals); %XXX replace test_vals
% xlim([x_min x_max]);
% 
% % Plot estimated gamma distribution
% subplot(2,1,2);
% plot(plot_x_vals, gampdf(plot_x_vals, gamma_params(1), gamma_params(2)), 'k', 'LineWidth', 2); hold on;
% 
% % Plot p value points
% for p_val_n = 1:length(p_vals)
%   plot([x_vals(p_val_n) x_vals(p_val_n)], [0 gampdf(x_vals(p_val_n), gamma_params(1), gamma_params(2))], 'r', 'LineWidth', 3);
%   text(x_vals(p_val_n), gampdf(x_vals(p_val_n), gamma_params(1), gamma_params(2)), ['p=' num2str(p_vals(p_val_n))], 'Color', 'r', 'VerticalAlignment', 'bottom');
% end

end



