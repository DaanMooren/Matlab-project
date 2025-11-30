% ======================================================================
%   Pre-processing for pre-/post-rest-EEG and EMG data
% ======================================================================
clear all;
close all;
clc;
warning off;

restoredefaultpath;
if ismac
    addpath('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/08_Code_book_variables/EEG/01_preprocessing');
else
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\EEG\01_preprocessing');
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\toolbox\fieldtrip-20171217\');
end

ft_defaults;

subjects = {'p7','p8','p9','p10','p11','p12','p13','p14','p15','p16','p17','p18','p19'};
sessions = {'_A_2_s1', '_A_2_s2', '_I_2_s1', '_S_2_s1','_A_1_s1', ...
    '_A_1_s2','_A_15_s1','_A_5_s1', '_A_5_s2','_I_5_s1','_S_5_s1',...
    '_A_15_s1','_A_5_s1', '_A_5_s2','_I_5_s1','_S_5_s1'}; % for batch processing pre/post rest EEG/EMG
load('easycapM1_neighb.mat');

for sb = 1:length(subjects)
    for ss = 1:length(sessions)
        subj = subjects{sb}
        if ismac
            rootdir = '';
            outputdir = '';
        else
            rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\07_Raw_data\',subj,'\'); % set the path to the participant folders
            outputdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\09_Data_after_cleaning\',subj,'\');
        end
        sess = sessions{ss}
        
        %% =======================================================
        %           LOAD DATA
        % ========================================================
        filename = append(subj, sess, '.eeg');
        cd(rootdir);
        cfg = [];
        cfg.dataset = filename;
        cfg.channel =   {'all', '-EMG','-TP10'};           % Indicate the channels we would like to read and/or exclude.
        if exist(filename, 'file')
            data_rest = ft_preprocessing(cfg);
        else
            fprintf('File %s does not exist. Skipping to the next.\n', filename);
            continue;
        end
