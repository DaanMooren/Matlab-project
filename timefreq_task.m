%% ----------------------------------------------------------%
%   Script for time-frequency analysis for EEG and EMG data
%   using Wavelet method     
%   Input files: clean EEG/EMG
%   Output files: time-frequency representations (time x frequency x coherence) of EEG/EMG
%------------------------------------------------------------%

restoredefaultpath;
if ismac
    addpath('');
else
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\EEG\02_timefreq\')
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\toolbox\fieldtrip-20171217\');
end

clear all;
close all;
clc;
warning off;
subjects = {'p7','p8','p9','p10','p11','p12','p13','p14','p15','p16','p17',...
    'p18','p19','p20','p21','p22','p23','p25','p26'};

sessions = {'_A_2_s1', '_A_2_s2', '_I_5_s1', '_S_2_s1','_A_1_s1', '_A_1_s2',...
    '_A_15_s1','_A_15_s2','_A_5_s1', '_A_5_s2','_I_2_s1','_S_5_s1'}; % for batch processing

for sb = 1:length(subjects)
    for ss = 1:length(sessions)
        close all;
        subj = subjects{sb}
        if ismac
            rootdir = append('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/09_Data_after_cleaning/closedloop/EEG/',subj,'/stim/');
            outdir = append('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/09_Data_after_cleaning/closedloop/EEG/', subj,'/freq/');
        else
            rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\09_Data_after_cleaning\',subj,'\');
            % !!! change
            outdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\09_Data_after_cleaning\',subj,'\Wvl_cmx\');
        end
        sess = sessions{ss}
        
        filename = append(subj, sess);
        file = append(rootdir,filename,'_clean_task.mat');
        if exist(file, 'file')
            load(file);
        else
            fprintf('File %s does not exist. Skipping to the next.\n', file);
            continue;
        end
%          cfg = [];
%          cfg.viewmode = 'butterfly';
%          ft_databrowser(cfg, data_tapping); %exit the browser by pressing 'q
        %% --------------------------%
        %   WAVELET                %
        % https://www.fieldtriptoolbox.org/tutorial/timefrequencyanalysis/
        %--------------------------%
        prestim = data_tapping.time{1}(1);
        cfg = [];  
        cfg.output     = 'pow';
        cfg.foi        = 1:0.5:45; % Frequency range of interest
        cfg.toi        = prestim:0.02:prestim+2.8;  % For all conditions
        cfg.method     = 'wavelet';
        % cfg.width      = linspace(2,12,length(cfg.foi)); % Width varies cross frequency
        cfg.width      = 8; % fixed width;
        cfg.keeptrials = 'no';
        cfg.channel    = 'all'; % or specify the relevant channel(s)
        freq_tap       = ft_freqanalysis(cfg, data_tapping);
        
%         %% visualize 
%         figure
%         cfg = [];
%         cfg.channel = 'EMG';
%         cfg.baseline = [4.0 4.2];
%         cfg.zlim = [-0.5 0.5];
%         cfg.layout       = 'easycapM1';
%         cfg.baselinetype = 'relchange';
%         ft_singleplotTFR(cfg, freq_tap);

%         %% visualize 
%         cfg = [];
%         cfg.baseline     = [4.5 4.7];
%         cfg.channel      = 'C1';
%         cfg.baselinetype = 'db';
%         % cfg.zlim         = [-0.5 0.5];
%         cfg.marker       = 'on';
%         cfg.layout       = 'easycapM1';
%         cfg.colorbar     = 'yes';
%         % figure
%         % ft_topoplotTFR(cfg, freq_tap);
%         figure
%         ft_singleplotTFR(cfg, freq_tap);

        mkdir(outdir);
        filename2 =fullfile(outdir,[filename '_freq']);
        save(filename2, 'freq_tap');
                 
    end
end
