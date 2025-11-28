% For multicomparison
% Based on: https://www.fieldtriptoolbox.org/workshop/madrid2019/tutorial_stats/
clear all;
close all;
clc;
warning off;

restoredefaultpath;
if ismac
    addpath('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH/08_Code_book_variables/EEG/03_TFR/');
    addpath('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH/08_Code_book_variables/toolbox/fieldtrip-20171217/');
else
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\EEG\03_TFR\'); % Add the path of the current script
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\toolbox\fieldtrip-20171217\'); % Add the path of the Fieldtrip toolbox
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\toolbox\fieldtrip-20171217\statfun\');
end
% ft_defaults;

% Parameters
subjects = {'p7','p8','p9','p10','p11','p12','p13','p14','p15','p16','p17',...
    'p18','p19','p20','p21','p22','p25','p26'};
sessions = {'A_1_s1','A_15_s1','A_2_s1',...
    'A_5_s1','I_2_s1','I_5_s1','S_2_s1','S_5_s1'};
COI  = {'C1' 'CP1' 'CP13' 'CP5' 'C5' 'FC5' 'FC3' 'FC1'};
% COI  = {'C1'};
toi      = [0 0.3]; % relative to the end point of stimulation
foi      = [15 20];
BaseLine = [2.3 2.4]; % relative to the end point of stimulation [2.5 2.8]
Baselinetype = 'db';
cmp_norm = 7; % condtision number used to normalize the spectrum, 0: no norm

%% =======================================================
%           Load data
%  =======================================================
for k = 1:length(sessions)
    eval(append('cmp',string(k),' = sessions{',string(k),'}([1 3:end-3]);'))
end

for sb = 1:length(subjects)
    subj = subjects(sb)
    if ismac
        rootdir = append('/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH/09_Data_after_cleaning/',subj,'/freq/');;
        outdir = '/Volumes/fpn_rdm$/DM2334_IL_CLOSEDLOOP-PINCH/11_Final_products/TFR/';
        for k = 1:length(sessions)
            eval(append("ave_freq",string(k),"{sb} = load(string(append(rootdir, subj,'_',sessions{",string(k),"},'_freq.mat'))).freq_tap;"))
        end
    else
        rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\09_Data_after_cleaning\',subj,'\freq\'); % Add the path of the TF data: _freq.mat
        outdir = '\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\11_Final_products\TFR\';
        for k = 1:length(sessions)
            eval(append("ave_freq",string(k),"{sb} = load(string(append(rootdir, subj,'_',sessions{",string(k),"},'_freq.mat'))).freq_tap;"))
        end
    end
end

cfg = [];
cfg.keeptrials    = 'no';
for i = 1:length(subjects)
    for k = 1:length(sessions)
       eval(strcat('ave_freq', string(k), '{i}.time = ave_freq', string(k), '{i}.time - ave_freq', string(k), '{i}.time(1);')); 
    end
end

