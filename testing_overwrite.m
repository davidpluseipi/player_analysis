
results_folder = 'C:\Users\david\googledrive\MATLAB\soccer\results';
desired_filename = 'results.xlsx';
new_filename = dont_overwrite(results_folder, desired_filename);
writematrix(['No jumps this session.'], strcat(results_folder,...
            new_filename), 'Sheet', D(w).name, 'Range', 'A1');
        
%% Nested Function

function new_filename = dont_overwrite(results_folder, desired_filename)
% try to save, writetable, writematrix, etc. but don't overwrite anything
files = dir(results_folder);

for i = 3:size(files,1)
     
    if strcmp(fullfile(results_folder, desired_filename), ...
            fullfile(files(i).folder, files(i).name))
        index = strfind(files(i).name,'.');
        ext = files(i).name(index+1:end);
        ending = string(datetime('now','Format','yyyy_MM_dd_HHmm'));
        new_filename = strcat(files(i).name(1:index-1), '_', ending, '.', ext);
    else
        new_filename = desired_filename;
    end
end


end