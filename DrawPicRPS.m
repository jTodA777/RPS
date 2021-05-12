for i = 1 :1: inf
    try
        A = readmatrix(['data/' num2str(i) '.csv']);
    catch
        break
    end
    imagesc(A)
    colorbar
    title(num2str(i))
%     pause(0.05)
    drawnow
    
end