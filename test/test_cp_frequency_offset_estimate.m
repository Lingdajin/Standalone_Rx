function tests = test_cp_frequency_offset_estimate
tests = functiontests(localfunctions);
end

function testEstimatesCommonOffsetAcrossMultipleAntennas(testCase)
rng(59);
fftSize = 128;
cpLengths = [12, 9, 9, 9];
numSlots = 5;
slotLength = numel(cpLengths) * fftSize + sum(cpLengths);
slot = zeros(1, slotLength);
writeIndex = 1;
for symbolIndex = 1:numel(cpLengths)
    useful = randn(1, fftSize) + 1j * randn(1, fftSize);
    cpLength = cpLengths(symbolIndex);
    block = [useful(end-cpLength+1:end), useful];
    slot(writeIndex:writeIndex+numel(block)-1) = block;
    writeIndex = writeIndex + numel(block);
end

baseSignal = repmat(slot, 1, numSlots);
antennaGains = [1; 0.4+0.8j; -0.7j];
signal = antennaGains * baseSignal;
sampleRate = 3.84e6;
expectedHz = 875;
time = (0:size(signal, 2)-1) / sampleRate;
signal = signal .* exp(1j * 2*pi*expectedHz*time);
signal = signal + 1e-3 * (randn(size(signal)) + 1j*randn(size(signal)));
slotOffsets = (0:numSlots-1) * slotLength;

[actualHz, quality, statistics] = cp_frequency_offset_estimate(...
    signal, slotOffsets, fftSize, cpLengths, sampleRate);

verifyEqual(testCase, actualHz, expectedHz, 'AbsTol', 2);
verifyGreaterThan(testCase, quality, 0.99);
verifyEqual(testCase, statistics.numSymbols, numSlots*numel(cpLengths));
end
