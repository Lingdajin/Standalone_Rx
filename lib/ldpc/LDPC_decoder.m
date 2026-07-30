function decoded_bits = LDPC_decoder(initial_llr, parity_matrix, information_length, max_iterations)
%LDPC_DECODER Sum-product LDPC decoder implemented in MATLAB.

if nargin < 4
    max_iterations = 50;
end

[check_count, codeword_length] = size(parity_matrix);
channel_llr = zeros(1, codeword_length);
copy_length = min(numel(initial_llr), codeword_length);
channel_llr(1:copy_length) = initial_llr(1:copy_length);

connections = cell(check_count, 1);
messages = cell(check_count, 1);
for check_idx = 1:check_count
    positions = find(parity_matrix(check_idx, :));
    connections{check_idx} = positions;
    messages{check_idx} = channel_llr(positions);
end

decoded_codeword = double(channel_llr <= 0);
for iteration = 1:max_iterations %#ok<NASGU>
    check_messages = sparse(check_count, codeword_length);
    for check_idx = 1:check_count
        positions = connections{check_idx};
        incoming = messages{check_idx};
        zero_count = sum(incoming == 0);
        if zero_count >= 2
            continue;
        end

        signs = sign(incoming);
        magnitudes = abs(incoming);
        if zero_count == 1
            is_zero = incoming == 0;
            nonzero_magnitudes = magnitudes(~is_zero);
            check_sum = sum(-log(tanh(nonzero_magnitudes / 2)));
            output_sign = prod(signs(~is_zero));
            check_messages(check_idx, positions(is_zero)) = ...
                -output_sign * log(tanh(check_sum / 2));
        else
            check_sum = sum(-log(tanh(magnitudes / 2)));
            extrinsic_sums = check_sum + log(tanh(magnitudes / 2));
            output_signs = prod(signs) * signs;
            check_messages(check_idx, positions) = ...
                -output_signs .* log(tanh(extrinsic_sums / 2));
        end
    end

    posterior_llr = channel_llr + full(sum(check_messages, 1));
    decoded_codeword = double(posterior_llr <= 0);
    if all(mod(parity_matrix * decoded_codeword', 2) == 0)
        break;
    end

    for check_idx = 1:check_count
        positions = connections{check_idx};
        posterior = posterior_llr(positions);
        extrinsic = full(check_messages(check_idx, positions));
        updated = posterior - extrinsic;

        indeterminate = isinf(posterior) & isinf(extrinsic);
        if any(indeterminate)
            same_sign = sign(posterior) == sign(extrinsic);
            updated(indeterminate & same_sign) = posterior(indeterminate & same_sign);
            updated(indeterminate & ~same_sign) = 0;
        end
        messages{check_idx} = updated;
    end
end

decoded_bits = decoded_codeword(1:information_length);
end
