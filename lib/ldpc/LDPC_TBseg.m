function [ C,CBS,L0,CBsets ] = LDPC_TBseg( info_bits, TBS,Rc )
%LDPC_TB segmentation & adding CRC 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name：LDPC_TBseg
% Input:
%   Kcb: Maximum CB length
%   info_bits: information bits
%   TBS: length of TB (N_info)
%   Rinit: initial Rate
% Output:
%   BGtype: Base graph type(BG1/BG2)
%   C: number of CB
%   CBS: length of CB(not including CB-CRC)
%   L0: length of filled bits
%   CBsets: matrix,CB sets after segmentation and adding CRC
%           every row represents a CB sequence
% Description：
% (1) This function generates transmission data.
% Amendent record：
%    by zhangjignwen 2018-3-11
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if TBS <= 292 || (TBS <= 3824 && Rc <= 0.67) || Rc <= 0.25
    Kcb = 3840;
else
    Kcb = 8448;
end
%%  添加TB-CRC
if TBS <= 3824                    
    L1 = 16;
    TBcrc_bits = crc_calc_212(info_bits,'CRC16');
else
    L1 = 24;
    TBcrc_bits = crc_calc_212(info_bits,'CRC24A');
end
info_bits = [info_bits TBcrc_bits];

%% CB数目及CB长度
B = TBS + L1;
L2 = 24;
if B <= Kcb
    C = 1;
    CBS = B;
else
    C = ceil(B/(Kcb - L2));
    CBS = ceil(B/C);  %zlh
%     CBS = ceil(B/C)+24;
end
%% TB分割
if C == 1
    CBsets = info_bits;
    L0 = 0;
else
    L0 = C*CBS - B;
    if L0 > 0
        fill_bits = zeros(L0);
        info_bits = [info_bits fill_bits];
    end
    for i = 1 :C
        CBsets(i,:) =  info_bits(CBS*(i-1)+1:CBS*i);
    end
%% 添加CB-CRC
    for i = 1:C
        CBcrc_bits = crc_calc_212(CBsets(i,:),'CRC24B');
        CBsets1(i,:) = [CBsets(i,:) CBcrc_bits];
    end
    CBsets = CBsets1;
    CBS = CBS + L2;
end
end

