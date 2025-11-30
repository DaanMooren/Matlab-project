% ======================================================================
%     Script for pre-processing inter-stimulation rest EEG + EMG data
% ======================================================================

clear all;
close all;
clc;
warning off;

restoredefaultpath;
if ismac
    addpath('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH_P/08_Code_book_variables/EEG/01_preprocessing'); % add path of the current script
    addpath('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH_P/08_Code_book_variables/toolbox/fieldtrip-20171217/'); % add path of the Fieldtrip Toolbox
else
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH_P\08_Code_book_variables\EEG\01_preprocessing'); % add path of the current script
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH_P\08_Code_book_variables\toolbox\fieldtrip-20171217\'); % add path of the Fieldtrip Toolbox
end
ft_defaults; % Sometimes Fieldtrip errors might occur with this line. Command it if neccessary

% subjects = {'p7','p8','p10','p11','p12','p13','p14','p15','p16','p17','p18','p19',...
%     'p20','p21','p22','p25','p26','p27','p28','p29','p30'};
% sessions = {'_A_1_s1', '_A_1_s2','_A_15_s1','_A_15_s2','_A_2_s1', '_A_2_s2',...
%     '_A_5_s1', '_A_5_s2','_I_2_s1','_I_5_s1', '_S_2_s1','_S_5_s1'...
%     }; % for batch processing (!!! Don't change the order)
subjects = {'p7'};
sessions = {'_S_5_s1'};
load('easycapM1_neighb.mat'); % Find more: https://github.com/fieldtrip/fieldtrip/tree/master/template/neighbours
for sb = 1:length(subjects)
    for ss = 1:length(sessions)
        subj = subjects{sb}
        if ismac
            rootdir = append('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH_P/07_Raw_data/',subj,'/'); % set the path to the participant folders
            outputdir = append('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH_P/09_Data_after_cleaning/',subj,'/');         
        else
            rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH_P\07_Raw_data\',subj,'\'); % Set the path to the participant folders
            outputdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH_P\09_Data_after_cleaning\',subj,'\'); % Path of the outcomes
        end
        sess = sessions{ss}
        if strcmp([sess(4) sess(5)],'1_')
            prestim = -1.1; % 
        elseif strcmp([sess(4) sess(5)],'2_')
            prestim = -2.1; % 
        elseif strcmp([sess(4) sess(5)],'15')
            prestim = -1.6; % 
        elseif strcmp([sess(4) sess(5)],'5_')
            prestim = -5.1; % 
        end
        poststim = -prestim+3;
        %% =======================================================
        %           LOAD DATA
        % ========================================================
        filename = append(subj, sess, '.vhdr');
        cd(rootdir);
        cfg = [];
        cfg.dataset = filename;
        cfg.channel                 =  {'all'};           % Indicate the channels we would like to read and/or exclude.
        if exist(filename, 'file')
            data = ft_preprocessing(cfg);
        else
            fprintf('File %s does not exist. Skipping to the next.\n', filename);
            continue;
        end

        %% ------------------------%
        %   SEGMENT DATA           %
        %------------------------%
        cfg = [];
        cfg.dataset = filename;
        cfg.trialdef.eventtype      = 'onset'; % see above
        cfg.trialdef.eventvalue     = 'S15';
        cfg.trialdef.prestim        = prestim;         % prior to stimuli onset
        cfg.trialdef.poststim       = poststim;         % after event onset
        cfg = ft_definetrial(cfg);                % make the trial definition matrix
        data = ft_redefinetrial(cfg,data);
        
        %% ------------------------------------
        %    Filter data               
        % -------------------------------------
        %-----------EEG and EOG-------------------------
        % https://www.fieldtriptoolbox.org/tutorial/continuous/
        cfg = [];
        cfg.channel                 =  {'all', '-EMG','-TP10'}; % TP10 is the system reference channel 
        cfg.demean                  = 'yes';
        cfg.detrend                 = 'yes';
        cfg.bpfilter                = 'yes';
        cfg.bpfreq                  = [1 100];
        cfg.dftfilter               = 'yes';
        cfg.bsfilter                = 'yes';
        cfg.bsfreq                  = [49 51];
        cfg.bsfilttype              = 'firws';
        data_tapping = ft_preprocessing(cfg, data);
%         %----------remove bad channels------------------------%
%         cfg = [];
%         cfg.viewmode = 'butterfly';
%         artif = ft_databrowser(cfg, data_tapping); %exit the browser by pressing 'q
%         % cfg.artfctdef.reject = 'complete';
%         % data_tapping = ft_rejectartifact(cfg, data_tapping);
%         artif.badchannel  = input('write badchannels: ');
%         if ~isempty(artif.badchannel)
%             cfg = [];
%             cfg.badchannel     = artif.badchannel;
%             cfg.method         = 'weighted';
%             cfg.neighbours     = neighbours;
%             data_tapping = ft_channelrepair(cfg,data_tapping);
%             % Visualize the results of channel interpolation
%             cfg = [];
%             cfg.viewmode      = 'vertical';
%             cfg.artifactalpha = 0.8;
%             cfg.artfctdef.badchannel.artifact = artif.badchannel;
%             ft_databrowser(cfg,data_tapping);
%         end

%         %% -----------EMG-------------------------
%         % view raw EMG
%         figure;
%         plot(data.time{5},data.trial{5}(36,:));
%         axis tight;
%         legend(data.label(36));
        %% pre-process EMG
        cfg              = [];
        cfg.channel      =  {'EMG'};
        cfg.continuous   = 'yes';
        cfg.demean       = 'yes';
        cfg.dftfilter    = 'yes';
        cfg.bpfilter     = 'yes';
        cfg.bpfreq       = [1 100];
        cfg.rectify      = 'yes';
        data_emg = ft_preprocessing(cfg,data);       
%         %% view clean EMG
%         % view raw EMG
%         figure;
%         plot(data_emg.time{5},data_emg.trial{5}(1,:));
%         axis tight;
%         legend(data_emg.label(1));

        %% --------------------------%%%
        %     REFERENCE DATA         %%%
        %%%--------------------------%%%    
        % VEOG channel
        cfg              = [];
        cfg.channel      = {'VEOG1','VEOG2'};
        cfg.reref        = 'yes';
        cfg.implicitref  = []; % this is the default, we mention it here to be explicit
        cfg.refchannel   = 'VEOG2';
        VEOG             = ft_preprocessing(cfg, data_tapping);
        
        % only keep one channel, and rename to eogv
        cfg              = [];
        cfg.channel      = 'VEOG1';
        VEOG             = ft_selectdata(cfg, VEOG);
        VEOG.label       = {'VEOG'};
        
        % HEOG channel
        cfg              = [];
        cfg.channel      = {'HEOG1','HEOG2'};
        cfg.reref        = 'yes';
        cfg.implicitref  = []; % this is the default, we mention it here to be explicit
        cfg.refchannel   = {'HEOG2'};
        HEOG             = ft_preprocessing(cfg, data_tapping);
        
        % only keep one channel, and rename to eogh
        cfg              = [];
        cfg.channel      = 'HEOG1';
        HEOG             = ft_selectdata(cfg, HEOG);
        HEOG.label       = {'HEOG'};
        %We now discard these extra channels that were used as EOG from the data and add the bipolar-referenced EOGv and EOGh channels that we have just created:
        
        cfg = [];
        cfg.reref         = 'yes';             % We want to rereference our data
        cfg.refchannel    = {'FT9'};             % Here we specify our reference channels; all = common reference
        data_tapping = ft_preprocessing(cfg, data_tapping);
        
        cfg = [];
        cfg.channel       =  {'all','-FT9','-HEOG1','-HEOG2','-VEOG1','-VEOG2'};
        data_tapping        = ft_selectdata(cfg, data_tapping);
        
        % append the EOGH and EOGV channel to the 60 selected EEG channels
        cfg = [];
        data_tapping = ft_appenddata(cfg, data_tapping, VEOG, HEOG);
        
        %% -----------------------
        %        RUN ICA
        % -----------------------
        cfgica = [];
        cfgica.method = 'runica';
        % cfgica.outputfile = fullfile([outputdir,subj,sess,'_ica']);
        comp = ft_componentanalysis(cfgica,data_tapping);
        
        % plot the components for visual inspection
        figure
        cfg = [];
        cfg.component = 1:31;       % specify the component(s) that should be plotted
        % load('easycapM1.mat');
        cfg.layout    = 'easycapM1'; % specify the layout file that should be used for plotting
        % cfg.layout = 'GSN129.sfp';
        cfg.comment   = 'no';
        ft_topoplotIC(cfg, comp);
%         % LOOK AT ICA COMPONENTS
%         cfg = [];
%         cfg.viewmode = 'component';
%         % cfg.component = 1:31;
%         cfg.layout='easycapM1';% acticap-64ch-standard2.mat
%         ft_databrowser(cfg,comp);
        
        % select the ones you want to remove
        addition  = input('fill in with noisy component: ');
        eog = [];% Eog component
        [data_tapping,added,zs] = component_rejection(data_tapping, comp, comp.fsample, 0.95, addition, eog);
        datacomp.rej_comp=data_tapping.rej_comp';

        %% ----------------------------------%
        %   REMOVE REMAINING BAD EPOCHS      %
        %------------------------------------%
        cfg = [];
        cfg.reref         = 'yes';             % We want to rereference our data
        cfg.refchannel    = {'all', '-VEOG', '-HEOG'};             % Here we specify our reference channels; all = common reference
        cfg.refmethod     = 'avg';
        data_tapping      = ft_preprocessing(cfg, data_tapping);
        
        cfg = [];
        cfg.viewmode = 'butterfly';
        cfg = ft_databrowser(cfg, data_tapping); %exit the browser by pressing 'q
        cfg.artfctdef.reject = 'complete';
        data_tapping = ft_rejectartifact(cfg, data_tapping);
        data_emg = ft_rejectartifact(cfg, data_emg);
        % append the EEG and EMG
        cfg = [];
        data_tapping = ft_appenddata(cfg, data_tapping, data_emg);
        %% ------------------------%
        %   SAVE                   %
        %--------------------------%
        mkdir(outputdir);
        filename1 =fullfile(outputdir,[filename(1:end-4) '_clean_task']);
        save(filename1, 'data_tapping');
        clear data_tapping data filename event nameinput input
    end
end