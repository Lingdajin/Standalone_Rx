function [TBS, modulation_mode, R] = TBS_calculation_f30( MCS_TABLE_PDSCH, nPRB, v, MCS, N_PRB_DMRS, N_sh_symb, N_PRB_oh)
%% *函数名 ： TBS_calculation
%% *函数功能描述 ： 调制阶数、目标码率和传输快大小确定
%% *输入参数 ： 
%  MCS_TABLE_PDSCH：higher layer parameter（是否等于256）
%  nPRB：针对UE的分配的PRB的总数
%  MCS：给定的“调制和编码方案”字段  
%  v：UE的层数

%% *输出参数 ：
%  TBS：传输块的值
%  modulation_mode：调制阶数
%  R：目标码率

%% MCS index table 1 for PDSCH
MCS1=[0 2 120/1024 ;
      1 2 157/1024 ;
      2 2 193/1024 ;
      3 2 251/1024 ;
      4 2 308/1024 ;
      5 2 379/1024 ;
      6 2 449/1024 ;
      7 2 526/1024 ;
      8 2 602/1024 ;
      9 2 679/1024 ;
      10 4 340/1024 ;
      11 4 378/1024 ;
      12 4 434/1024 ;
      13 4 490/1024 ;
      14 4 553/1024 ;
      15 4 616/1024 ;
      16 4 658/1024 ;
      17 6 438/1024 ;
      18 6 466/1024 ;
      19 6 517/1024 ;
      20 6 567/1024 ;
      21 6 616/1024 ;
      22 6 666/1024 ;
      23 6 719/1024 ;
      24 6 772/1024 ;
      25 6 822/1024 ;
      26 6 873/1024 ;
      27 6 910/1024 ;
      28 6 948/1024 ];
 
%% MCS index table 2 for PDSCH
MCS2=[0 2 120/1024 ;
      1 2 193/1024 ;
      2 2 308/1024 ;
      3 2 449/1024 ;
      4 2 602/1024 ;
      5 4 378/1024 ;
      6 4 434/1024 ;
      7 4 490/1024 ;
      8 4 553/1024 ;
      9 4 616/1024 ;
      10 4 658/1024 ;
      11 6 466/1024 ;
      12 6 517/1024 ;
      13 6 567/1024 ;
      14 6 616/1024 ;
      15 6 666/1024 ;
      16 6 719/1024 ;
      17 6 772/1024 ;
      18 6 822/1024 ;
      19 6 873/1024 ;
      20 8 682.5/1024 ;
      21 8 711/1024 ;
      22 8 754/1024 ;
      23 8 797/1024 ;
      24 8 841/1024 ;
      25 8 885/1024 ;
      26 8 916.5/1024 ;
      27 8 948/1024];
  
%% MCS index table 2 for PDSCH  --revised by zlh according to 38.214-f30 20181119 
MCS3 = [0	2	30/1024
        1	2	40/1024
        2	2	50/1024
        3	2	64/1024
        4	2	78/1024
        5	2	99/1024
        6	2	120/1024
        7	2	157/1024
        8	2	193/1024
        9	2	251/1024
        10	2	308/1024
        11	2	379/1024
        12	2	449/1024
        13	2	526/1024
        14	2	602/1024
        15	4	340/1024
        16	4	378/1024
        17	4	434/1024
        18	4	490/1024
        19	4	553/1024
        20	4	616/1024
        21	6	438/1024
        22	6	466/1024
        23	6	517/1024
        24	6	567/1024
        25	6	616/1024
        26	6	666/1024
        27	6	719/1024
        28	6	772/1024];
%% TBS index for N_info<=3824
TBS1=[24 32 40 48 56 64 72 80 88 96 104 112 120 128 136 144 152 160 168 176 184 192 208 ...
      224 240 256 272 288 304 320 336 352 368 384 408 432 456 480 504 528 552 576 608 640 ...
      672 704 736 768 808 848 888 928 984 1032 1064 1128 1160 1192 1224 1256 1288 1320 1352 ...
      1416 1480 1544 1608 1672 1736 1800 1864 1928 2024 2088 2152 2216 2280 2408 2472 2536 ...
      2600 2664 2728 2792 2856 2976 3104 3240 3368 3496 3624 3752 3824];

%% 调制顺序和目标码率的确定
 MCS = floor(MCS+1);
 switch MCS_TABLE_PDSCH
     case 1
         y = MCS1(MCS,:);
     case 2
         y = MCS2(MCS,:);
     case 3
         y = MCS3(MCS,:);
     otherwise
         error('Wrong MCS_TABLE_PDSCH configuration!');
 end
 modulation_mode = y(1,2);
 R = y(1,3);
   
%% TBS大小的确定
% step 1:determine the number of REs (N_RE) within the slot

% N_apostrophe_RE = 156;  (现有的版本里给出了这个值，但是以后可能会改，所以先写完整版)
N_RB_sc=12;         % the number of subcarriers in a physical resource block
% N_sh_symb=12;       % the number of symbols of the PDSCH allocation within the slot
% N_PRB_DMRS=12;    % the number of REs for DM-RS per PRB in the scheduled duration including the overhead of the DM-RS CDM groups indicated by DCI format 1_0/1_1 
% N_PRB_oh=0;         % is the overhead configured by higher layer parameter Xoh-PDSCH, if not configured:0
Napostrophe_RE=N_RB_sc * N_sh_symb - N_PRB_DMRS - N_PRB_oh;
%-------------------------------------------------------------
% if Napostrophe_RE<=9
%     N_apostrophe_RE=6;
% elseif Napostrophe_RE<=15
%     N_apostrophe_RE=12;
% elseif Napostrophe_RE<=30
%     N_apostrophe_RE=18;
% elseif Napostrophe_RE<=57
%     N_apostrophe_RE=42;
% elseif Napostrophe_RE<=90
%     N_apostrophe_RE=72;
% elseif Napostrophe_RE<=126
%     N_apostrophe_RE=108;
% elseif Napostrophe_RE<=150
%     N_apostrophe_RE=144;
% else
%     N_apostrophe_RE=156;
% end
% 
% N_RE = N_apostrophe_RE * nPRB;    % nPRB is the total number of allocated PRBs for the UE. 
%-------------------------------------------------------------
N_RE = min(Napostrophe_RE,156) * nPRB;          % revised by zlh according to 38.214-f30 20181119
%-------------------------------------------------------------

% step 2:the intermediate number of information bits (N_info)
N_info = N_RE * R * modulation_mode * v ;
% step 3:when N_info <= 3824, TBS is determined as follows
if N_info <= 3824
    n = max(3,floor(log2(N_info))-6);
    N_apostrophe_info = max(24, 2^n * floor(N_info/2^n));
    for i=1:length(TBS1)
        if TBS1(i)>=N_apostrophe_info
            TBS=TBS1(i);
            break;
        end
    end
else
% step 4:when N_info > 3824, TBS is determined as follows
    n = floor(log2(N_info-24))-5;
%     N_apostrophe_info = 2^n * round((N_info-24)/2^n);
    N_apostrophe_info = max(3840,2^n * round((N_info-24)/2^n)); % revised by zlh according to 38.214-f30 20181119
    if R<=1/4
        C = ceil((N_apostrophe_info+24)/3816);
        TBS = 8*C * ceil((N_apostrophe_info+24)/(8*C))-24;
    elseif N_apostrophe_info > 8424
        C = ceil((N_apostrophe_info+24)/8424);
        TBS = 8*C * ceil((N_apostrophe_info+24)/(8*C))-24;
    else
        TBS = 8* ceil((N_apostrophe_info+24)/8)-24;
    end
end
end