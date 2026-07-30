function MatrixForCE = MatrixForCE_Gen(sigma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description: 
% (1) MatrixForCE_Gen generates matrix for channel estiamtion.
% (2) The matrix is either for LMMSE CE or expPDP CE based on CE_mode.
%% Input Parameters:
    % sigma: noise standard deviation
%% Output Parameters:
    % MatrixForCE: structure variable,inculding components:
        % M_LMMSE_odd_CRS and M_LMMSE_even_CRS: matrixes for LMMSE CE based on CRS.
        % M_expPDP_CRS: matrix for expPDP CE based on CRS.
        % M_LMMSE_odd_DMRS and M_LMMSE_even_DMRS: matrixes for LMMSE CE based on DMRS.
        % M_expPDP_DMRS: matrix for expPDP CE based on DMRS.
%% Modification records:
% (1) Modify annotations in 2012.11.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SystemParam
global ChannelParam
global PilotParam
global path_power_exp_PDP
global path_delay_exp_PDP
global N_Matraix
global DMRS_perM
global SC_perM
global CSIRS_perM

TM               = SystemParam.TM;
FFT_size         = SystemParam.FFT_size;
Nc               = SystemParam.Nc;
Nr               = SystemParam.Nr;
Nc_Index         = SystemParam.Nc_Index;
pathPower        = ChannelParam.pathPower;
Path_Delay       = ChannelParam.Path_Delay;
NumOfTaps        = ChannelParam.NumOfTaps;
CE_Mode_CRS      = SystemParam.CE_Mode_CRS;
CE_Mode_DMRS     = SystemParam.CE_Mode_DMRS;
CE_Mode_CSIRS    = SystemParam.CE_Mode_CSIRS;

MatrixForCE = struct(...
    'M_LMMSE_CRS',[],...
    'M_expPDP_CRS',[],...
    'M_LMMSE_DMRS',[],...
    'M_expPDP_DMRS',[],...
    'M_LMMSE_CSIRS',[],...
    'M_expPD_CSIRS',[]);

% matrix for channel estimation based on CRS
if SystemParam.CRS_port ~= 0
    CRS_port         = SystemParam.CRS_port;
    Nc_used_CRS      = SystemParam.Nc_used_CRS;
    Nc_used_DMRS     = SystemParam.Nc_used_DMRS;
    CRS_position     = PilotParam.CRS_position;
    CRS_Signal       = PilotParam.CRS_Signal;
    CRS_COLUMN_INDEX = PilotParam.CRS_COLUMN_INDEX;
    switch CE_Mode_CRS
        case 2
            [ MatrixForCE.M_LMMSE_CRS ] = MatrixForLMMSE_Gen(pathPower,Path_Delay,CRS_position,FFT_size,sigma,Nc,NumOfTaps,Nc_used_CRS);
        case 3
            MatrixForCE.M_expPDP_CRS = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,CRS_Signal,CRS_position,CRS_COLUMN_INDEX,sigma,FFT_size,CRS_port,Nr,Nc_Index);
    end
end

% matrix for channel estimation based on DMRS
if SystemParam.DMRS_port~= 0
    DMRS_port         = SystemParam.DMRS_port;
    DMRS_position     = PilotParam.DMRS_position;
    DMRS_Signal       = PilotParam.DMRS_Signal;
    DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
    Nc_used_DMRS = SystemParam.Nc_used_DMRS;
    switch CE_Mode_DMRS
        case 2
            switch TM
                case 7
                     error('LMMMSE is not available for TM 7 and TM 8!') % becuase  granularity for TM7/8 CE is not the whole bandwidth
                case 8 
                     error('LMMMSE is not available for TM 7 and TM 8!') % becuase  granularity for TM7/8 CE is not the whole bandwidth
                case 9 
                    [ MatrixForCE.M_LMMSE_DMRS ] = MatrixForLMMSE_Gen(pathPower,Path_Delay,DMRS_position,FFT_size,sigma,Nc,NumOfTaps,Nc_used_DMRS);
                case 'NR'
                    [ MatrixForCE.M_LMMSE_DMRS ] = MatrixForLMMSE_Gen(pathPower,Path_Delay,DMRS_position,FFT_size,sigma,Nc,NumOfTaps,Nc_used_DMRS);
            end
        case 3
            switch TM
                case 7
                    for nrb = 1:N_Matraix
                        stp = (nrb-1) * SC_perM + 1;
                        edp = nrb * SC_perM;
                        stp1 = (nrb-1) * DMRS_perM + 1;
                        edp1 = nrb * DMRS_perM;
                        DMRS_Signal_perM= DMRS_Signal(:,stp1:edp1,:);
                        DMRS_position_perM = DMRS_position(:,stp1:edp1,:);
                        Nc_Index_perM = Nc_Index(stp:edp);
                        MatrixForCE.M_expPDP_DMRS(nrb,:,:,:,:,:) = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,DMRS_Signal_perM,DMRS_position_perM,DMRS_COLUMN_INDEX,sigma,FFT_size,DMRS_port,Nr,Nc_Index_perM);
                    end
                case 8 
                    for nrb = 1:N_Matraix
                        stp = (nrb-1) * SC_perM + 1;
                        edp = nrb * SC_perM;
                        stp1 = (nrb-1) * DMRS_perM + 1;
                        edp1 = nrb * DMRS_perM;
                        DMRS_Signal_perM= DMRS_Signal(:,stp1:edp1,:);
                        DMRS_position_perM = DMRS_position(:,stp1:edp1,:);
                        Nc_Index_perM = Nc_Index(stp:edp);
                        MatrixForCE.M_expPDP_DMRS(nrb,:,:,:,:,:) = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,DMRS_Signal_perM,DMRS_position_perM,DMRS_COLUMN_INDEX,sigma,FFT_size,DMRS_port,Nr,Nc_Index_perM);
                    end
                case 9
                    MatrixForCE.M_expPDP_DMRS = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,DMRS_Signal,DMRS_position,DMRS_COLUMN_INDEX,sigma,FFT_size,DMRS_port,Nr,Nc_Index);
                case 'NR'
                    for nrb = 1:N_Matraix
                        stp = (nrb-1) * SC_perM + 1;
                        edp = nrb * SC_perM;
                        stp1 = (nrb-1) * DMRS_perM + 1;
                        edp1 = nrb * DMRS_perM;
                        DMRS_Signal_perM= DMRS_Signal(:,stp1:edp1,:);
                        DMRS_position_perM = DMRS_position(:,stp1:edp1,:);
                        Nc_Index_perM = Nc_Index(stp:edp);
                        MatrixForCE.M_expPDP_DMRS(nrb,:,:,:,:,:) = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,DMRS_Signal_perM,DMRS_position_perM,DMRS_COLUMN_INDEX,sigma,FFT_size,DMRS_port,Nr,Nc_Index_perM);
                    end
            end
        case 4
            if TM == 'NR'
                for nrb = 1:N_Matraix
                    stp = (nrb-1) * SC_perM + 1;
                    edp = nrb * SC_perM;
                    stp1 = (nrb-1) * DMRS_perM + 1;
                    edp1 = nrb * DMRS_perM;
                    DMRS_Signal_perM= DMRS_Signal(:,stp1:edp1,:);
                    DMRS_position_perM = DMRS_position(:,stp1:edp1,:);
                    Nc_Index_perM = Nc_Index(stp:edp);
                    MatrixForCE.M_expPDP_DMRS(nrb,:,:,:,:,:) = MatrixForexpPDP_Gen(pathPower,Path_Delay,DMRS_Signal_perM,DMRS_position_perM,DMRS_COLUMN_INDEX,sigma,FFT_size,DMRS_port,Nr,Nc_Index_perM);
