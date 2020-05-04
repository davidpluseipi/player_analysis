%% Player Analysis
% Purpose: Take player data and provide analysis to players and staff

%% Start clean

% Clear all variables in the base workspace
clear

% Close all figure windows that may be open
close all;

% Clear the command window (another open is using 'home')
clc

%% Inputs
timer = true; % if true, times the entire analysis
progress = true; % if true, displays a progress bar / dialog box
visualize = true; % if true, displays plots / graphs
record = true; % if true, saves imported data, results and figure(s)

%% Setup
% Start a timer
if timer
    tic
end

if progress
    % Start a dialog box / progress bar to track progress throughout
    f = uifigure;
    d = uiprogressdlg(f, 'Title', 'Please Wait', 'Message', 'Starting...');
end

% References for this section:
% web(fullfile(docroot, 'matlab/ref/uiprogressdlg.html'))

%% Import Data


% This imports one file for analysis, but it is possible to automate the
% analysis of multiple files.

% Specify the file to import data from
filename = 'C:\Users\david\googledrive\MATLAB\soccer\match_data1.csv';

% Specify what rows to import
row_start = 2;
row_end = row_start + 10000;

if progress
    % Update the progress bar
    d.Value = 0.1;
    d.Message = 'Importing data';
    pause(.1)
end

% Call the function importfile() (auto-generated by the import tool)
data = importfile(filename, [row_start, row_end]);
data.ay = -1 * data.ay; % correction so y is positive up, like axes.png

% Variables in the table, 'data':
% (units and datatype are included, if possible)
%
% data.id = player id, double
% data.name = player name, categorical
% data.session = session id, double
% data.t = time (HH:mm:ss.SS), datetime (was originally string)
% data.t_elapsed = elapsed time, double
% data.speed = speed (m/s), double
% data.a_impulse = instantaneous acceleration impulse, double
% data.hr_interval = heart rate interval, double
% data.lat = latitude, double
% data.lon = longitude, double
% data.ax = acceleration in the +x direction (see axes.png)
% data.ay = acceleration in the +y direction (see axes.png)
% data.az = acceleration in the +z direction (see axes.png)
% data.gx = gyro x
% data.gy = gyro y
% data.gz = gyro z
% data.h_acc =
% data.h_dop =
% data.signal_quality = gps signal quality?
% data.num_sat = number of satellites
%
% References for this section:
% web(fullfile(docroot, 'matlab/import_export/select-spreadsheet-data-interactively.html'))

%% Data Management

if progress
    % Update the progress bar
    d.Value = 0.2;
    d.Message = 'Formating data';
    pause(.1)
end

% Convert the time data from a 'string array' to 'datatime' data type
data.t = datetime(data.t, 'InputFormat', 'HH:mm:ss.SS', 'Format', 'HH:mm:ss.SS');

%% Calculate vertical velocity

% Setup
s = row_end - row_start; % this will be the number of times through the loop
r = 100; % number of rows processed between updates to the progress bar

% Preallocating memory for the following loop
data.v = zeros(length(data.t), 1);

for i = 1:s
    
    if progress
        if rem(i,r) == 0
            % Update the progress bar
            d.Value = 0.2 + 0.7*i/s;
            d.Message = 'Integrating...';
        end
    end
    
    % Compute the numerical integration
    data.v(i+1) = trapz(data.ay(i:i+1));
    
end


%% Find the take-off points

% Setup

% Define required variables
h = 20;                     % this will look for at most h jumps
rng = 5;                    % look for sign change rng before/after j
vh = maxk(data.v,h);        % finds the h highest velocities
vh = vh(vh > mean(vh));

% Preallocate memory for the following loop
toff = NaT(length(vh), 1, 'Format', 'HH:mm:ss.SS'); % NaT = Not a Time
a = NaN(length(vh),1); % NaN = Not a Number

for i = 1:length(vh)
    j = find(data.v == vh(i)); % finds the index of the ith velocity
    a(i) = data.ay(data.v == vh(i)); % finds the accel. associated with ith
    % velocity
    
    if a(i) >= 0.1
        % Look for a sign change in acceleration
        for k = j-rng:j+rng
            if sign(data.ay(k)) ~= sign(data.ay(k+1))
                if abs(data.ay(k)) < abs(data.ay(k+1))
                    a(i) = data.ay(k);
                    toff(i) = data.t(k);
                    break
                else
                    a(i) = data.ay(k+1);
                    toff(i) = data.t(k+1);
                    break
                end
            end
        end
    else
        % If a is nearly zero, get capture that time as the takeoff time
        toff(i) = data.t(j); 
    end
end

% Combine desired data into a separate table
T = table(toff, a, vh, 'VariableNames', {'takeoff', 'acceleration', ...
    'velocity'});

