function [Hd_base,z,SimParam] = genHd_base(K,N,R)
%产生校验基础矩阵和校验矩阵
% K为信息码长，R为码率
% BG2: K<=292 // （K<=3824 & R<=0.67） // R<=0.25
% BG1: else

aset = [2 3 5 7 9 11 13 15];
Zset1 = [2,4,8,16,32,64,128,256];
Zset2 = [3,6,12,24,48,96,192,384];
Zset3 = [5,10,20,40,80,160,320];
Zset4 = [7,14,28,56,112,224];
Zset5 = [9,18,36,72,144,288];
Zset6 = [11,22,44,88,176,352];
Zset7 = [13,26,52,104,208];
Zset8 = [15,30,60,120,240];
Zset = [Zset1,Zset2,Zset3,Zset4,Zset5,Zset6,Zset7,Zset8];
Zset = sort(Zset);

%% 确定BGtype
if  K<=308 || (K<=3840 && R<=0.67) || R<=0.25
    load('BG2.mat');
    BGtype = 'BG2';
    BG = BG2;
    mb = 42;
    nb = 52;
    Rmax = 1/5;
    if K<192
        kb = 6;
    elseif K>192 && K<560
        kb = 8;
    elseif K>560 && K<640
        kb = 9;
    else
        kb = 10;
    end
else
    load('BG1.mat');
    BGtype = 'BG1';
    BG = BG1;
    mb = 46;
    nb = 68;
    kb = 22;
    Rmax = 1/3;
end

%% 确定扩展因子
z = ceil(K/kb);
z_pos = find(Zset-z>=0,1,'first');
z = Zset(z_pos);
a0 = z;
for j = 8:-1:1
    b = a0/aset(j);
    if b == fix(b)
        a = aset(j);
        break;
    end
end
%% 选择基础矩阵
p = find(aset==a);
Hb = BG(:,:,p);

row_base=ceil((N+2*z-K)/z); % 基础矩阵行数
if row_base>mb
    row_base=mb;
end
switch BGtype
    case 'BG2'
        col_base=10+row_base;
    case 'BG1'
        col_base=22+row_base;
end
Hd_base=Hb(1:row_base,1:col_base);
pos = find(Hd_base>0);
Hd_base(pos)=mod(Hd_base(pos),z);

liftZ = z;
momCodeLength = nb*liftZ;
momK = kb*liftZ;
% l_padding = momK-CBS;
l_padding = momK-K;
iteration=50;

SimParam.liftZ             = liftZ;
% SimParam.PCMName           = Hname;
SimParam.BGtype            = BGtype;
SimParam.momcodeLength     = momCodeLength;
SimParam.momK              = momK;
SimParam.l_padding         = l_padding;
SimParam.iterationNumLDPC  = iteration;
SimParam.decType           = 'FloodingBP';

end

