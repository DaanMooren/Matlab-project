restoredefaultpath;
if ismac
    addpath('/Volumes/B/PINCH/08_Code_book_variables/EEG/03_TFR/');
    addpath('/Volumes/B/PINCH/08_Code_book_variables/toolbox/fieldtrip-20171217/');
else
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\EEG\03_TFR\'); % Add the path of the current script
    addpath('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\08_Code_book_variables\toolbox\fieldtrip-20171217\'); % Add the path of the Fieldtrip toolbox
end
% ft_defaults;

clear all;
close all;
clc;
warning off;

% Parameters
subjects = {'p10','p11','p12','p13','p14','p15','p16','p17','p18','p19'};
% subjects = {'p11'};

cmp1 = 'A_2_s1'; % select the condition 1
cmp2 = 'S_2_s1'; % select the condition 2
COI  = {'C1' 'CP1' 'CP13' 'CP5' 'C5' 'FC5' 'FC3' 'FC1'};
toi      = [0 0.5]; % relative to the end point of stimulation
foi      = [18 22];
BaseLine = [2.5 2.6]; % relative to the end point of stimulation 2.5-2.8

%% =======================================================
%           Load data
%  =======================================================
for sb = 1:length(subjects)
    subj = subjects(sb)
    if ismac
        rootdir = '';
        outdir = '\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\11_Final_products\TFR\';
        ave_freq1{sb} = load(string(append(rootdir, subj,'_',cmp1,'_freq.mat'))).freq_tap;
        ave_freq2{sb} = load(string(append(rootdir, subj,'_',cmp2,'_freq.mat'))).freq_tap;
    else
        rootdir = append('\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\09_Data_after_cleaning\',subj,'\freq\'); % Add the path of the TF data: _freq.mat
        ave_freq1{sb} = load(string(append(rootdir, subj,'_',cmp1,'_freq.mat'))).freq_tap;
        ave_freq2{sb} = load(string(append(rootdir, subj,'_',cmp2,'_freq.mat'))).freq_tap;
        outdir = '\\ca-um-nas201\fpn_rdm$\DM2334_IL_CLOSEDLOOP-PINCH\11_Final_products\TFR\';
    end
end

cfg = [];
cfg.keeptrials    = 'no';
% cfg.frequency     = foi;
for i = 1:length(ave_freq1)
    cfg.latency       = [ave_freq1{1, 1}.time(1) ave_freq1{1, 1}.time(1)+2.9];
    [ave_freq_cmp1{i}] = ft_freqdescriptives(cfg, ave_freq1{i});
    ave_freq_cmp1{i}.time = ave_freq_cmp1{i}.time - cfg.latency(1); % Reset the time stamps
    cfg.latency       = [ave_freq2{1, 1}.time(1) ave_freq2{1, 1}.time(1)+2.9];
    [ave_freq_cmp2{i}] = ft_freqdescriptives(cfg, ave_freq2{i});
    ave_freq_cmp2{i}.time = ave_freq_cmp2{i}.time - cfg.latency(1); % Reset the time stamps
    % subplot(6,2,i)
    % cfg = [];
    % ft_singleplotTFR(cfg,ave_freq_cmp1{i})  
end

cfg = ave_freq_cmp1{1}.cfg;
cfg.keepindividual = 'yes';
[cmp1_avg_bsl] = ft_freqgrandaverage(cfg, ave_freq_cmp1{:});
cfg = ave_freq_cmp2{1}.cfg;
cfg.keepindividual = 'yes';
[cmp2_avg_bsl] = ft_freqgrandaverage(cfg, ave_freq_cmp2{:});

%% baseline-correct the average:
if ~isempty(BaseLine)
    cfg = [];
    cfg.baseline = BaseLine;
    cfg.baselinetype = 'db';
    cmp1_avg_bsl = ft_freqbaseline(cfg, cmp1_avg_bsl);
    cmp2_avg_bsl = ft_freqbaseline(cfg, cmp2_avg_bsl);
end
% select channel
cfg = [];
% if strcmp(COI,'all')
cfg.avgoverchan = 'yes';
% else
cfg.channel = COI;
% end
cmp1_avg_bsl_ch = ft_selectdata(cfg, cmp1_avg_bsl);
cmp2_avg_bsl_ch = ft_selectdata(cfg, cmp2_avg_bsl);

%%  =======================================================
%           CALCULATE DIFF
%  =======================================================
cfg = [];
cfg.parameter    = 'powspctrm';
cfg.operation    = 'x1-x2';
TFR_diff = ft_math(cfg, cmp1_avg_bsl, cmp2_avg_bsl);

%% plot
% Zlim = [-1 1];
Xlim  = [0.1 1];
Ylim = [5 35];
figure;
% colormap(brewermap(256, '*RdYlBu')); % https://nl.mathworks.com/matlabcentral/fileexchange/45208-colorbrewer-attractive-and-distinctive-colormaps
set(gcf, 'Position',  [100, 100, 550, 850]);
meanpow = squeeze(mean(cmp1_avg_bsl_ch.powspctrm, 1));
sub1 = subplot(3,1,1);
colorbar(sub1,'Position',...
    [0.823,0.633,0.038,0.272]);
imagesc(cmp1_avg_bsl_ch.time, cmp1_avg_bsl_ch.freq, meanpow);
axis xy;
% caxis(Zlim);
xlim(Xlim);
ylim(Ylim);
title(cmp1,'Interpreter', 'none');
colorbar;

meanpow = squeeze(mean(cmp2_avg_bsl_ch.powspctrm, 1));
subplot(3,1,2);
imagesc(cmp2_avg_bsl_ch.time, cmp2_avg_bsl_ch.freq, meanpow);
axis xy;
% caxis(Zlim);
xlim(Xlim);
ylim(Ylim);
title(cmp2,'Interpreter', 'none');
colorbar;

% Save change
cd(outdir);
saveas(gcf, string(append(cmp1,'_',cmp2,'_tfr','.png')));
saveas(gcf, string(append(cmp1,'_',cmp2,'_tfr','.fig')));

% Diff
% Zlim             = [-2 2];
cfg              = [];
cfg.channel      = COI;
% cfg.zlim         = Zlim;
cfg.xlim = xlim;
cfg.ylim = ylim;
cfg.layout       = 'easycapM1';
subplot(3,1,3);
ft_singleplotTFR(cfg, TFR_diff);
title(append(cmp1,'-',cmp2),'Interpreter', 'none');

figure
cfg              = [];
cfg.layout       = 'easycapM1';
cfg.ylim = foi;
cfg.xlim = toi;
% cfg.zlim = Zlim;
subplot(1,3,1);
ft_topoplotTFR(cfg, cmp1_avg_bsl);
title(cmp1,'Interpreter', 'none');
subplot(1,3,2);
ft_topoplotTFR(cfg, cmp2_avg_bsl);
title(cmp2,'Interpreter', 'none');
subplot(1,3,3);
ft_topoplotTFR(cfg, TFR_diff);
title(append(cmp1,'-',cmp2),'Interpreter', 'none');

% Save change
cd(outdir);
% saveas(gcf, string(append(cmp1,'_',cmp2,'_topo','.png')));
% saveas(gcf, string(append(cmp1,'_',cmp2,'_topo','.fig')));
%% =======================================================
%  NON PARAMETRIC  CLUSTER IN TIME/FREQ in one channel
%  https://www.fieldtriptoolbox.org/tutorial/cluster_permutation_freq/
%  =======================================================
cfg = [];
cfg.channel = 'all';
cfg.latency          = [0.1 1];
cfg.frequency        = [10 40];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.alpha            = 0.05;
cfg.numrandomization = 1000;
cfg.neighbours       = [];
cfg.clusteralpha     = 0.01;
cfg.tail             = 0; %(-1, 1, 0 onesided - twosided)
% tfce see https://www.fieldtriptoolbox.org/example/threshold_free_cluster_enhancement/
cfg.correctm         = 'tfce';
cfg.tfce_H           = 0.01;       % height threshold (signal intensity) 0.01
cfg.tfce_E           = 5;     % cluster extent 5
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
[stat] = ft_freqstatistics(cfg, cmp1_avg_bsl, cmp2_avg_bsl);

% t plot
Zlim = [-1 1];
cfg = [];
cfg.channel       = COI;
% cfg.zlim          = Zlim;
% cfg.xlim          = toi;
% cfg.ylim          = foi;
cfg.renderer      = 'painters';
cfg.colorbar      = 'yes';
cfg.parameter     = 'stat';
cfg.maskparameter = 'mask';
cfg.maskstyle     = 'outline';
cfg.alpha         = 0.05;
cfg.clusteralpha  = 0.05;
cfg.layout        = 'easycapM11';

figure
ft_singleplotTFR(cfg, stat);
title(append(cmp1,'-',cmp2),'Interpreter', 'none');
%Save change
cd(outdir);
saveas(gcf, string(append(cmp1,'_',cmp2,'_statTfr','.png')));
saveas(gcf, string(append(cmp1,'_',cmp2,'_statTfr','.fig')));
%% 
cfg.channel       = 'all';
figure
ft_topoplotTFR(cfg, stat);
title(append(cmp1,'-',cmp2),'Interpreter', 'none');
% Save change
cd(outdir);
saveas(gcf, string(append(cmp1,'_',cmp2,'_statTopo','.png')));
saveas(gcf, string(append(cmp1,'_',cmp2,'_statTopo','.fig')));
