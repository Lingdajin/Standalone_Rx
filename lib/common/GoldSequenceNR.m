function [ c_seq ] = GoldSequenceNR( c_init, seq_len )
% GoldSequenceNR: Generate Gold-31 pseudo-random sequence c(n) per TS 38.211 ¡ì5.2.1
% Input:
%      c_init  : decimal initialization value (0 ~ 2^31-1)
%      seq_len : desired length of output sequence c(0) ... c(seq_len-1)
% Output:
%      c_seq   : 1 x seq_len binary pseudo-random sequence

Nc = 1600;                       % shift of m-sequence
register_len = 31;               % length of LFSR registers
m_len = Nc + seq_len;            % total m-sequence length needed

m_seq1 = zeros(1, m_len);
m_seq2 = zeros(1, m_len);

% m-sequence 1: initial state [1, 0, ..., 0] (31 bits)
m_seq1(1) = 1;

% m-sequence 2: initial state from c_init (bits c_init(30:0) ¡ú register(0:30))
c_init_bin = dec2bin(c_init, register_len);
for i = 1:register_len
    m_seq2(i) = str2double(c_init_bin(register_len - i + 1));
end

% Generate both m-sequences: x(n+31) = (x(n+3) + x(n)) mod 2  (for m_seq1)
%                            x(n+31) = (x(n+3) + x(n+2) + x(n+1) + x(n)) mod 2 (for m_seq2)
for n = 1:(m_len - register_len)
    m_seq1(n + register_len) = mod(m_seq1(n + 3) + m_seq1(n), 2);
    m_seq2(n + register_len) = mod(m_seq2(n + 3) + m_seq2(n + 2) + m_seq2(n + 1) + m_seq2(n), 2);
end

% Gold sequence: c(n) = (m_seq1(n + Nc) + m_seq2(n + Nc)) mod 2
c_seq = zeros(1, seq_len);
for n = 1:seq_len
    c_seq(n) = mod(m_seq1(n + Nc) + m_seq2(n + Nc), 2);
end

end
