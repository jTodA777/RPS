clearvars
close all
clc

stepsize = 50



color = {'k','r','g','b'}
colormap_rgb = [0 0 0;1 0 0; 0 1 0; 0 0 1];
colormap(colormap_rgb)

files = dir('.')
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir]
% Extract only those that are directories.
subFolders = files(dirFlags)
% 
% while true
    for k = 4:length(subFolders)
        
        title_name = subFolders(k).name;
        title_name(subFolders(k).name=='_')=' ';
        figure(k-3)
%         pause
        colormap(colormap_rgb)
        FolderName = [subFolders(k).name '/'];
        clf
        HowManyFiles = sum(cellfun(@(x) isfile(x),cellfun(@(x) [FolderName x],{dir(FolderName).name},'UniformOutput',false)));
        population = zeros(HowManyFiles,4);
        
        for i = stepsize :stepsize: HowManyFiles
            try
                A = readmatrix([FolderName num2str(i) '.csv']);
                subplot(2,2,4)
                t = arrayfun(@(x) sum(A==x,'all'),[0 1 2 3]);
                population(i,:) = t;
                for j = 1:4
                    plot(stepsize :stepsize:i,population(stepsize:stepsize:i,j),color{j})
                    hold on
                end
                
                xlim([i-50*stepsize i])
                hold off
                subplot(2,2,2)
                for j = 1:4
                    plot(stepsize :stepsize:i,population(stepsize:stepsize:i,j),color{j})
                    hold on
                end
                
                xlim([0 i])
                hold off
            catch
                break
            end
            
            subplot(2,2,[1,3])
            imagesc(A,[0 3])
            sgtitle(title_name)
            title(num2str(i))
            %     pause(0.05)
            drawnow
            
        end
    end
% end