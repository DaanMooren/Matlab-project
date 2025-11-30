% Perf_Cal_StimOn
% Only for checking the delay and phase condition
% The acc, mean and std are not correct anymore with stimulation on
% Input data: .mat file including structures of 'allTs_trigger', 'IBF' and 'EEGData'
restoredefaultpath;
if ismac
    addpath('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/08_Code_book_variables/EEG/00_datacheck/');
else
    addpath('\\ca-um-nas201\fpn_rdm$\DM0941_IL_Finetuning\07_Raw_data\CLOSED_LOOP\Scripts\Performance\');
    addpath '\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\toolbox\fieldtrip-20171217';
end

close all;
clear all;
clc;
warning off;
ft_defaults;
% subjects = {'P16','P17','P18','P20','P23','P24','P25',...
%     'P26','P27','P28','P29','P30','P31','P33','P34','P35',...
%     'P36','P37','P38','P39','P40','P41','P42','P43','P44','P45',...
%     'P46','P47','P48','P52','P53','P54','P55','P56','P57',...
%     'P58','P59','P60','P61'}; % for batch processing
subjects = {'p8'};
% sessions = {'_1','_-1'}; % for batch processing
sessions = {'S_5_s1'};
phaseCon = -1; % 1 inphase -1: antiphase 0 sham
fs = 1000;
technical_delay = 18;
win_length = fs;
plotRaw = 1; % 1: raw; 2: filtered
COI = 1; % 1: C1; 2:
COIlabel = {'C1' 'CP1' 'CP13' 'CP5' 'C5' 'FC5' 'FC3' 'FC1'};

% for COI = 1:4
    for sb = 1:length(subjects)
        subj = subjects{sb}
        for ss = 1:length(sessions)
            sess = sessions{ss}
            % phaseCon = session(ss); % 1: inphase; -1: antiphase; 0: sham
            
            if ismac
                rootdir = append('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/07_Raw_data/closedloop/EEG/',subj);
                outputdir = '/Volumes/fpn_rdm$/DM0941_IL_Finetuning/07_Raw_data/CLOSED_LOOP/Scripts/Performance';
                cd(rootdir);
                filename = append(subj,'_', sess,'.mat');
                a=load(filename);
            else
                % rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2186_IL_ClosedLoop\07_Raw_data\closedloop\EEG\',subj);
                outputdir = '\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\09_Data_after_cleaning\';
                rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\07_Raw_data\',subj);
                cd(rootdir);
                filename = append(subj,'_', sess,'.mat');
                a=load(filename);
            end
            
            num = find(a.allTs_trigger == 0,1)-1;
            
            %% Plotting
            figure0 = figure;
            p = plot([1:1:length(a.EEGData)],a.EEGData(COI,:));
            for i = 1:500
                hold on;
                % xline(a.allTs_trigger(i)+technical_delay);
                % hold on;
                xline(a.allTs_trigger(i));
                % hold on;
                % xline(a.allTs_trigger(i)+technical_delay+50);
            end
            p.DataTipTemplate.DataTipRows(1).Format = '%g'; % x
            sample = 1;
            figure
            for n = 1:num-1
                Targetpoint = a.allTs_trigger(n);
                chunk = a.EEGData(COI,Targetpoint:Targetpoint+win_length);
                [~,pks] = findpeaks(chunk,'MinPeakDistance',30,'MinPeakProminence',100); %changed 05122024
                if phaseCon == 1
                    Stimdelay(n) = pks(2)-(pks(3)-pks(2));
                elseif phaseCon == -1
                    Stimdelay(n) = pks(1)-(pks(2)-pks(1))/2;
                elseif phaseCon == 0
                    clear pks
                    [~,pks] = findpeaks(chunk,'MinPeakWidth',200);
                    Stimdelay(n) = pks(1)-500;
                end
            end
            scatter(1:length(Stimdelay),Stimdelay,25,'filled');
            
            meanDelay = median(Stimdelay(3:end));
            yline(meanDelay,'red');
            set(gca, 'YLim', [0, 50]);
            title(append(string(subj),string(sess),'_',COIlabel{COI}), 'interpreter', 'none' );
%             cd(outputdir);
%             saveas(gcf, append(string(subj),string(sess),'_',COIlabel{COI},'_delay.tiff'));
  %%          
            figure
            for n = [2:2:12 round(num/2)-10:2:round(num/2)+12 num-10:2:num]
                % for n = 2:2:12
                Targetpoint = a.allTs_trigger(n) + round(fs*technical_delay/1000);
                allVec = a.EEGData(:,Targetpoint-win_length/2:Targetpoint+win_length/2);
                if size(allVec,1) == 1
                    chunk = allVec(:,:);
                else
                    ref = mean(allVec(2:8,:));
                    chunk = allVec(COI,:)-ref;
                end
                chunk_filt = ft_preproc_bandpassfilter(chunk, fs, [a.IBF-1 a.IBF+1], [], 'fir','twopass');
                clear chunk
                hold on;
                subplot(4,6,sample);
                % subplot(3,2,sample);
                if plotRaw
                    plot(allVec(COI,round(win_length/4):round(win_length*3/4)));
                else
                    plot(chunk_filt(round(win_length/4):round(win_length*3/4)));
                end
                hold on;
                xline(round(win_length/4),'blue');
                hold on;
                xline(round(win_length/4) + round(1000./a.IBF),'red'); % 0512224
                % hold on;
                % xline(round(win_length/4)-technical_delay+50+mean(Stimdelay),'black');
                sample = sample + 1;
                set(gca,'YTick',[]);
                set(gca,'XTick',[]);
                title(['n = ' num2str(n)]);
            end
            sgtitle(append(string(subj),string(sess),'_',COIlabel{COI}),'interpreter', 'none' )
            % Save
            % cd(outputdir);
            % saveas(gcf, append(string(subj),string(sess),'_', COIlabel{COI}, '_stim.tiff'));
            
            pause(3);
            % close all
        end
    end
% end