%                     MatrixForCE.M_expPDP_DMRS(nrb,:,:,:,:,:) = MatrixForexpPDP_Gen(pathPower,Path_Delay,CSIRS_Signal_perM,DMRS_position_perM,DMRS_COLUMN_INDEX,sigma,FFT_size,DMRS_port,Nr,Nc_Index_perM);
                end
            else
                error('this CE only for NR DMRS now');
            end
    end
end

% matrix for channel estimation based on CSI-RS
if SystemParam.CSIRS_port~= 0
    CSIRS_port         = SystemParam.CSIRS_port;
    Nc_used_CSIRS      = SystemParam.Nc_used_CSIRS;
    CSIRS_position     = PilotParam.CSIRS_position;
    CSIRS_Signal       = PilotParam.CSIRS_Signal;
    CSIRS_COLUMN_INDEX = PilotParam.CSIRS_COLUMN_INDEX;
    switch CE_Mode_CSIRS
        case 2
            [ MatrixForCE.M_LMMSE_CSIRS ] = MatrixForLMMSE_Gen(pathPower,Path_Delay,CSIRS_position,FFT_size,sigma,Nc,NumOfTaps,Nc_used_CSIRS);
        case 3
%             MatrixForCE.M_expPDP_CSIRS = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,CSIRS_Signal,CSIRS_position,CSIRS_COLUMN_INDEX,sigma,FFT_size,CSIRS_port,Nr,Nc_Index);
            M_expPDP_CSIRS = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,CSIRS_Signal,CSIRS_position,CSIRS_COLUMN_INDEX,sigma,FFT_size,CSIRS_port,Nr,Nc_Index);
            MatrixForCE.M_expPDP_CSIRS = M_expPDP_CSIRS(:,:,:,1:SystemParam.Nc_RB:end,:);  
        case 4
             if TM == 'NR'
                CSIRS_port = 1;
                CSIRS_perM = 6;
%                 for nrb = 1:N_Matraix
%                     stp = (nrb-1) * SC_perM + 1;
%                     edp = nrb * SC_perM;
%                     stp1 = (nrb-1) * CSIRS_perM + 1;
%                     edp1 = nrb * CSIRS_perM;
%                     CSIRS_Signal_perM= CSIRS_Signal(:,stp1:edp1,:);
%                     CSIRS_position_perM = CSIRS_position(:,stp1:edp1,:);
%                     Nc_Index_perM = Nc_Index(stp:edp);
%                     MatrixForCE.M_expPDP_CSIRS(nrb,:,:,:,:,:) = MatrixForexpPDP_Gen(pathPower,Path_Delay,CSIRS_Signal_perM,CSIRS_position_perM,CSIRS_COLUMN_INDEX,sigma,FFT_size,CSIRS_port,Nr,Nc_Index_perM);
%                     %N_Matraix*Nr*CSIRS/DMRS_port*NumOfPilotColumn*SC_perM*Pilot_perM
%                 end
            else
                error('this CE only for NR DMRS now');
            end
            %             MatrixForCE.M_expPDP_CSIRS = MatrixForexpPDP_Gen(path_power_exp_PDP,path_delay_exp_PDP,CSIRS_Signal,CSIRS_position,CSIRS_COLUMN_INDEX,sigma,FFT_size,CSIRS_port,Nr,Nc_Index);
%             M_expPDP_CSIRS = MatrixForexpPDP_Gen(pathPower,Path_Delay,CSIRS_Signal,CSIRS_position,CSIRS_COLUMN_INDEX,sigma,FFT_size,CSIRS_port,Nr,Nc_Index);
%             MatrixForCE.M_expPDP_CSIRS = M_expPDP_CSIRS(:,:,:,1:SystemParam.Nc_RB:end,:);
    end
end