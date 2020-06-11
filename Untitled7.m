jumps_by_range = zeros(9,10);
for rng = 1:10
    for w = 1:9
        jumps = randi([0 3]);
        jumps_by_range(w,rng) = jumps;
        disp(jumps_by_range)
    end
end
