Perf_Cal_StimOn.m – Behavioural Performance Analysis During Stimulation
This script calculates motor performance during the stimulation interval, using the isometric pinching force measured from the force sensor.
Imports raw force data for each trial.
1. Low-pass filters the force trace (removing >20 Hz noise).
2. Baseline-corrects the signal relative to pre-stim periods.
3. Calculates integrated force or force stability within 1–1.25% of MVC.
4. Outputs trial-level summaries for ANOVA

com_freq_v2_Proper.m – Cortico-Muscular Coherence (CMC) and Spectral Analysis
Computes cortico-muscular coherence (CMC) between EEG signals (C3 ROI and surrounding channels) and rectified EMG of the first dorsal interosseous during the post-stimulation interval.
1. Preprocesses EEG: band-pass (1–100 Hz), notch at 50 Hz.
2. Preprocesses EMG: 1–100 Hz filter + rectification.
3. Computes auto- and cross-spectral densities.
4. Computes magnitude-squared coherence:
5. Extracts coherence at IBF ± 1 Hz.
6. Formats output for rmANOVA and topographical visualization.

eeg_task_stim.m – Preprocessing Task-Related EEG and Epoch Extraction
Handles all EEG preprocessing during the stimulation intervals and extracts trial epochs aligned to stimulation offset.
1. Load raw EEG during the isometric contraction task.
2. Re-reference (average or Laplacian, depending on the stage).
3. Band-pass filter (1–100 Hz).
4. ICA for removing ocular/muscle artefacts.
5. Segment into epochs time-locked to the stimulation endpoint (0–3 s).
6. Reject trials marked by artefacts.
7. Output the clean epoched data for time-frequency analysis.

multicom_freq.m – Multi-Condition Frequency Analysis
Provides a batch-level frequency analysis across all stimulation conditions (A1, A15, A2, A5, I2, I5, S2, S5).
1. Loops over all stimulation conditions.
2. Loads EEG spectra for each condition.
3. Applies log-transform and 1/f correction.
4. Fits Gaussian curves to estimate peak beta power.
5. Extracts spectral features for statistical analysis.

timefreq_task.m – Time-Frequency Decomposition (Morlet Wavelets)
Computes time-frequency representations (TFRs) to assess how beta power evolves immediately after stimulation offset.
1. Takes preprocessed task EEG data.
2. Performs Morlet wavelet decomposition (1–45 Hz).
3. Extracts power time courses for IBF and beta band.
4. Normalizes TFR using S2 (2-s sham condition).
5. Outputs single-channel CP1 plots + topographical beta maps.
