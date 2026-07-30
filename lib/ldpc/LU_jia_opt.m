function [L1, U1, P] = LU_jia_opt(H)
%LDPC编码
%LU分解
[m,n]=size(H);
K=n-m;
H_matrix=H(:,K+1:n);
%% LU分解
L1 = zeros(m,m);
U1 = zeros(m,m);
P = eye(m,m);
for i=1:m
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% method 1
%         col_1 = find(H_matrix(i,i:m)==1,1);
%         col_1 = col_1+i-1;
%         posi_col = col_1;
    %% method 2
    col_1 = find(H_matrix(i,i:m)==1);
    col_1 = col_1+i-1;
    colweight = sum(H_matrix(:,col_1), 1);
    posi_col = col_1(find(colweight == min(colweight),1));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    if posi_col~=i
        mid_col = H_matrix(:,posi_col);
        H_matrix(:,posi_col) = H_matrix(:,i);
        H_matrix(:,i) = mid_col;
        mid_row_P = P(posi_col,:);
        P(posi_col,:) = P(i,:);
        P(i,:) = mid_row_P;
    end
    L1(i:end, i) = H_matrix(i:end, i);
    U1(1:i, i) = H_matrix(1:i, i);
    if i<m
        posi_row = find(H_matrix((i + 1):end, i)==1)+i;          
        H_matrix(posi_row, :) = mod(H_matrix(posi_row, :) + repmat(H_matrix(i, :), length(posi_row), 1), 2);
    end
end



