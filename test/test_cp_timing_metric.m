function tests = test_cp_timing_metric
% TEST_CP_TIMING_METRIC CP相关定时度量回归测试。
tests = functiontests(localfunctions);
end

function testScoresTrueOfdmBoundaryHigherThanShiftedWindow(testCase)
rng(11);
fftSize = 16;
cpVec = [4, 3, 4];
slot = build_ofdm_slot(fftSize, cpVec);
signal = [zeros(1, 7), slot, zeros(1, 9)];

trueMetric = cp_timing_metric(signal, 7, fftSize, cpVec);
shiftedMetric = cp_timing_metric(signal, 10, fftSize, cpVec);

verifyGreaterThan(testCase, trueMetric, 0.99);
verifyLessThan(testCase, shiftedMetric, trueMetric);
end

function testVectorOffsetsAndMultipleAntennas(testCase)
rng(23);
fftSize = 32;
cpVec = [6, 5, 5, 6];
slot = build_ofdm_slot(fftSize, cpVec);
channelGains = [1; 0.3+0.8j; -1.5j];
multiAntennaSlot = channelGains * slot;
trueOffset = 19;
signal = [zeros(3, trueOffset), multiAntennaSlot, zeros(3, 31)];
offsets = trueOffset-3:trueOffset+3;

[metrics, cache] = cp_timing_metric(signal, offsets, fftSize, cpVec);
cachedMetrics = cp_timing_metric(signal, offsets, fftSize, cpVec, cache);

verifySize(testCase, metrics, size(offsets));
verifyEqual(testCase, metrics(4), 1, 'AbsTol', 1e-12);
verifyGreaterThan(testCase, metrics(4), max(metrics([1:3, 5:7])));
verifyEqual(testCase, cachedMetrics, metrics, 'AbsTol', 1e-12);
end

function slot = build_ofdm_slot(fftSize, cpVec)
slot = [];
for symbolIndex = 1:numel(cpVec)
    useful = randn(1, fftSize) + 1j * randn(1, fftSize);
    cpLength = cpVec(symbolIndex);
    slot = [slot, useful(end-cpLength+1:end), useful]; %#ok<AGROW>
end
end
