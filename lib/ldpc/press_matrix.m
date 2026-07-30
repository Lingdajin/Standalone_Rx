%%求出压缩后的矩阵
function [press_L1, Length_L1] = press_matrix(L1)
[row_L1, n] = size(L1);
col_L1 = max(sum(L1,2));
press_L1 = zeros(row_L1,col_L1);
Length_L1 = zeros(1,row_L1);
for i = 1:row_L1;
   posi = find(L1(i,:)==1);
   Length_L1(i) = length(posi);
   press_L1(i,1:length(posi)) = posi;
end
