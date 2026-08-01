function tests = test_nr_symbol_phase_compensation
tests = functiontests(localfunctions);
end

function testFormulaUsesUsefulSymbolStart(testCase)
sampleRate = 122.88e6;
carrierFrequency = 3.5e9;
fftSize = 4096;
cpLengths = [320, 288 * ones(1, 6), 320, 288 * ones(1, 6)];
slotIndex = 4;

actual = nr_symbol_phase_compensation( ...
    carrierFrequency, sampleRate, fftSize, cpLengths, slotIndex);
samplesPerSlot = fftSize * numel(cpLengths) + sum(cpLengths);
usefulStart = slotIndex * samplesPerSlot + ...
    [0, cumsum(fftSize + cpLengths(1:end-1))] + cpLengths;
expected = exp(-1j * 2 * pi * carrierFrequency .* usefulStart / sampleRate);

verifyEqual(testCase, actual, expected, 'AbsTol', 2e-7);
end

function testDemodulatorRemovesTransmitCompensation(testCase)
rng(17);
fftSize = 32;
cpLengths = [4, 3, 3];
symbolCount = numel(cpLengths);
sampleRate = 960e3;
carrierFrequency = 3.5e9;
phaseComp = nr_symbol_phase_compensation( ...
    carrierFrequency, sampleRate, fftSize, cpLengths, 7);

expectedGrid = randn(fftSize, symbolCount) + ...
    1j * randn(fftSize, symbolCount);
waveform = complex(zeros(1, fftSize * symbolCount + sum(cpLengths)));
writeIndex = 1;
for symbolIndex = 1:symbolCount
    useful = ifft(ifftshift(expectedGrid(:, symbolIndex))) * sqrt(fftSize);
    useful = useful * phaseComp(symbolIndex);
    symbol = [useful(end-cpLengths(symbolIndex)+1:end); useful];
    waveform(writeIndex:writeIndex + numel(symbol) - 1) = symbol;
    writeIndex = writeIndex + numel(symbol);
end

actualGrid = OFDM_DeModulater( ...
    waveform, fftSize, cpLengths, fftSize + cpLengths(1), ...
    1, symbolCount, phaseComp);
actualGrid = squeeze(actualGrid(1, :, :));

verifyEqual(testCase, actualGrid, expectedGrid, 'AbsTol', 1e-11);
end
