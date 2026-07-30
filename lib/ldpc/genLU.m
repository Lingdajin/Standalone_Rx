function [ press_L1, Length_L1,press_U1, Length_U1,press_H1, Length_H1,press_P, Length_P,...
    max_L1,max_U1,max_H1 ] = genLU( Hb,z )
% 产生编码所需的变量及矩阵

%% 生成校验矩阵
[mb,nb] = size(Hb);
P = eye(z);
H0 = num2cell(Hb);
H11=[];
for i=1:mb*nb
    j = cell2mat(H0(i));
    if j == -1
        P0 = zeros(z);
    else
        P0 = circshift(P,j,2);
    end
    H11{i}=P0;
end
H = cell2mat(reshape(H11,mb,nb));
%% LU分解
[row_H,col_H] = size(H);
[L1, U1, P] = LU_jia_opt(H);
H1 = H(:,1:col_H-row_H);
[press_L1, Length_L1] = press_matrix(L1);%% 保留位置
[press_U1, Length_U1] = press_matrix(U1);
[press_H1, Length_H1] = press_matrix(H1);
[press_P, Length_P] = press_matrix(P);
max_L1 = max(Length_L1);
max_U1 = max(Length_U1);
max_H1 = max(Length_H1);
end

