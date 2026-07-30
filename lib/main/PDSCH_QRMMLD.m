function [soft_value]=PDSCH_QRMMLD(H,Y,NoisePower)
%% Function Description:
% R-ML算法，QRM-MLD
% 利用信道矩阵的三角分解，降低ML的搜索复杂度
%% Input:
% H:Nr*Nt,complex channel transfer matrix
% Y:Nr*1,complex received signal
% NoisePower: noise power
%% Output:
% soft_value:1*(Nt*ml),soft information of every transmitted bit
%% Date:2018-11-05
global SystemParam TurboCodingRateMatchingParam LDPCCodingRateMatchingParam
if SystemParam.channel_code == 1
    modulation_mode = TurboCodingRateMatchingParam.modulation_mode;
else
    modulation_mode = LDPCCodingRateMatchingParam.modulation_mode;
end
mod_mode = 2^modulation_mode;

%各调制阶数对应的星座点，注意一定要与发送端调制星座图的顺序一致
switch mod_mode
    case 2
        constel_sym = [1+1i -1-1i]./sqrt(2);
    case 4
        constel_sym = [1+1i  1-1i  -1+1i   -1-1i]./sqrt(2);
    case 16
        constel_sym = [1 + 1i	1 + 3i	3 + 1i	3 + 3i ...
                       1 - 1i   1 - 3i	3 - 1i	3 - 3i ...
                       -1 + 1i  -1 + 3i	-3 + 1i	-3 + 3i	 ...
                       -1 - 1i  -1 - 3i	-3 - 1i	-3 - 3i]/sqrt(10);
    case 64
        constel_sym = [3 + 3i   3 + 1i   1 + 3i   1 + 1i   3 + 5i   3 + 7i   1 + 5i   1 + 7i ...
                       5 + 3i   5 + 1i   7 + 3i   7 + 1i   5 + 5i   5 + 7i   7 + 5i   7 + 7i ...
                       3 - 3i   3 - 1i   1 - 3i   1 - 1i   3 - 5i	3 - 7i   1 - 5i   1 - 7i ...
                       5 - 3i   5 - 1i   7 - 3i   7 - 1i   5 - 5i	5 - 7i	 7 - 5i   7 - 7i ...
                       -3 + 3i  -3 + 1i  -1 + 3i  -1 + 1i  -3 + 5i  -3 + 7i  -1 + 5i  -1 + 7i ...
                       -5 + 3i  -5 + 1i  -7 + 3i  -7 + 1i  -5 + 5i	-5 + 7i	 -7 + 5i  -7 + 7i ...
                       -3 - 3i  -3 - 1i  -1 - 3i  -1 - 1i  -3 - 5i	-3 - 7i	 -1 - 5i  -1 - 7i ...
                       -5 - 3i  -5 - 1i  -7 - 3i  -7 - 1i  -5 - 5i	-5 - 7i	 -7 - 5i  -7 - 7i]/sqrt(42);
    case 256
        constel_sym =  [-15-15i  -15-13i  -15-9i  -15-11i  -15-1i  -15-3i  -15-7i  -15-5i  -15+15i  -15+13i  -15+9i  -15+11i  -15+1i  -15+3i  -15+7i  -15+5i ...
                        -13-15i  -13-13i  -13-9i  -13-11i  -13-1i  -13-3i  -13-7i  -13-5i  -13+15i  -13+13i  -13+9i  -13+11i  -13+1i  -13+3i  -13+7i  -13+5i ...
                        -9-15i  -9-13i  -9-9i  -9-11i  -9-1i  -9-3i  -9-7i  -9-5i  -9+15i  -9+13i  -9+9i  -9+11i  -9+1i  -9+3i  -9+7i  -9+5i ...
                        -11-15i  -11-13i  -11-9i  -11-11i  -11-1i  -11-3i  -11-7i  -11-5i  -11+15i  -11+13i  -11+9i  -11+11i  -11+1i  -11+3i  -11+7i  -11+5i ...
                        -1-15i  -1-13i  -1-9i  -1-11i  -1-1i  -1-3i  -1-7i  -1-5i  -1+15i  -1+13i  -1+9i  -1+11i  -1+1i  -1+3i  -1+7i  -1+5i ...
                        -3-15i  -3-13i  -3-9i  -3-11i  -3-1i  -3-3i  -3-7i  -3-5i  -3+15i  -3+13i  -3+9i  -3+11i  -3+1i  -3+3i  -3+7i  -3+5i ...
                        -7-15i  -7-13i  -7-9i  -7-11i  -7-1i  -7-3i  -7-7i  -7-5i  -7+15i  -7+13i  -7+9i  -7+11i  -7+1i  -7+3i  -7+7i  -7+5i ...
                        -5-15i  -5-13i  -5-9i  -5-11i  -5-1i  -5-3i  -5-7i  -5-5i  -5+15i  -5+13i  -5+9i  -5+11i  -5+1i  -5+3i  -5+7i  -5+5i ...
                        15-15i  15-13i  15-9i  15-11i  15-1i  15-3i  15-7i  15-5i  15+15i  15+13i  15+9i  15+11i  15+1i  15+3i  15+7i  15+5i ...
                        13-15i  13-13i  13-9i  13-11i  13-1i  13-3i  13-7i  13-5i  13+15i  13+13i  13+9i  13+11i  13+1i  13+3i  13+7i  13+5i ...
                        9-15i  9-13i  9-9i  9-11i  9-1i  9-3i  9-7i  9-5i  9+15i  9+13i  9+9i  9+11i  9+1i  9+3i  9+7i  9+5i ...
                        11-15i  11-13i  11-9i  11-11i  11-1i  11-3i  11-7i  11-5i  11+15i  11+13i  11+9i  11+11i  11+1i  11+3i  11+7i  11+5i ...
                        1-15i  1-13i  1-9i  1-11i  1-1i  1-3i  1-7i  1-5i  1+15i  1+13i  1+9i  1+11i  1+1i  1+3i  1+7i  1+5i ...
                        3-15i  3-13i  3-9i  3-11i  3-1i  3-3i  3-7i  3-5i  3+15i  3+13i  3+9i  3+11i  3+1i  3+3i  3+7i  3+5i ...
                        7-15i  7-13i  7-9i  7-11i  7-1i  7-3i  7-7i  7-5i  7+15i  7+13i  7+9i  7+11i  7+1i  7+3i  7+7i  7+5i ...
                        5-15i  5-13i  5-9i  5-11i  5-1i  5-3i  5-7i  5-5i  5+15i  5+13i  5+9i  5+11i  5+1i  5+3i  5+7i  5+5i]/sqrt(170);
    otherwise
        disp('Wrong modulation_mode!');
