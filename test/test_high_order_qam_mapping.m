function tests = test_high_order_qam_mapping
tests = functiontests(localfunctions);
end

function test256QamUsesInterleavedNrBitLabels(testCase)
% b0,b2,b4,b6 label I; b1,b3,b5,b7 label Q (TS 38.211 5.1.6).
bits = zeros(1, 8);
symbol = modulation36211(bits, 256);

verifyEqual(testCase, symbol, (5 + 5i) / sqrt(170), 'AbsTol', 1e-12);
verifyEqual(testCase, newsoft_demodulation36211(symbol, 256, 1) < 0, ...
    logical(bits));
end

function test1024QamUsesInterleavedNrBitLabels(testCase)
bits = zeros(1, 10);
symbol = modulation36211(bits, 1024);

verifyEqual(testCase, symbol, (11 + 11i) / sqrt(682), 'AbsTol', 1e-12);
verifyEqual(testCase, newsoft_demodulation36211(symbol, 1024, 1) < 0, ...
    logical(bits));
end

function testAll256QamLabelsRoundTrip(testCase)
bits = de2bi(0:255, 8, 'left-msb').';
bits = bits(:).';
symbols = modulation36211(bits, 256);
decoded = newsoft_demodulation36211(symbols, 256, 1) < 0;

verifyEqual(testCase, decoded, logical(bits));
end

function testAll1024QamLabelsRoundTrip(testCase)
bits = de2bi(0:1023, 10, 'left-msb').';
bits = bits(:).';
symbols = modulation36211(bits, 1024);
decoded = newsoft_demodulation36211(symbols, 1024, 1) < 0;

verifyEqual(testCase, decoded, logical(bits));
end
