%%
clear all
%%
filename = 'C:\Users\david\googledrive\MATLAB\soccer\match_data1.csv';
ds = tabularTextDatastore(filename,'TreatAsMissing','NA');
ds.SelectedFormats(4) = {'%s'};
preview(ds)
%%
tt = tall(ds);
tt.Time = datetime(tt.Time, 'InputFormat', 'HH:mm:ss.SS', 'Format', 'HH:mm:ss.SS');
%% Create Player Names
p1 = matlab.lang.makeUniqueStrings('Alex Villanueva');

%% 