end
M = length(constel_sym);    %前height-1层每层保留的节点数
nr = size(H,1);         %接收天线的数量
nt = size(H,2);         %发送天线的数量(或层数等)
height = min(nr,nt);    %树的层数
[Q,R] = qr(H);
Z = Q'*Y;
bit_sur = zeros(height,M*mod_mode*modulation_mode);     %M条幸存路径星座点对应的二进制比特矩阵
%% R-ML树遍历
if nr>=nt   %目前只支持nr>=nt场景
    %--------树的第一层，上三角矩阵非全零行的最后一行
    loop_tree = height;
    error_loop1=abs(repmat(Z(loop_tree),ones(1,mod_mode)) - R(loop_tree,loop_tree)*constel_sym).^2; %第一层所有的均方差
    [error_loop1,seq1]=sort(error_loop1);
    error_sur = error_loop1(1:M);
    constellation_sur(:,loop_tree) = constel_sym(seq1);     %按照误差模方从小到大保留前M个星座点
    con_num(:,loop_tree) =seq1-1;   %幸存星座点在星座图向量中的序号
    for ii = 1:modulation_mode
        bit_sur(loop_tree,modulation_mode-ii+1:modulation_mode:M*modulation_mode) = bitget(seq1-1,ii);  %幸存星座点对应的比特
    end
    
    %--------树的第二层到最后一层的搜索
    for loop_tree = height-1:-1:1
        pro_tmp = R(loop_tree,loop_tree:end) * cat(1,repmat(constel_sym,[1,M]),kron(constellation_sur(:,loop_tree+1:end).',ones(1,mod_mode)));  %R*x 对应的第loop_tree层
        error_loop = abs(repmat(Z(loop_tree),size(pro_tmp))- pro_tmp).^2 + kron(error_sur,ones(1,mod_mode));    %前loop_tree层的误差平方和
        if loop_tree == 1
            M = M*mod_mode;     %最后一层保留所有节点
        end
        [error_loop,seq]=sort(error_loop);
        error_sur = error_loop(1:M);
        seq = seq(1:M);     %引入本层误差后重新排序选择幸存路径
        constellation_sur(1:M,loop_tree+1:end) = constellation_sur(ceil(seq/length(constel_sym)),loop_tree+1:end);  %前loop_tree-1层
        constellation_sur(1:M,loop_tree) = constel_sym(mod(seq-1,length(constel_sym))+1);   %第loop_tree层
        con_num(1:M,loop_tree+1:end) = con_num(ceil(seq/length(constel_sym)),loop_tree+1:end);
        con_num(1:M,loop_tree) = mod(seq-1,length(constel_sym));
        for ii = 1:modulation_mode
            bit_sur(loop_tree+1:end,modulation_mode-ii+1:modulation_mode:M*modulation_mode) = bit_sur(loop_tree+1:end,(ceil(seq/length(constel_sym))-1)*modulation_mode+modulation_mode-ii+1);
            bit_sur(loop_tree,modulation_mode-ii+1:modulation_mode:M*modulation_mode) = bitget(seq-1,ii);
        end
    end
end
%% 根据幸存星座点计算LLR
NB=0;
NE0=0;
NE1=0;
sum_NB=0;
eb0=zeros(nt,modulation_mode);
eb1=zeros(nt,modulation_mode);
empty_ix0=[];
empty_ix1=[];
E = error_sur/ NoisePower; %% LLR for QPSK
for loop_h=1:nt
    for loop_bit=1:modulation_mode
        b0_ix=find(bit_sur(loop_h,loop_bit:modulation_mode:modulation_mode*M)==0);   %每个符号第b位中等于0的
        b1_ix=find(bit_sur(loop_h,loop_bit:modulation_mode:modulation_mode*M)==1);   %每个符号第b位中等于1的
        if isempty(b0_ix)
            NE0=NE0+1;
            empty_ix0(NE0)=loop_h*modulation_mode+loop_bit;
            eb1(loop_h,loop_bit)=min(E(b1_ix));
        elseif isempty(b1_ix)
            NE1=NE1+1;
            empty_ix1(NE1)=loop_h*modulation_mode+loop_bit;
            eb0(loop_h,loop_bit)=min(E(b0_ix));
        else
            NB=NB+1;
            eb0(loop_h,loop_bit)=min(E(b0_ix));
            eb1(loop_h,loop_bit)=min(E(b1_ix));
            if eb0(loop_h,loop_bit)>eb1(loop_h,loop_bit)
                sum_NB=sum_NB+eb0(loop_h,loop_bit);
            else
                sum_NB=sum_NB+eb1(loop_h,loop_bit);
            end
        end
    end
end
emptye=sum_NB/NB*1.5;       %对于没有eb1或者eb0的位置的近似算法，1.5只是一个经验值 zlh
if ~isempty(empty_ix0)
    for k=1:length(empty_ix0)
        loop_h=floor((empty_ix0(k)-1)/modulation_mode);
        loop_bit=rem((empty_ix0(k)-1),modulation_mode)+1;
        eb0(loop_h,loop_bit)=emptye;
    end
end
if ~isempty(empty_ix1)
    for k=1:length(empty_ix1)
        loop_h=floor((empty_ix1(k)-1)/modulation_mode);
        loop_bit=rem((empty_ix1(k)-1),modulation_mode)+1;
        eb1(loop_h,loop_bit)=emptye;
    end
end
for loop_h=1:nt
    for loop_bit=1:modulation_mode
        lmd_tmp(loop_h,loop_bit)=eb0(loop_h,loop_bit)-eb1(loop_h,loop_bit);
    end
end
soft_value = reshape(lmd_tmp.',1,[]);
end