function [Hbname,Hb,z] = genHb(K,R)
%产生校验矩阵
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
if  K<=292 || (K<=3840 && R<=0.67) || R<=0.25
    load('BG2.mat');
    BG = BG2;
    mb = 42;
    nb = 52;
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
    BG = BG1;
    mb = 46;
    nb = 68;
    kb = 22;
end

%% 确定扩展因子
z = ceil(K/kb);
z_pos = find(Zset-z>=0,1,'first');
z = Zset(z_pos);
%% 选择基础矩阵
a0 = z;
for j = 8:-1:1
    b = a0/aset(j);
    if b == fix(b)
        a = aset(j);
        break;
    end
end

Hbname = ['Hb_K',num2str(K),'_R',num2str(R),'_Z',num2str(z),'.mat'];
if exist(Hbname, 'file')
    load( Hbname );
    return;
end

p = find(aset==a);
Hb = BG(:,:,p);
pos = find(Hb>0);
Hb(pos)=mod(Hb(pos),z);
global MainFileAddress
base_address = MainFileAddress.address;
cache_dir = fullfile(base_address, 'data', 'MatForLDPC');
if ~isfolder(cache_dir), mkdir(cache_dir); end
name = fullfile(cache_dir, ['Hb_K',num2str(K),'_R',num2str(R),'_Z',num2str(z),'.mat']);
save(name,'Hb');

end

