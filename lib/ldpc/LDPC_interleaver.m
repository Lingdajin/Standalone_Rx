function [ inter_bits ] = LDPC_interleaver( bufferbits,ModuOrder )
%bit interleaver
%  row-write and column-read

l = length(bufferbits);
r = ModuOrder;
c = ceil(l/r);
% if c*r > l
%     bufferbits = [bufferbits zeros(1,c*r-l)];
% end
for i = 1 : r
    interleaver(i,:) = bufferbits((i-1)*c+1: i*c);
end
for j = 1 : c
    inter_bits((j-1)*r+1:j*r) = interleaver(:,j);
end

end