for k = 1:length(sessions)
    % Average over individuals
    eval(append('cfg = ave_freq',string(k)','{1}.cfg;'))
    cfg.keepindividual = 'yes';
    eval(append('[cmp',string(k),'_avg_bsl] = ft_freqgrandaverage(cfg, ave_freq',string(k),'{:});'))
    % Baseline if needed
    if ~isempty(BaseLine)
        cfg = [];
        cfg.baseline = BaseLine;
        cfg.baselinetype = Baselinetype;
        eval(append('cmp',string(k),'_avg_bsl = ft_freqbaseline(cfg, cmp',string(k),'_avg_bsl);'))
    end
end

% Normalized power spectra % https://www.fieldtriptoolbox.org/workshop/madrid2019/tutorial_freq/
freq_norm = foi; % frequency range used to normalize the spectrum
if (~isempty(freq_norm) && cmp_norm~=0)
    eval(append('foi_norm  = nearest(cmp',string(cmp_norm),'_avg_bsl.freq, freq_norm);'))
    eval(append('common_denominator = nanmean(cmp',string(cmp_norm),'_avg_bsl.powspctrm(:,:,foi_norm(1):foi_norm(2),:),3);'))
    for k = 1:length(sessions)
        eval(append('cmp',string(k),'_avg_bsl.powspctrm = bsxfun(@rdivide, cmp',string(k),'_avg_bsl.powspctrm, common_denominator);'))
    end
end

%% =======================================================
%  PSD
%  =======================================================
% COI  = COI;
% toi      = [0 0.3]; % relative to the end point of stimulation
% foi      = [15 30];
cfg = [];
cfg.channel     = COI;
cfg.avgoverchan = 'yes';
cfg.frequency   = foi;
cfg.avgoverfreq = 'yes';
cfg.parameter   = 'powspctrm';
cfg.latency     = toi;
cfg.avgovertime = 'yes';
cfg.nanmean     = 'yes';
for k = 1:length(sessions)
    eval(append('cmp',string(k),'_avg_bsl_ch = ft_selectdata(cfg, cmp',string(k),'_avg_bsl);'))
    eval(append('data_fROI{',string(k),'} = cmp',string(k),'_avg_bsl_ch.powspctrm'))
    eval(append('cmplabel{',string(k),'} = cmp',string(k),';'))
end
% plot
figure
plotSpread(data_fROI,[],[],cmplabel,4);
ylabel('abs. power (V^2)');
title('PSD');
% Save
cd(outdir);
writematrix(cell2mat(data_fROI), 'psd2.xlsx');

%% =======================================================
%  Topograph
%  =======================================================
cfg = [];
cfg.layout           = 'easycapM1';
cfg.parameter        = 'powspctrm'; % you can plot either powspctrm (default) or powspctrm_b
cfg.ylim = foi;
cfg.xlim = toi;
% cfg.zlim = [-10 10];
cfg.highlight        = 'on';
cfg.highlightchannel = COI;
cfg.highlightsymbol  = '*';
cfg.highlightcolor   = [0 0 0];
cfg.highlightsize    = 6;
cfg.markersymbol     = '.';
cfg.comment          = 'no';
cfg.colormap         = 'jet';
figure
for k = 1:length(sessions)
    subplot(2,4,k); 
    eval(append('ft_topoplotER(cfg, cmp',string(k),'_avg_bsl); colorbar; title(cmp',string(k),');'))
end

%% =======================================================
%  Log power spectra (High freq doesn't look good if the TOI is too small) 
%  Goes wierd with baseline method 
%  =======================================================
cfg = [];
cfg.channel     = COI;
cfg.avgoverchan = 'yes';
cfg.frequency   = 'all';
cfg.parameter   = 'powspctrm';
cfg.latency      = toi;
cfg.avgovertime = 'yes';
cfg.nanmean     = 'yes';
for k = 1:length(sessions)
    eval(append('cmp',string(k),'_avg_bsl_fq = ft_selectdata(cfg, cmp',string(k),'_avg_bsl);'))
end
figure
loglog(cmp5_avg_bsl_fq.freq,...
    [nanmean(squeeze(cmp1_avg_bsl_fq.(cfg.parameter)),1)'...
    nanmean(squeeze(cmp2_avg_bsl_fq.(cfg.parameter)),1)'...
    nanmean(squeeze(cmp3_avg_bsl_fq.(cfg.parameter)),1)']);
% xlim(foi);
% grid on; hold on;
% plot([10,10],[10^-3 10^2],'--k')
% ylim([10^-3 10^2]);
legend(cmp1,cmp2,cmp3);
xlabel('Frequency (Hz)');
ylabel(cfg.parameter);
title('2-second stimulation');

%% =======================================================
%  RM ANOVA
%  =======================================================
cfg = [];
cfg.channel          = 'all';
cfg.frequency        = foi;
cfg.parameter        = 'powspctrm';
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesFmultivariate';
cfg.correctm         = 'cluster'; % tfce
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum'; %'maxsum', 'maxsize', 'wcm'
cfg.clusterthreshold = 'nonparametric_common';
cfg.layout           = 'easycapM1';
cfg.minnbchan        = 2;
cfg.tail             = 1; % For a F-statistic, it only make sense to calculate the right tail
cfg.clustertail      = cfg.tail;
cfg.tfce_H           = 10;       % height threshold (signal intensity) 0.01
cfg.tfce_E           = 0.1;     % cluster extent 5
cfg.alpha            = 0.05;
cfg.computeprob      = 'yes';
cfg.numrandomization = 500;
cfg.neighbours       = [];
nsubj = length(subjects);
design = zeros(2,8*nsubj);
design(1,1:nsubj)           = 1;
design(1,nsubj+1:2*nsubj)   = 2;
design(1,nsubj*2+1:3*nsubj) = 3;
design(1,nsubj*3+1:4*nsubj) = 4;
design(1,nsubj*4+1:5*nsubj) = 5;
design(1,nsubj*5+1:6*nsubj) = 6;
design(1,nsubj*6+1:7*nsubj) = 7;
design(1,nsubj*7+1:8*nsubj) = 8;
design(2,:) = repmat(1:nsubj,1,8);
cfg.design   = design;
cfg.uvar     = 2; % subject
cfg.ivar     = 1; % independent variable 

stat1 = ft_freqstatistics(cfg, cmp1_avg_bsl, cmp2_avg_bsl, cmp3_avg_bsl, cmp4_avg_bsl, cmp5_avg_bsl,...
    cmp6_avg_bsl, cmp7_avg_bsl,cmp8_avg_bsl);

%% Plot ANOVA results
cfg            = [];
cfg.frequency  = foi;
cfg.avgoverrpt = 'yes';
cfg.layout     = 'easycapM1';
cfg.parameter  = 'powspctrm';
for k = 1:length(sessions)
    eval(append('cmp',string(k),'_avg_bsl_er = ft_selectdata(cfg, cmp',string(k),'_avg_bsl);'))
    eval(append('cmp',string(k),'_avg_bsl_er.mask = stat1.mask;')) % copy the mask field to each variable
end
cfg = [];
% cfg.zlim          = [0 90];
cfg.layout        = 'easycapM1';
% cfg.elec          = COI;
cfg.colorbar      = 'no';
cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
cfg.maskstyle     = 'box';
cfg.parameter     = 'mask';
cfg.maskfacealpha = 0.1;
cfg.parameter     = 'stat';
figure; 
ft_multiplotER(cfg,stat1);

figure;
cfg.xlim = toi;
cfg.ylim = foi;
cfg.highlight  = 'on'; % Highlight significant areas
cfg.highlightchannel = find(stat1.mask); % Channels showing significance
cfg.highlightsymbol  = 'x'; % Marker for significant points
cfg.highlightcolor   = [1 0 0]; % Red color for highlights
cfg.highlightsize    = 10; % Size of highlights
ft_topoplotTFR(cfg,stat1);

%% =======================================================
%  POST HOC COMPARE
%  =======================================================
condition1 = cmp1_avg_bsl;
condition2 = cmp2_avg_bsl;

cfg                  = [];
cfg.channel          = 'all';
cfg.latency          = [0 0.3];
cfg.frequency        = [10 40];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.alpha            = 0.05;
cfg.numrandomization = 500;
cfg.neighbours       = [];
cfg.clusteralpha     = 0.01;
cfg.tail             = 0; %(-1, 1, 0 onesided - twosided)
% tfce see https://www.fieldtriptoolbox.org/example/threshold_free_cluster_enhancement/
cfg.correctm         = 'tfce';
cfg.tfce_H           = 0.1;       % height threshold (signal intensity) 0.01
cfg.tfce_E           = 1;     % cluster extent 5
% % clustered based : https://www.fieldtriptoolbox.org/tutorial/cluster_permutation_freq/
% cfg.minnbchan        = 2;
% cfg.correctm         = 'cluster';
% cfg.clusteralpha     = 0.05;
% cfg.clusterstatistic = 'maxsum';
% cfg.clusterthreshold = 'nonparametric_individual';
% cfg.clustertail      = 0;

subj = length(subjects);
design = zeros(2,2*subj);
for i = 1:subj
    design(1,i) = i;
end
for i = 1:subj
    design(1,subj+i) = i;
end
design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;
cfg.design   = design;
cfg.uvar     = 1;
cfg.ivar     = 2;
[stat2] = ft_freqstatistics(cfg, condition1, condition2);

%%  t plot
Zlim = [-1 1];
cfg = [];
cfg.channel       = COI;
% cfg.zlim          = Zlim;
cfg.xlim          = toi;
cfg.ylim          = foi;
cfg.renderer      = 'painters';
cfg.colorbar      = 'yes';
cfg.parameter     = 'stat';
cfg.maskparameter = 'mask';
cfg.maskstyle     = 'outline';
cfg.alpha         = 0.05;
cfg.clusteralpha  = 0.05;
cfg.layout        = 'easycapM1';

figure
ft_singleplotTFR(cfg, stat2);
title(append('condition 1 vs condition 2'),'Interpreter', 'none');
%%
cfg.channel       = 'all';
figure
ft_topoplotTFR(cfg, stat2);
