function descrambled = ldpc_descramble(llr, RNTI, nID, q)
%LDPC_DESCRAMBLE Apply the NR PDSCH scrambling sequence to soft bits.

sequence_length = numel(llr);
x1 = zeros(1, sequence_length + 1600);
x2 = zeros(1, sequence_length + 1600);
x1(1) = 1;

c_init = RNTI * 2^15 + nID + q * 2^14;
initial_bits = dec2bin(c_init, 31) - '0';
x2(1:31) = initial_bits(end:-1:1);

for index = 32:sequence_length + 1600
    x1(index) = xor(x1(index - 28), x1(index - 31));
    x2(index) = xor(xor(x2(index - 28), x2(index - 29)), ...
        xor(x2(index - 30), x2(index - 31)));
end

scrambling_bits = xor(x1(1601:1600 + sequence_length), ...
    x2(1601:1600 + sequence_length));
descrambled = reshape(llr, 1, []) .* (1 - 2 * scrambling_bits);
end
