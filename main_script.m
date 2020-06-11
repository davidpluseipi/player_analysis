% main script
input = 1;
output = nested_function(input)

function [output] = nested_function(input)

try 
    disp(strcat('Input was:', string(input)))
    input = input(2)
catch
    error('Input failed to display.')
end

output = input;

end