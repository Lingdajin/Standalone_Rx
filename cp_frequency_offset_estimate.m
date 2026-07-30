function [frequencyOffsetHz, quality, statistics] = cp_frequency_offset_estimate(...
    signal, slotOffsets, fftSize, cpLengths, sampleRate)
% CP_FREQUENCY_OFFSET_ESTIMATE Estimate common CFO from cyclic prefixes.
% slotOffsets are zero-based. The second half of every CP is correlated
% with the matching end of the OFDM symbol to reduce multipath transients.

if size(signal, 2) <= fftSize
    error('cp_frequency_offset_estimate:SignalTooShort', ...
        'Signal length must exceed the FFT size.');
end
if isempty(slotOffsets)
    error('cp_frequency_offset_estimate:NoSlots', ...
        'At least one slot offset is required.');
end

correlations = [];
leadingEnergy = [];
trailingEnergy = [];
numSamples = size(signal, 2);

for slotOffset = slotOffsets(:).'
    symbolOffset = 0;
    for symbolIndex = 1:numel(cpLengths)
        cpLength = cpLengths(symbolIndex);
        useRange = floor(cpLength / 2) + 1 : cpLength;
        leadingIndices = slotOffset + symbolOffset + useRange - 1;
        trailingIndices = leadingIndices + fftSize;
        if leadingIndices(1) < 0 || trailingIndices(end) >= numSamples
            symbolOffset = symbolOffset + cpLength + fftSize;
            continue;
        end

        leading = signal(:, leadingIndices + 1);
        trailing = signal(:, trailingIndices + 1);
        correlations(end+1) = sum(leading .* conj(trailing), 'all'); %#ok<AGROW>
        leadingEnergy(end+1) = sum(abs(leading).^2, 'all'); %#ok<AGROW>
        trailingEnergy(end+1) = sum(abs(trailing).^2, 'all'); %#ok<AGROW>
        symbolOffset = symbolOffset + cpLength + fftSize;
    end
end

if isempty(correlations) || all(abs(correlations) == 0)
    error('cp_frequency_offset_estimate:NoValidCorrelation', ...
        'No nonzero CP correlations were available for CFO estimation.');
end

combinedCorrelation = sum(correlations);
frequencyScale = sampleRate / (2 * pi * fftSize);
frequencyOffsetHz = -angle(combinedCorrelation) * frequencyScale;
quality = abs(combinedCorrelation) / ...
    sqrt(sum(leadingEnergy) * sum(trailingEnergy) + eps);

perSymbolHz = -angle(correlations) * frequencyScale;
weights = abs(correlations);
unambiguousRangeHz = sampleRate / (2 * fftSize);
residualHz = mod(perSymbolHz - frequencyOffsetHz + unambiguousRangeHz, ...
    2 * unambiguousRangeHz) - unambiguousRangeHz;

statistics.numSymbols = numel(correlations);
statistics.perSymbolMedianHz = median(perSymbolHz);
statistics.weightedStdHz = sqrt(sum(weights .* residualHz.^2) / sum(weights));
statistics.unambiguousRangeHz = unambiguousRangeHz;
end
