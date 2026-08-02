function x_scramble = scrambling(x, RNTI, nID, q)
%scrambling NR PDSCH scrambling (for re-encoding in EVM calculation).
%   x_scramble = scrambling(x, RNTI, nID, q)
%   x     - input binary bits (0/1)
%   RNTI  - RNTI (typically 1 for PDSCH)
%   nID   - data scrambling identity N_ID
%   q     - codeword index (0 or 1)

n = length(x);  % input sequence length

% Generate first m-sequence x1
x1 = zeros(1, n + 1600);
x1(1) = 1;

% Generate second m-sequence x2 from c_init
c_init = RNTI * 2^15 + nID + q * 2^14;
initial_bits = dec2bin(c_init, 31) - '0';
x2 = zeros(1, n + 1600);
x2(1:31) = initial_bits(end:-1:1);

%通过不断迭代，扩展产生相应长度的m序列x1，x2
for j=32:n+1600
    x1(j)=xor(x1(j-28),x1(j-31));
    x2(j)=xor(xor(x2(j-28),x2(j-29)),xor(x2(j-30),x2(j-31)));   
end

c(1:n)=xor(x1(1601:1600+n),x2(1601:1600+n));  %产生加扰序列
x_scramble=xor(x,c);  %经过加扰操作后的序列