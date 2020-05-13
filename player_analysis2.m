%% Option to delete .mat files (for testing)
answer = questdlg('Delete existing player .mat files? (for testing player_analysis)', ...
    'Delete', ...
    'Delete','Keep','Cancel','Delete');
% Handle response
switch answer
    case 'Delete'
        fprintf('Deleting the following...\n')
        fprintf('data_AlexVillanueva.mat &\n')
        fprintf('data_AntinoLopez.mat\n')
        delete data_AlexVillanueva.mat data_AntinoLopez.mat
    case 'Keep'
        % do nothing
    case 'Cancel'
        return
end
%%
clear; close all; clc


%% Pre Data Grab

%% Allow user to select file
[file,path,indx] = uigetfile('*.csv'); % files other than .csv have not been tested
if isequal(file,0)
   disp('File selection cancelled.')
   return
else
    filename = fullfile(path, file);
    disp(['User selected ', filename,...
         ' and filter index: ', num2str(indx)])
end
%% Auto select file
tic
% filename = 'C:\Users\david\googledrive\MATLAB\soccer\match_data1.csv';
row_start_min = 270000; % minimum is 2 (row 1 contains the variable names)
row_end_final = 310000; % to continue until end of file, use Inf
chunk = 20000; % # of rows in each data grab
count = 0; % for display while matlab is running

h = 10; % jumps to look for in each data grab
rng = 5; % milliseconds on either side of v to look for matching a
interval = 1; % # of seconds to wait before looking for a second ju
min_airtime = 0.1; % shortest jump time to look for
max_airtime = 1; % longest jump time to look for
num_players = 2; % number of players with data in selected data file
% var2 = 1:num_players;
% var3 = cell(num_players, 1);
% for i = 1:length(var2)
%     var3{i} = num2str(var2(i));
% end
db = categorical({'-'}); % database of who's had any amount data imported

for row_start = row_start_min : chunk : row_end_final % overall loop
    count = count + 1;
    row_end = row_start + chunk;
    fprintf('count: %d, row_start: %d, row_end: %d\n\n', count, row_start,...
        row_end)
    
    %% Data Grab
    disp('importing data for...')
    data = importfile(filename, [row_start, row_end]);
    if isempty(data)
        break % break the overall 'for loop' if all data is already processed
    end
    disp(categories(data.name)) % display the player names in this data grab
    data.ay = -1 * data.ay; % make the y-axis accel. data positive up
    data.t = datetime(data.t, 'InputFormat', 'HH:mm:ss.SS', 'Format',...
        'HH:mm:ss.SS'); % convert time 'strings' to 'datetime' datatype
    s = size(data, 1); % size of the 1st dimension of data
    data.v = zeros(s, 1); % preallocate velocity data with zeros
    disp('starting integration')
    for i = 1:s-1
        data.v(i) = trapz(data.ay(i:i+1)); % calculate v from a
    end
    disp('integration complete')
    
    %% Post data grab
    names = categories(data.name); % names in data are 'categorical' datatype in an array of 'cell' datatype
    ending = matlab.lang.makeValidName(names); % make names a valid matlab variable name (no spaces)
    prefix = cell(size(names,1), 1); % create empty array of 'cell' datatype
    prefix(:) = {'data_'};
    varnames = strcat(prefix, ending); % concatenate strings in these 2 'cell' arrays
    col = [4 12 21]; % grab columns for t, ay, and v
    
    for n = 1:size(names,1) % loop through each player with data in this set / grab
        
        % if data_playername table doesn't exist as a variable
        if ~exist(varnames{n}, 'var')
            % Create a table of data for that player
            assignin('base', varnames{n}, data(data.name == string(names{n}), col));
        else
            % if data_playername already exists as a table, concatenate new data
            % onto or "under" the existing data
            assignin('base', varnames{n}, [eval(varnames{n}); data(data.name == string(names{n}), col)]);
            
        end
        % after bringing any amount of data for a particular player, add
        % their name to the database of names
        if ~contains(string(db(:)), names{n})
            db = addcats(db, names(n));
        end
        
        if n == size(names,1)
            disp('Players with any amount of data imported:')
            disp(categories(db))
        end
    end
end



