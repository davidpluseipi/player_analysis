clear a b c
a = [1 2 3]
b = a
if length(a) == length(b)
    i = 1;
    c(i) = a(i)
    while i <= length(a)
        c(i*2) = b(i)
        if i+1 <= length(a)
            c(i*2+1) = a(i+1)
        end
        i = i + 1;
    end
end