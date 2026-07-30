%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output parameters:
    % H_Innse: frequency domaion H, with size m*n*p, and:
    % m: Pilot_port*Nr;
    % n: used subcarrier index;
    % p: OFDM symbol index of data region.
% Modified in 2012.3 based on previous CE.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ H_Inuse ] = LMMSE_CE(Pilot_port,Nr,Nd,Nc_used,FFT_size,Nc,PILOT_COLUMN_INDEX,DATA_COLUMN_INDEX,Pilot_position,Pilot_Signal,FFT_Out_Pilot,M_LMMSE)

for nra=1:Nr
    for nta = 1:Pilot_port
        PILOT_COLUMN_INDEX_temp = PILOT_COLUMN_INDEX(nta,~isnan(PILOT_COLUMN_INDEX(nta,:)));    % 除去PILOT_COLUMN_INDEX中设置的NaN
        P_ns = length(PILOT_COLUMN_INDEX_temp);                                                 % P_ns:导频所占符号数
        Pilot_Col = zeros(Nc_used,P_ns);
        % ********** interpolatoin at freqency domain ********* %
        for np = 1:P_ns
            Pilot_H_LS = squeeze(FFT_Out_Pilot(nra,nta,:,np))./(squeeze(Pilot_Signal(nta,:,np))+eps).';
            H_LMMSE_Pilot = M_LMMSE*Pilot_H_LS;
%             Pilot_position_temp = mod(squeeze(Pilot_position(nta,:,np))-(FFT_size-Nc)/2 ,Nc_used);               % 使插值时导频位置总是从第一个RB开始，方便逐个RB信道估计
            Pilot_position_temp = squeeze(Pilot_position(nta,:,np))-(FFT_size-Nc)/2; 
            Pilot_Col(:,np) = interp1(Pilot_position_temp,H_LMMSE_Pilot.',1:Nc_used,'linear','extrap');
        end
        % ********** interpolatoin at temporal domain ********* %
        if size(Pilot_Col,2) == 1
            Pilot_Ant_Pair=repmat(Pilot_Col,1,Nd);                                                      % 时域只有一列时，重复插值 %复制
        else
            Pilot_Ant_Pair=interp1(PILOT_COLUMN_INDEX_temp,Pilot_Col.',[1:Nd],'linear','extrap').';     % 时域不止一列时，线性插值
        end
        H_Inuse((nta-1)*Nr+nra,:,:) = Pilot_Ant_Pair(:,DATA_COLUMN_INDEX);
    end
end

end