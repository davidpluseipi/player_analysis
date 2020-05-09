function output = maxk_mac(vector,k)
output = zeros(k,1);
for i = 1:k
    output(i) = max(vector);
    vector = vector(vector ~= output(i));
end