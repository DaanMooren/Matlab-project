restoredefaultpath;

if ismac
    %addpath('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/08_Code_book_variables/EEG/01_preprocessing');
else
    addpath('D:\PhD_project_Zhou_Fang\data\');
    addpath 'D:\PhD_project_Zhou_Fang\code\fieldtrip-20171217';
end

% ======================================================================
%                       EEG with tACS stim
% ======================================================================

clear all;
close all;
clc;
warning off;
%
% subjects = {'P16','P17','P18','P20','P23','P24','P25',...
%             'P26','P27','P28','P29','P30','P31','P33','P34','P35',...
%             'P36','P37','P38','P39','P40','P41','P42','P43','P44','P45',...
%             'P46','P47','P48','P52','P53','P54','P55','P56','P57',...
%             'P58','P59','P60','P61'}; % for batch processing
ft_defaults;
subjects = {'p3'};
sessions = {'_S_5_s1'}; % for batch processing
prestim = -5.1; %
poststim = -prestim+3.0;
load('easycapM1_neighb.mat');
for sb = 1:length(subjects)
    for ss = 1:length(sessions)
        subj = subjects{sb}
        if ismac
        else
            rootdir = append('D:\PhD_project_Zhou_Fang\data'); % set the path to the participant folders
            outputdir = append('D:\PhD_project_Zhou_Fang\data');
        end
        sess = sessions{ss}
        
        %% =======================================================
        %           LOAD DATA
        % ========================================================
        filename = append(subj, sess, '.eeg');
        cd([rootdir]);
        cfg = [];
        cfg.dataset = filename;
        cfg.channel                 =  {'all'};           % Indicate the channels we would like to read and/or exclude.
        data = ft_preprocessing(cfg);     
        
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
        %----------remove bad channels------------------------%
        cfg = [];
        cfg.viewmode = 'vertical';
        artif = ft_databrowser(cfg, data_tapping); %exit the browser by pressing 'q
        artif.badchannel  = input('write badchannels: ');
        
        if ~isempty(artif.badchannel)
            cfg = [];
            cfg.badchannel     = artif.badchannel;
            cfg.method         = 'weighted';
            cfg.neighbours     = neighbours;
            data_tapping = ft_channelrepair(cfg,data_tapping);
            % Visualize the results of channel interpolation
            cfg = [];
            cfg.viewmode      = 'vertical';
            cfg.artifactalpha = 0.8;
            cfg.artfctdef.badchannel.artifact = artif.badchannel;
            ft_databrowser(cfg,data_tapping);
        end
        
        %-----------EMG-------------------------
        cfg              = [];
        cfg.channel      =  {'EMG'};
        cfg.continuous   = 'yes';
        cfg.demean       = 'yes';
        cfg.dftfilter    = 'yes';
        cfg.bpfilter     = 'yes';
        cfg.bpfreq       = [1 100];
        cfg.rectify      = 'yes';
        data_emg = ft_preprocessing(cfg,data);
        
        %% --------------------------%%%
        %     REFERENCE DATA         %%%
        %%%--------------------------%%%
        cfg = [];
        cfg.reref         = 'yes';             % We want to rereference our data
        cfg.refchannel    = {'TP9'};             % Here we specify our reference channels; all = common reference
        data_tapping = ft_preprocessing(cfg, data_tapping);
        
        cfg = [];
        cfg.channel       =  {'all','-TP9'};
        data_tapping        = ft_selectdata(cfg, data_tapping);
        
        %% -----------------------
        %        RUN ICA
        % -----------------------
        cfgica = [];
        cfgica.method = 'runica';
        cfgica.outputfile = fullfile([outputdir,subj,sess,'_ica']);
        comp = ft_componentanalysis(cfgica,data_tapping);
        
        %% plot the components for visual inspection
        figure
        cfg = [];
        cfg.component = 1:33;       % specify the component(s) that should be plotted
        cfg.layout    = 'easycapM1'; % specify the layout file that should be used for plotting
        cfg.comment   = 'no';
        ft_topoplotIC(cfg, comp);
        %% LOOK AT ICA COMPONENTS
        cfg = [];
        cfg.viewmode = 'component';
        cfg.layout='easycapM1';% acticap-64ch-standard2.mat
        ft_databrowser(cfg,comp);
        %% select the ones you want to remove
        addition  = input('write muscle component: ');
        eog = input('write eog component: ');% Eog component
        [dataica,added,zs] = component_rejection(data_tapping, comp, comp.fsample, 0.95, addition, eog);
        datacomp.rej_comp=dataica.rej_comp';
        
        %% ----------------------------------%
        %   REMOVE REMAINING BAD EPOCHS      %
        %------------------------------------%
        cfg = [];
        cfg.viewmode = 'vertical';
        cfg = ft_databrowser(cfg, dataica); %exit the browser by pressing 'q
        cfg.artfctdef.reject = 'complete';
        data_tapping = ft_rejectartifact(cfg, dataica);
        % append the EEG and EMG
        cfg = [];
        data_tapping = ft_appenddata(cfg, data_tapping, data_emg);
        %% --------------------------%
        % SAVE %
        %--------------------------%
        mkdir(outputdir);
        filename1 =fullfile(outputdir,[filename(1:end-4) '_clean_task']);
        save(filename1, 'data_tapping');
        clear data_tapping data filename event nameinput input
    end
end