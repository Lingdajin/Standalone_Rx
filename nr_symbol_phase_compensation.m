function phase_comp = nr_symbol_phase_compensation( ...
    carrier_frequency, sample_rate, fft_size, cp_lengths, slot_index)
%NR_SYMBOL_PHASE_COMPENSATION NR transmit phase compensation per OFDM symbol.
%   The returned coefficients follow TS 38.211 Section 5.3.1. The receiver
%   removes the compensation by multiplying each symbol by their conjugates.

arguments
    carrier_frequency (1,1) double {mustBeFinite}
    sample_rate (1,1) double {mustBeFinite, mustBePositive}
    fft_size (1,1) double {mustBeInteger, mustBePositive}
    cp_lengths (1,:) double {mustBeInteger, mustBeNonnegative}
    slot_index (1,1) double {mustBeInteger, mustBeNonnegative} = 0
end

symbol_count = numel(cp_lengths);
samples_before_symbol = [0, cumsum(fft_size + cp_lengths(1:end-1))];
samples_per_slot = fft_size * symbol_count + sum(cp_lengths);
useful_start_samples = slot_index * samples_per_slot + ...
    samples_before_symbol + cp_lengths;

% Only the carrier frequency modulo Fs affects phases at integer samples.
% Reducing it first avoids loss of precision for GHz carriers.
normalized_carrier = mod(carrier_frequency / sample_rate, 1);
phase_comp = exp(-1j * 2 * pi * normalized_carrier .* useful_start_samples);
end
