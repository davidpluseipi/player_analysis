%% Process
%
% Filename: process.m
% Created: 2020-5-23
% By: David Meissner
% Copyright 2020
%
%% Description:
% This script is called by player_analysis2.m
% There is one loop to process the data to look for jumps.
%
D = whos('data_*'); % capture any variables in the workspace with this prefix
x = 100; % for UI table placement x,y from lower left corner
y = 100;
shift = 50; % placement shifts up and right for ever new UI table

h = 10; % max jumps to look for in each player's data set
rng = 9; % indices on either side of v to look for matching a
% 4 gives 3 jumps for Arreaga

% jumps_by_rng = zeros(9, 10);
% for rng = 1:10
    %% Processing Loop
    
    
    for w = 1:size(D,1)
        
        if inst; disp('Processing Data...'); end
        %% Process the Data
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
        al = vm;
        jl = vm;
        landtime = NaT(length(vm), 1, 'Format', 'HH:mm:ss.SS');
        height = zeros(m,1);
        airtime = height;
        
        %% Determine any possible takeoff/land times
        if inst; disp('starting takeoff time search'); end
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
            if inst; disp('starting land time search'); end
            if toff(i) ~= NaT
                % Get the indicies for time greater than the current takeoff time plus
                % the minimum air time, but less than the takeoff plus max air time
                indices = find((data2.t >= (toff(i) + duration(0, 0, min_airtime))) &...
                    (data2.t <= (toff(i) + duration(0, 0, max_airtime))));
                % There are no dates, just times, so sometimes you'll
                % get more than one group of indicies reported, so...
                takeoff_index = j;
                indices = indices(indices < (takeoff_index + 100));
                
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
                    jl(i) = jland(1);
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
            if inst; disp('starting height calculation'); end
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
        if inst; disp('creating jump table'); end
        jump_table = table(toff, landtime, airtime, height,'VariableNames',...
            {'takeoff','land','airtime','height'});
        
        jump_table = sortrows(jump_table,{'takeoff'}); % Sort the table
        
        if jump_table.takeoff(1) == NaT || jump_table.land(1) == NaT
            % fprintf('No jumps found between row %i and %i\n', row_start, row_end);
        else
            % only keep rows that have actual data
            keep1 = ~isnat(jump_table.takeoff);
            keep2 = ~isnat(jump_table.land);
            keep = keep1 & keep2;
            jump_table = table(jump_table.takeoff(keep), jump_table.land(keep),...
                jump_table.airtime(keep), jump_table.height(keep), ...
                'VariableNames', {'takeoff','land','airtime','height'});
        end
        
%         disp(D(w).name)
%         disp(jump_table)
        
        %% Throw Jump Table in a UI Figure
        
        if size(jump_table,1) ~= 0
            
            %         if inst; disp('Creating UI Table'); end
            %         fig = uifigure('Position',[x y 752 250]);
            %         fig.Name = D(w).name;
            %         uit = uitable('Parent',fig,'Position',[25 50 700 200]);
            %         uit.Data = jump_table;
            %         x = x + shift;
            %         y = y + shift;
            
            
            % Save Data and Clear Up Memory
            if inst; disp('Saving player data table and jump table in .mat file.'); end
            
            matfilename = strcat(D(w).name, '.mat');
            results_file = strcat(results_folder, '\results.xlsx');
            
            try
                save(matfilename, D(w).name, 'jump_table', '-v7.3');
            catch
                error('Failed to save mat file from jump table.')
            end
            
            try
                movefile(matfilename, results_folder);
            catch
                error([matfilename, ' failed to copy to ', results_folder])
            end
            
            % Write data to excel
            try
                writetable(jump_table, strcat(results_folder,...
                    '\results.xlsx'), 'Sheet', D(w).name, 'Range', 'A1');
                % disp('Data in table successfully copied to excel.')
            catch
                error('mat-file failed to copy to excel.')
            end
            
        else
            writematrix(['No jumps this session.'], strcat(results_folder,...
                '\results.xlsx'), 'Sheet', D(w).name, 'Range', 'A1');
        end
        
        figure(w)
        table_name = D(w).name;
        title(table_name(5:end))
        index_circle = eval(strcat('find(', table_name, '.ay == 0)'));
        eval(strcat('plot(', table_name, '.t(index_circle)', ',',...
            '-1*ones(length(index_circle),1),', '''bo''', ')'))
        hold on
        index_star = eval(strcat('find(', table_name, '.v > min(vh))'));
        eval(strcat('plot(', table_name, '.t(index_star)', ',',...
            '-1*ones(length(index_star),1),', '''b*''', ')'))
        shg
%     jumps_by_rng(rng,w) = size(jump_table,1);    
%     disp(jumps_by_rng)
%     disp('------------------------------------------------')
    end % This is the end of the processing loop
   
% end
% disp(jumps_by_rng)
% desired_filename = 'results.xlsx';
% new_filename = dont_overwrite(desired_filename);
% writematrix(['No jumps this session.'], strcat(results_folder,...
%             new_filename), 'Sheet', D(w).name, 'Range', 'A1');
%
% %% Nested Function
%
% function new_filename = dont_overwrite(desired_filename)
% % try to save, writetable, writematrix, etc. but don't overwrite anything
% files = dir(results_folder);
%
% for i = 3:size(files,1)
%
%     if strcmp(fullfile(results_folder, desired_filename), ...
%             fullfile(files(i).folder, files(i).name))
%         index = strfind(files(i).name,'.');
%         ext = files(i).name(index+1:end);
%         ending = string(datetime('now','Format','yyyy_MM_dd_HHmm'));
%         new_filename = strcat(files(i).name(1:index-1), '_', ending, '.', ext);
%     else
%         new_filename = desired_filename;
%     end
% end
%
%
% end
%% EOF (end of file)