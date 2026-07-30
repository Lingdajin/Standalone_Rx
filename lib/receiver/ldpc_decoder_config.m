function cfg = ldpc_decoder_config(Ns, modulation_mode, C_save, F_save, ...
    RNTI, nID, q, len_Er_save, len_CB_save, SimParam_list, rm_pos_list, varargin)
%LDPC_DECODER_CONFIG Build the state used by the standalone LDPC decoder.

parser = inputParser;
parser.addParameter('src_len', [], @isnumeric);
parser.addParameter('HARQMaxTrans', 1, @(x) isnumeric(x) && isscalar(x));
parser.addParameter('crc_len', [], @isnumeric);
parser.addParameter('LLRbuffer', {}, @iscell);
parser.addParameter('to_decode_softvalue', {}, @iscell);
parser.parse(varargin{:});
options = parser.Results;

cfg.Ns = Ns;
cfg.src_len = options.src_len;
cfg.modulation_mode = reshape(modulation_mode, 1, []);
cfg.C_save = reshape(C_save, 1, []);
cfg.F_save = reshape(F_save, 1, []);
cfg.RNTI = expand_parameter(RNTI, Ns, 'RNTI');
cfg.nID = expand_parameter(nID, Ns, 'nID');
cfg.q = expand_parameter(q, Ns, 'q');
cfg.len_Er_save = reshape(len_Er_save, 1, []);
cfg.len_CB_save = reshape(len_CB_save, 1, []);
cfg.SimParam_list = SimParam_list;
cfg.rm_pos_list = rm_pos_list;

if isempty(options.crc_len)
    if isempty(cfg.src_len)
        cfg.crc_len = 24 * ones(1, Ns);
    else
        cfg.crc_len = 16 + 8 * (cfg.src_len > 3824);
    end
else
    cfg.crc_len = expand_parameter(options.crc_len, Ns, 'crc_len');
end

cfg.HARQMaxTrans = options.HARQMaxTrans;
cfg.harq_trans_idx = ones(1, Ns);
cfg.stream_offset = [0, cumsum(cfg.C_save(1:end-1))];

if isempty(options.LLRbuffer)
    cfg.LLRbuffer_list = cell(1, Ns);
    for stream_idx = 1:Ns
        cfg.LLRbuffer_list{stream_idx} = ...
            cell(cfg.C_save(stream_idx), cfg.HARQMaxTrans);
    end
else
    cfg.LLRbuffer_list = options.LLRbuffer;
end

if isempty(options.to_decode_softvalue)
    cfg.to_decode_softvalue_list = cell(1, Ns);
    for stream_idx = 1:Ns
        sim_param = SimParam_list{stream_idx};
        code_length = sim_param.momcodeLength - 2 * sim_param.liftZ;
        cfg.to_decode_softvalue_list{stream_idx} = ...
            zeros(cfg.C_save(stream_idx), code_length);
    end
else
    cfg.to_decode_softvalue_list = options.to_decode_softvalue;
end
end

function values = expand_parameter(values, count, parameter_name)
values = reshape(values, 1, []);
if isscalar(values)
    values = repmat(values, 1, count);
elseif numel(values) ~= count
    error('ldpc_decoder_config:InvalidParameterLength', ...
        '%s must be scalar or contain one value per stream.', parameter_name);
end
end
