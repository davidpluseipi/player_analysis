close all;
E = whos('data_*');
for u = 1:size(E,1)
    
    figure(u)
    table_name = E(u).name;
    title(table_name(5:end))
    index_circle = eval(strcat('find(', table_name, '.ay == 0)'));
    eval(strcat('plot(', table_name, '.t(index_circle)', ',', '-1*ones(length(index_circle),1),', '''bo''', ')'))
    hold on
    index_star = eval(strcat('find(', table_name, '.v > min(vh))'));
    eval(strcat('plot(', table_name, '.t(index_star)', ',', '-1*ones(length(index_star),1),', '''b*''', ')'))
    shg
end