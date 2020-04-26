for i = 1:10
    v(i) = trapz(data.AcclY(1+i*10:10*i+10))
end