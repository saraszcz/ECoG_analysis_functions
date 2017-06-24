function [h] = shade_plot(x_points,y,dy,facecolor,transparency,plot_y)
%
%   shade_plot(x_points,y,dy,color,transparency)
%
%       plots a shaded area beteween y_low and y_high across x_points
%       using the color and transparency values (default 'b', 0.6)
%       
%       x_points     - vector of time points (corresponding to x axis). 
%       
%       y            - vector of voltage (or amplitude or power) values over time
%
%       dy           - change +/- in shaded region. This corresponds to a
%                      vector of STDEV and STDERR values for each time point. 
%
%       facecolor    - color of shaded region.
%
%       transparency - how transparent you want shaded region to be. 1 =
%                      opaque. 0 = conpletely transparent. 
%     
%       plot_y       - 1 = yes. 0 = no. 
%



    if ~exist('facecolor'), facecolor = 'b'; end
    if ~exist('transparency'), transparency = 0.6; end
    if ~exist('plot_y'), plot_y = 0; end
    if plot_y
        h=plot(x_points,y,'color','k','LineWidth',2,'linesmoothing','on'); hold on;
    end
    x_points = [x_points fliplr(x_points)];
    y_points = [y-dy fliplr(y+dy)]; %set lower bounnd and upper bound for shaded region. 
    h=fill(x_points,y_points,facecolor);
    set(h,'EdgeColor',facecolor,'FaceAlpha',transparency,'EdgeAlpha',transparency);%set edge color
    %if plot_y
    %    hold off;
    %end

end
