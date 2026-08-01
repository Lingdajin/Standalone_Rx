function tests = test_usable_frame_offsets
tests = functiontests(localfunctions);
end

function testNegativeFirstFrameStartIsKept(testCase)
slotLength = 100;
frameLength = 20 * slotLength;
dlMask = false(1, 20);
dlMask(3:5) = true;

offsets = PDSCH_UsableFrameOffsets([-150, 1850], 4200, slotLength, ...
    frameLength, dlMask, 0);

verifyEqual(testCase, offsets, [-150, 1850]);
end

function testTruncatedLastConfiguredSlotDropsFrame(testCase)
slotLength = 100;
frameLength = 20 * slotLength;
dlMask = false(1, 20);
dlMask(3:5) = true;

offsets = PDSCH_UsableFrameOffsets([-150, 1850], 2300, slotLength, ...
    frameLength, dlMask, 0);

verifyEqual(testCase, offsets, -150);
end

function testIncompleteFrameHeaderAndTailDoNotMatter(testCase)
slotLength = 100;
frameLength = 20 * slotLength;
dlMask = false(1, 20);
dlMask(3:5) = true;

offsets = PDSCH_UsableFrameOffsets([-150, 1850], 2350, slotLength, ...
    frameLength, dlMask, 0);

verifyEqual(testCase, offsets, [-150, 1850]);
end

function testConfiguredFrameLimitKeepsEarliestFrames(testCase)
slotLength = 100;
frameLength = 20 * slotLength;
dlMask = false(1, 20);
dlMask(3:5) = true;

offsets = PDSCH_UsableFrameOffsets([-150, 1850, 3850], 6200, slotLength, ...
    frameLength, dlMask, 2);

verifyEqual(testCase, offsets, [-150, 1850]);
end

function testDoesNotExtrapolateUndetectedFrames(testCase)
slotLength = 100;
frameLength = 20 * slotLength;
dlMask = false(1, 20);
dlMask(3:5) = true;

offsets = PDSCH_UsableFrameOffsets(1850, 6200, slotLength, ...
    frameLength, dlMask, 0);

verifyEqual(testCase, offsets, 1850);
end

function testDetectsSingleTXMainPeak(testCase)
offsets = 0:100:3000;
scores = zeros(size(offsets));
scores(offsets == 1000) = 1;
scores(offsets == 1900) = 0.069;

peakIndices = PDSCH_DetectFramePeaks(offsets, scores, 100e3);

verifyEqual(testCase, offsets(peakIndices), 1000);
end

function testDetectsThreeVsaPeaksAndRejectsTailSpike(testCase)
offsets = 0:100:4000;
scores = zeros(size(offsets));
scores(offsets == 500) = 1;
scores(offsets == 1500) = 0.905;
scores(offsets == 2500) = 0.769;
scores(offsets == 3500) = 0.203;

peakIndices = PDSCH_DetectFramePeaks(offsets, scores, 100e3);

verifyEqual(testCase, offsets(peakIndices), [500, 1500, 2500]);
end

function testSuppressesNearbySideLobe(testCase)
offsets = 0:100:2000;
scores = zeros(size(offsets));
scores(offsets == 1000) = 1;
scores(offsets == 1200) = 0.8;

peakIndices = PDSCH_DetectFramePeaks(offsets, scores, 100e3);

verifyEqual(testCase, offsets(peakIndices), 1000);
end
