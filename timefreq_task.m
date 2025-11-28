restoredefaultpath;
if ismac
addpath('');
else
 addpath('C:\Users\User\Documents\MATLAB\Zhou_participants\p16\');
 addpath 'C:\Users\User\Documents\MATLAB\Zhou_code\fieldtrip-20171217';
end
% Wavelet
clear all;
close all;
clc;
warning off;
% subjects = {'P16','P17','P18','P20','P23','P24','P25',...
% 'P26','P27','P28','P29','P30','P31','P33','P34','P35',...
% 'P36','P37','P38','P39','P40','P41','P42','P43','P44','P45',...
% 'P46','P47','P48','P54','P55','P56','P57',...
% 'P58','P60','P61'}; % for batch processing
% sessions = {'_A_2_s1', '_A_2_s2', '_I_2_s1', '_S_2_s1'}; % for batch processing
% sessions = {'_A_1_s1', '_A_1_s2'}; % for batch processing
% sessions = {'_A_15_s1', '_A_15_s2'};
% sessions = {'_A_5_s1', '_A_5_s2','_I_5_s1','_S_5_s1'};
subjects = {'p16'};
sessions = {'_A_2_s1'}; % for batch processing
st = ''; % '': stimulated data (using for 'comp_freq.m');
% '_nostim': sham data (using for 'com_freq_nostim.m');
% '_tr': keep trials (using for 'prepost_trial_individual')
for sb = 1:length(subjects)
for ss = 1:length(sessions)
close all;
subj = subjects{sb}
if ismac
rootdir = append('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/09_Data_after_cleaning/closedloop/EEG/',subj,'/stim/');
outdir = append('/Volumes/fpn_rdm$/DM2186_IL_ClosedLoop/09_Data_after_cleaning/closedloop/EEG/', subj,'/freq/');
else
outdir = append ('C:\Users\User\Documents\MATLAB\Zhou_participants\p16\');
rootdir=append('C:\Users\User\Documents\MATLAB\Zhou_participants\p16\');
end
sess = sessions{ss}
load(append(rootdir,subj,sess,'_clean_task',st,'.mat'));
filename = append(subj, sess);
% cfg = [];
% cfg.viewmode = 'butterfly';
% ft_databrowser(cfg, data_tapping); %exit the browser by pressing 'q
%% --------------------------%
% WAVELET %
% https://www.fieldtriptoolbox.org/tutorial/timefrequencyanalysis/
%--------------------------%
cfg = [];
cfg.output = 'pow';
cfg.foi = 1:0.5:45; % Frequency range of interest
cfg.toi = 2.1:0.02:4.9; % For all conditions %change with condition: [n+0.1 n+2.9]
cfg.method = 'wavelet';
cfg.width = 6; % Wavelet width (in number of cycles)
cfg.keeptrials = 'no';
cfg.channel = 'all'; % or specify the relevant channel(s)
freq_tap = ft_freqanalysis(cfg, data_tapping);
%% visualize
figure
cfg = [];
cfg.channel = 'CP1';
cfg.baseline = [4.0 4.2]; %change with condition: [n+2.0 n+2.2]
cfg.zlim = [-0.5 0.5];
cfg.layout = 'acticap-64ch-standard2.mat';
cfg.baselinetype = 'relchange';
ft_singleplotTFR(cfg, freq_tap);
%% visualize
cfg = [];
cfg.baseline = [4.0 4.2]; %change with condition: [n+2.0 n+2.2]
cfg.channel = 'all';
cfg.baselinetype = 'relchange';
% cfg.zlim = [-0.5 0.5];
  cfg.ylim = [18 22];
  cfg.xlim = [2.1 2.5]; %change with condition: [n+0.1 n+0.5]
cfg.marker = 'on';
cfg.layout = 'acticap-64ch-standard2.mat';
cfg.colorbar = 'yes';
figure
ft_topoplotTFR(cfg, freq_tap);
%% mkdir(outdir);
filename2 =fullfile(outdir,[filename '_freq' st]);
save(filename2, 'freq_tap');
end
end