%% Processing
%A = categories(db);
%for j = 2:size(A,1) % start at 2 because 1st category is '-'
D = whos('data_*');
for w = 1:size(D,1)
    %name2 = matlab.lang.makeValidName(A{j});
    % if name in .mat file is also in the database created above...
    %         if contains(B(w).name, name2)
    %             % do nothing. Do not overwrite existing data in the .mat.
    %         else
    disp('Processing Data...')
    %% Process Data
    data2 = eval(D(w).name);
    if ispc
        vh = maxk(data2.v,h);
    else
        vh = maxk_mac(data2.v,h);
    end
    m = length(vh);
    
    toff = NaT(length(vh), 1, 'Format', 'HH:mm:ss.SS'); % NaT = Not a Time
    at = NaN(length(vh),1); % NaN = Not a Number
    vm = zeros(m,1);
    al = zeros(m,1);
    jl = zeros(m,1);
    landtime = NaT(length(vm), 1, 'Format', 'HH:mm:ss.SS');
    height = zeros(m,1);
    airtime = zeros(m,1);
    
    %% Determine any possible takeoff/land times
    disp('starting takeoff time search')
    for i = 1:length(vh)
        %% Determine takeoff times
        jtoff = find(data2.v > min(vh));
        at(i) = data2.ay(jtoff(i));
        
        if at(i) >= 0.1
            var1 = jtoff(i)-rng;
            if var1 <= 0
                var1 = 1; % prevent negative index
            end
            for k = var1:jtoff(i)+rng % Look for a sign change
                if sign(data2.ay(k)) ~= sign(data2.ay(k+1))
                    if abs(data2.ay(k)) < abs(data2.ay(k+1))
                        at(i) = data2.ay(k);
                        toff(i) = data2.t(k);
                        j = k;
                        break
                    else
                        at(i) = data2.ay(k+1);
                        toff(i) = data2.t(k+1);
                        j = k;
                        break
                    end
                end
            end
        else
            % If a is near zero, capture that as the takeoff time
            toff(i) = data2.t(j);
        end
        
        % Disregard a possible takeoff time if it is within 'interval' seconds of
        % the previous takeoff time
        for b = 1:length(toff)-1
            if toff(b+1) - toff(b) < duration(0, 0, interval)
                toff(b+1) = NaT;
            end
        end
        
        %% Determine associated land times
        disp('starting land time search')
        if toff(i) ~= NaT
            % Get the indicies for time greater than the current takeoff time plus
            % the minimum air time, but less than the takeoff plus max air time
            indices = find((data2.t >= (toff(i) + duration(0, 0, min_airtime))) &...
                (data2.t <= (toff(i) + duration(0, 0, max_airtime))));
            
            % Get the minimum velocity for the desired indicies
            vmin = mink(data2.v(indices), 1); % 1 means looking for 1 min value
            
            if isempty(vmin)
                break
            else
                vm(i) = vmin; % keep track of all the vmins in vm
                
                % Index of the land time is index of the shortest possible
                % jump, plus the index of vmin within the jump window
                jland = find(data2.t == (toff(i) + duration(0,0,min_airtime)))...
                    + find(data2.v(indices) == vm(i));
                jl(i) = jland;
                % Get the indicies of accel. where velocity is equal to the
                % minimum
                al(i) = data2.ay(jl(i));
                
                % If the acceleration value is not small, look for a sign change
                if abs(al(i)) >= 0.1
                    % Look for a sign change
                    for k = jl(i)-rng:jl(i)+rng
                        if sign(data2.ay(k)) ~= sign(data2.ay(k+1))
                            if abs(data2.ay(k)) < abs(data2.ay(k+1))
                                al(i) = data2.ay(k);
                                landtime(i) = data2.t(k);
                                jland = k;
                                break
                            else
                                al(i) = data2.ay(k+1);
                                landtime(i) = data2.t(k+1);
                                jland = k;
                                break
                            end
                        end
                    end
                else
                    % If the acceleration value is small, just pick it as
                    % the land time and keep the accel. value from above
                    landtime(i) = data2.t(jland);
                end
            end
        end
        
        %% Calculate flight time and height of jump
        disp('starting height calculation')
        if ~isnat(toff(i)) && ~isnat(landtime(i))
            airtime(i) = landtime(i).Second - toff(i).Second;
            if airtime(i) > 0
                % Calculate jump height
                % This assumes accel. data is in m/s^2
                height(i) = 0.5 * 9.81 * (airtime(i)/2)^2;
            end
        end
    end
    
    %% Create Jump Table
    disp('creating jump table')
    jump_table = table(toff, landtime, airtime, height,'VariableNames',...
        {'takeoff','land','airtime','height'});
    
    jump_table = sortrows(jump_table,{'takeoff'}); % Sort the table
    
    if jump_table.takeoff(1) == NaT || jump_table.land(1) == NaT
        fprintf('No jumps found between row %i and %i\n', row_start, row_end);
    else
        % only keep rows that have actual data
        keep1 = ~isnat(jump_table.takeoff);
        keep2 = ~isnat(jump_table.land);
        keep = keep1 & keep2;
        jump_table = table(jump_table.takeoff(keep), jump_table.land(keep), jump_table.airtime(keep), jump_table.height(keep), ...
            'VariableNames', {'takeoff','land','airtime','height'});
    end
    disp(names{n})
    disp(jump_table)
    
    %% Throw Jump Table in a UI Figure
    disp('creating UI')
    fig = uifigure('Position',[100 100 752 250]);
    fig.Name = names{n};
    uit = uitable('Parent',fig,'Position',[25 50 700 200]);
    uit.Data = jump_table;
    
    %% Save Data and Clear Up Memory
    disp('saving...')
    % save(filename, variables, version)
    save(strcat(D(w).name, '.mat'), D(w).name, 'jump_table', '-v7.3');
end

%% Measure Algorithm Runtime
run_time = toc;
if run_time < 60
    fprintf('Algorithm run time: %.0f seconds\n', round(run_time));
else
    fprintf('Algorithm run time: %.1f minutes\n', run_time/60);
end

