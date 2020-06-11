%% Player Analysis
%
% Filename: player_analysis2.m
% Created: 2020-5-23
% By: David Meissner
% Copyright 2020
%
%% Description
% This script will prompt the user to select a .csv or a folder with a
% group of .csv files so that they may be analyzed to look for player jumps
% and the height of those jumps may be calculated.
%
% If you alter the format of the input .csv to something other than that
% required by the nested function within import_and_analyze.m, make sure
% you change that code and the numeric entries within the variable 'col'.
% These indicate the columns to be pulled out of the imported data and
% stored in a variable with the player's name.
%
%% This starting code allows the script to run directly or via an app

close all; % close all figures
clc % clear the command window

disp('Running player analysis...')

if ~exist('app', 'var')     % if not using the app
    clear
    app = false;
else
    clearvars('-except', 'app', 'dname', 'results_folder');
end

%% Declar variables for instrumentation, troubleshooting, etc.

inst = false; % set this to true, if you want to 'instrument' the code
trouble = false; % change this to true, when troubleshooting

%% Allow user to select date file or folder where they have multiple data files

if ~app                         % if not using the app
    if ~trouble                 % if not troubleshooting
        result = ask();         % ask() is a nested function at the bottom 
                                %  of this script
        if isfolder(result)
            dname = result;
        else
            filename = result;
        end
    else                        % if troubleshooting, don't ask, just set result
        result = 'C:\Users\david\googledrive\MATLAB\soccer\pod_data\2020-05-22\2020-05-22-Arreaga-RawDataExportExtended.csv';
    end
end

%% Allow user to select the folder where the results will be saved

if ~app
    if ~trouble
        uiwait(msgbox('You will next select the folder where your results will go...',...
            'Step 2', 'modal'));
        if ispc
            results_folder = uigetdir('C:\Users\david\googledrive\MATLAB\soccer\results');
        else
            results_folder = uigetdir('~');
        end
    else
        if ispc
            results_folder = 'C:\Users\david\googledrive\MATLAB\soccer\results';
        else
            results_folder = pwd;
        end
    end
end

tic % Start a timer

if isfolder(result)
    F = dir(dname);
    for z = 3:size(F,1)
        file = F(z).name;
        [~,~,ext] = fileparts(file);
        if strcmp(ext, '.csv')
            filename = fullfile(dname,file);
            grab
            process
        else
            disp('Filetype must be .csv right now.')
        end
    end % this is the end of the for loop that looks for all .csv in the desired folder
else    % if result is not a folder, i.e. a filename
    filename = result;
    grab
    process
end

%% Measure Algorithm Runtime

run_time = toc; % Stop the timer
if run_time < 60
    fprintf('Algorithm run time: %.0f seconds\n', round(run_time));
else
    fprintf('Algorithm run time: %.1f minutes\n\n', run_time/60);
end

%% Nested Function

function result = ask()
answer = questdlg('Are you loading one .csv? or Do you want to load all .csv''''s in a folder?', ...
    'Selecting Data', ...
    'one .csv','all .csv files in a folder','all .csv files in a folder');
% Handle response
switch answer
    case 'one .csv'
        
        [file,path,~] = uigetfile('C:\Users\david\googledrive\MATLAB\soccer\pod_data\*.csv'); % files other than .csv have not been tested
        if isequal(file,0)
            disp('File selection cancelled.')
            result = 0;
            return
        else
            result = fullfile(path, file);
            disp(['User selected ', result])
        end
    case 'all .csv files in a folder'
        
        if ispc
            result = uigetdir('C:\Users\david\googledrive\MATLAB\soccer\pod_data');
        else
            result = uigetdir('~');
        end
end


end

%% EOF (end of file)