% Sort and Clean up the table
index = true(size(T,1),1); % preallocate memory
T = sortrows(T,{'takeoff'}); % Sort the table

% Disregard a possible takeoff time if it is within 'interval' seconds of
% the previous takeoff time
interval = 1;

for i = 1:(size(T,1)-1)
    if (T.takeoff(i+1) - T.takeoff(i)) < duration(0, 0, interval)
        index(i) = false;
    end
end

T.takeoff(~index) = NaT;
keep = ~isnat(T.takeoff);

U = table(T.takeoff(keep), T.acceleration(keep), T.velocity(keep), ...
    'VariableNames', {'takeoff', 'acceleration', 'velocity'});
T = U;
clear U

% Display the cleaned up table in the workspace
disp('Possible takeoff jumps...'); disp(' ');
disp(T)
disp('Acceleration should be nearly 0 where velocity is near maximum.'); disp(' ')

%% Find the land points

% Setup

% Clear any data from the previous section
clear a 

% Define required variables
rng = 5;
m = size(T,1); % this will look for at most m landings
min_air_time = 0.1;
max_air_time = 1;

% Preallocate memory before the following loop
vm = zeros(m,1);
a = vm;
land = NaT(length(vm), 1, 'Format', 'HH:mm:ss.SS');

% Loop through each takeoff time and look for a landing just after that
for i = 1:m
    
    % Get the indicies for time greater than the current takeoff time plus
    % the minimum air time, but less than the maximum air time
    index = (data.t > (T.takeoff(i) + duration(0, 0, min_air_time))) &...
        (data.t < (T.takeoff(i) + duration(0, 0, max_air_time)));
    
    % Get the minimum velocity for the desired indicies
    vm(i) = mink(data.v(index), 1); % 1 means looking for 1 min value
    j(i) = find(data.v == vm(i));
    a(i) = data.ay(data.v == vm(i));
    
    % If the acceleration value is not small, look for a sign change
    if abs(a(i)) >= 0.1
        % Look for a sign change
        for k = j(i)-rng:j(i)+rng
            if sign(data.ay(k)) ~= sign(data.ay(k+1))
                if abs(data.ay(k)) < abs(data.ay(k+1))
                    a(i) = data.ay(k);
                    land(i) = data.t(k);
                    break
                else
                    a(i) = data.ay(k+1);
                    land(i) = data.t(k+1);
                    break
                end
            end
        end
    else    
    % If the acceleration value is small, just pick it as the land time
    % and keep the accel. value from above
    land(i) = data.t(data.v == vm(i));
    end
end

% Group the data into a table
L = table(land, a, vm, 'VariableNames',{'land', 'acceleration', 'velocity'});

keep = ~isnat(L.land);

U = table(L.land(keep), L.acceleration(keep), L.velocity(keep), ...
    'VariableNames', {'land', 'acceleration', 'velocity'});
L = U;

% Display the data to the command window
disp('Possible landings...'); disp(' ')
disp(L)
disp('Acceleration should be zero where velocity is near minimum.') 
disp(' ');

%% Calculate Jump Height

% Preallocate memory for the following loop
height = zeros(m,1);

for i = 1:m
    % Calculate flight time
    if duration(land(i) - T.takeoff(i)) > 0
        flighttime(i) = duration(land(i)-T.takeoff(i),'Format','hh:mm:ss.SS');
        t = hours(flighttime(i))*3600;
        % Calculate jump height
        % This assumes accel. data is in m/s^2
        height(i) = 0.5 * 9.81 * (t/2)^2;
    end
end

try
    E = table(T.takeoff, L.land, flighttime', height,'VariableNames',...
        {'takeoff','land','flighttime','height'});
    disp('Results...'); disp(' ')
    disp(E)
catch
    fprintf('No jumps found between row %i and %i\n', row_start, row_end);
end

%% Visualize the data

if visualize
    figure % opens a figure window
    
    % Plot time vs acceleration in the y
    subplot(2,1,1)
    plot(data.t, data.ay)
    ylabel('Acceleration')
    grid on
    title('Accel. and Velocity vs Time, (displayed positive up)')
    
    % Plot time vs velocity in the y (positive
    subplot(2,1,2)
    plot(data.t, data.v)
    ylabel('velocity')
    xlabel('time')
    grid on
    
    % Show the current graph (just in case it opens in the background)
    shg
end

%% Save
if record
    save data.mat data
    save results.mat T
    if visualize
        savefig('data_figure')
    end
end

%% Clean up

if progress
    % Close the progress dialog
    close(d);
end

%clear a d filename h i j k r rng row_end row_start s toff vh

disp('Analysis complete.')

% Display script run time
if timer
    toc
end