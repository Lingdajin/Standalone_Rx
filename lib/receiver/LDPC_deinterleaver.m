function [ deinter_bits ] = LDPC_deinterleaver( received_bits,ModuOrder )
%  deinterleaver
%  column-write and row-read

lo = length(received_bits);
r = ModuOrder;
c = lo/r;

for j = 1 : c
    deinterleaver(:,j) = received_bits((j-1)*r+1:j*r);
end
for i = 1 : r
    deinter_bits((i-1)*c+1:i*c) = deinterleaver(i,:);
end
% deinter_bits = deinter_bits(1:l);
end

