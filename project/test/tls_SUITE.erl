-module(tls_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([all/0, init_per_suite/1, end_per_suite/1, rsa_test/1, ecc_test/1, sm4_test/1]).

all() -> [rsa_test, ecc_test, sm4_test].

init_per_suite(Config) ->
    CertDir = "/workspace/project/certs",
    os:cmd("bash /workspace/project/scripts/gen_certs.sh " ++ CertDir),
    ssl:start(),
    [{cert_dir, CertDir} | Config].

end_per_suite(_Config) ->
    ssl:stop().

rsa_test(Config) ->
    CertDir = ?config(cert_dir, Config),
    SslOpts = [
        {certfile, filename:join(CertDir, "rsa_cert.pem")},
        {keyfile, filename:join(CertDir, "rsa_key.pem")},
        {versions, ['tlsv1.2']},
        {ciphers, ["AES256-SHA256"]} %% RSA Key Exchange or similar
    ],
    test_handshake(9001, SslOpts, "-cipher AES256-SHA256", "AES256-SHA256").

ecc_test(Config) ->
    CertDir = ?config(cert_dir, Config),
    SslOpts = [
        {certfile, filename:join(CertDir, "ecc_cert.pem")},
        {keyfile, filename:join(CertDir, "ecc_key.pem")},
        {versions, ['tlsv1.3']},
        {ciphersuites, ["TLS_AES_256_GCM_SHA384"]}
    ],
    test_handshake(9002, SslOpts, "-ciphersuites TLS_AES_256_GCM_SHA384", "TLS_AES_256_GCM_SHA384").

sm4_test(Config) ->
    case lists:member(sm4_cbc, crypto:supports(ciphers)) of
        true ->
            CertDir = ?config(cert_dir, Config),
            SslOpts = [
                {certfile, filename:join(CertDir, "sm2_cert.pem")},
                {keyfile, filename:join(CertDir, "sm2_key.pem")},
                {versions, ['tlsv1.3']},
                {ciphersuites, ["TLS_SM4_GCM_SM3"]}
            ],
            test_handshake(9003, SslOpts, "-ciphersuites TLS_SM4_GCM_SM3", "TLS_SM4_GCM_SM3");
        false ->
            {skip, "SM4 not supported by this OTP/OpenSSL version"}
    end.

test_handshake(Port, SslOpts, OpenSslArgs, ExpectedCipher) ->
    {ok, ListenSocket} = tls_server:start(Port, SslOpts, self()),
    receive
        {server_started, _Pid} -> ok
    after 2000 ->
        error(timeout_waiting_for_server)
    end,
    
    %% Run openssl s_client
    Cmd = "echo 'Q' | openssl s_client -connect localhost:" ++ integer_to_list(Port) ++ " " ++ OpenSslArgs ++ " 2>&1",
    Result = os:cmd(Cmd),
    ct:log("OpenSSL Output: ~s", [Result]),
    
    tls_server:stop(ListenSocket),
    
    case string:find(Result, ExpectedCipher) of
        nomatch -> 
            ct:fail("Expected cipher ~s not found in handshake", [ExpectedCipher]);
        _ -> 
            ok
    end.