%         % =======================================================
%         %           VIEW RAW DATA
%         % ========================================================
%         cfg = [];
%         cfg.viewmode = 'butterfly';
%         cfg = ft_databrowser(cfg, data_rest);
        
        %% =======================================================
        %           CUT DATA
        % ========================================================
        % Post EEG
        cfg = [];
        cfg.begsample = data_rest.sampleinfo(2) - 29 * data_rest.fsample;
        cfg.endsample = data_rest.sampleinfo(2);
        data_rest_post = ft_redefinetrial(cfg,data_rest);
        % Pre EEG
        cfg = [];
        cfg.begsample = 1;
        cfg.endsample = 1 * 30 * data_rest.fsample;
        data_rest_pre = ft_redefinetrial(cfg,data_rest);
        
        %% --------------------------%%%
        %%%   FILTER DATA            %%%
        %%%--------------------------%%%
        cfg = [];
        cfg.demean                 = 'yes';
        cfg.detrend                = 'yes';
        cfg.bpfilter               = 'yes';
        cfg.bpfreq                 = [1 100];
        cfg.dftfilter              = 'yes';
        cfg.bsfilter               = 'yes';
        cfg.bsfreq                 = [49 51];
        cfg.bsfilttype             = 'firws';
        data_rest_pre = ft_preprocessing(cfg, data_rest_pre);
        data_rest_post = ft_preprocessing(cfg, data_rest_post);

        artif.badchannel  = input('Write badchannels that you know: ');
        if ~isempty(artif.badchannel)
            cfg = [];
            cfg.badchannel     = artif.badchannel;
            cfg.method         = 'weighted';
            cfg.neighbours     = neighbours;
            data_rest_pre = ft_channelrepair(cfg,data_rest_pre);            
            data_rest_post = ft_channelrepair(cfg,data_rest_post);
            % Visualize the results of channel interpolation
            cfg = [];
            cfg.viewmode      = 'vertical';
            cfg.artifactalpha = 0.8;
            cfg.artfctdef.badchannel.artifact = artif.badchannel;
            ft_databrowser(cfg,data_rest_pre);
        end
        %%%--------------------------%%%
        %%%   EPOCH                  %%%
        %%%--------------------------%%%
        cfg.length    = 1;
        cfg.overlap   = 0;
        data_rest_pre = ft_redefinetrial(cfg, data_rest_pre);
        data_rest_post = ft_redefinetrial(cfg, data_rest_post);
        
        %% --------------------------%%%
        %     REFERENCE DATA         %%%
        %%%--------------------------%%%    
        % VEOG channel pre
        cfg              = [];
        cfg.channel      = {'VEOG1','VEOG2'};
        cfg.reref        = 'yes';
        cfg.implicitref  = []; % this is the default, we mention it here to be explicit
        cfg.refchannel   = 'VEOG2';
        VEOG             = ft_preprocessing(cfg, data_rest_pre);
        
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
        HEOG             = ft_preprocessing(cfg, data_rest_pre);
        
        % only keep one channel, and rename to eogh
        cfg              = [];
        cfg.channel      = 'HEOG1';
        HEOG             = ft_selectdata(cfg, HEOG);
        HEOG.label       = {'HEOG'};
        %We now discard these extra channels that were used as EOG from the data and add the bipolar-referenced EOGv and EOGh channels that we have just created:
        
        cfg = [];
        cfg.reref         = 'yes';             % We want to rereference our data
        cfg.refchannel    = {'TP9'};             % Here we specify our reference channels; all = common reference
        data_rest_pre = ft_preprocessing(cfg, data_rest_pre);
        
        cfg = [];
        cfg.channel       =  {'all','-TP9','-HEOG1','-HEOG2','-VEOG1','-VEOG2'};
        data_rest_pre        = ft_selectdata(cfg, data_rest_pre);
        
        % append the EOGH and EOGV channel to the 60 selected EEG channels
        cfg = [];
        data_rest_pre = ft_appenddata(cfg, data_rest_pre, VEOG, HEOG);
        
        % VEOG channel post
        cfg              = [];
        cfg.channel      = {'VEOG1','VEOG2'};
        cfg.reref        = 'yes';
        cfg.implicitref  = []; % this is the default, we mention it here to be explicit
        cfg.refchannel   = 'VEOG2';
        VEOG             = ft_preprocessing(cfg, data_rest_post);
        
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
        HEOG             = ft_preprocessing(cfg, data_rest_post);
        
        % only keep one channel, and rename to eogh
        cfg              = [];
        cfg.channel      = 'HEOG1';
        HEOG             = ft_selectdata(cfg, HEOG);
        HEOG.label       = {'HEOG'};
        %We now discard these extra channels that were used as EOG from the data and add the bipolar-referenced EOGv and EOGh channels that we have just created:
        
        cfg = [];
        cfg.reref         = 'yes';             % We want to rereference our data
        cfg.refchannel    = {'TP9'};             % Here we specify our reference channels; all = common reference
        data_rest_post = ft_preprocessing(cfg, data_rest_post);
        
        cfg = [];
        cfg.channel       =  {'all','-TP9','-HEOG1','-HEOG2','-VEOG1','-VEOG2'};
        data_rest_post        = ft_selectdata(cfg, data_rest_post);
        
        % append the EOGH and EOGV channel to the 60 selected EEG channels
        cfg = [];
        data_rest_post = ft_appenddata(cfg, data_rest_post, VEOG, HEOG);
        
        %% -----------------------
        %        RUN ICA
        % -----------------------
        cfgica = [];
        cfgica.method = 'runica';
        comp = ft_componentanalysis(cfgica,data_rest_pre);
        
        figure
        cfg = [];
        cfg.component = 1:31;       % specify the component(s) that should be plotted
        cfg.layout    = 'easycapM1'; % specify the layout file that should be used for plotting
        cfg.comment   = 'no';
        ft_topoplotIC(cfg, comp);
   
        % select the ones you want to remove
        addition  = input('fill in with noisy component: ');
        eog = [];% Eog component
        [data_rest_pre,added,zs] = component_rejection(data_rest_pre, comp, comp.fsample, 0.95, addition, eog);
        datacomp.rej_comp=data_rest_pre.rej_comp';
        
        clear comp addtion eog
        close 
        
        cfgica = [];
        cfgica.method = 'runica';
        comp = ft_componentanalysis(cfgica,data_rest_post);
        
        figure
        cfg = [];
        cfg.component = 1:31;       % specify the component(s) that should be plotted
        cfg.layout    = 'easycapM1'; % specify the layout file that should be used for plotting
        cfg.comment   = 'no';
        ft_topoplotIC(cfg, comp);
   
        % select the ones you want to remove
        addition  = input('fill in with noisy component: ');
        eog = [];% Eog component
        [data_rest_post,added,zs] = component_rejection(data_rest_post, comp, comp.fsample, 0.95, addition, eog);
        datacomp.rej_comp=data_rest_post.rej_comp';
        close 
        %--------------------------%
        %   REMOVE BAD EPOCHS PRE  %
        %--------------------------%
        cfg = [];
        cfg.viewmode = 'butterfly';
        cfg = ft_databrowser(cfg, data_rest_pre); %exit the browser by pressing 'q
        cfg.artfctdef.reject = 'complete';
        data_rest_pre = ft_rejectartifact(cfg, data_rest_pre);

        %--------------------------%
        %   SAVE PRE               %
        %--------------------------%
        % mkdir(outputdir);
        filename2 =fullfile(outputdir,[filename(1:end-4) '_pre_clean_rest']);
        save(filename2, 'data_rest_pre');
         
        %--------------------------%
        %   REMOVE BAD EPOCHS      %
        %--------------------------%
        cfg = [];
        cfg.viewmode = 'butterfly';
        cfg = ft_databrowser(cfg, data_rest_post); %exit the browser by pressing 'q
        cfg.artfctdef.reject = 'complete';
        data_rest_post = ft_rejectartifact(cfg, data_rest_post);

        %--------------------------%
        %   SAVE POST              %
        %--------------------------%

        filename2 =fullfile(outputdir,[filename(1:end-4) '_post_clean_rest']);
        save(filename2, 'data_rest_post');
        
        clear comp data_tapping data var_eeg rem_chan data components
    end
end