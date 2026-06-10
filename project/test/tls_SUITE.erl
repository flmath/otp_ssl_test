-module(tls_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([all/0, init_per_suite/1, end_per_suite/1, rsa_test/1, ecc_test/1, sm4_test/1]).

all() -> [rsa_test, ecc_test, sm4_test].

init_per_suite(Config) ->
    CertDir = "/workspace/project/certs",
    file:make_dir(CertDir),
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
        {ciphers, ["AES256-GCM-SHA384"]}
    ],
    test_handshake(9001, SslOpts, "-cipher AES256-GCM-SHA384", "AES256-GCM-SHA384").

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
    CertDir = ?config(cert_dir, Config),
    %% Check if SM4-GCM is available in the list of all suites
    AllSuites = ssl:cipher_suites(all, 'tlsv1.3'),
    IsSM4Supported = lists:any(fun(M) -> maps:get(cipher, M, undefined) == sm4_gcm end, AllSuites),
    
    case IsSM4Supported of
        true ->
            SslOpts = [
                {certfile, filename:join(CertDir, "sm2_cert.pem")},
                {keyfile, filename:join(CertDir, "sm2_key.pem")},
                {versions, ['tlsv1.3']},
                {ciphersuites, ["TLS_SM4_GCM_SM3"]}
            ],
            test_handshake(9003, SslOpts, "-ciphersuites TLS_SM4_GCM_SM3", "TLS_SM4_GCM_SM3");
        false ->
            ct:log("Supported TLS 1.3 suites: ~p", [AllSuites]),
            {skip, "SM4-GCM not supported in TLS 1.3 for this Erlang/OpenSSL combo"}
    end.

test_handshake(Port, SslOpts, OpenSslArgs, ExpectedCipher) ->
    %% Ensure we use a fresh port and cleanup properly
    case ssl:listen(Port, [{reuseaddr, true}, {active, false} | SslOpts]) of
        {ok, ListenSocket} ->
            Pid = spawn_link(fun() -> 
                case ssl:transport_accept(ListenSocket) of
                    {ok, S0} ->
                        case ssl:handshake(S0) of
                            {ok, S1} ->
                                ssl:send(S1, "OK"),
                                ssl:close(S1);
                            _ -> ok
                        end;
                    _ -> ok
                end
            end),
            
            Cmd = "echo 'Q' | openssl s_client -connect localhost:" ++ integer_to_list(Port) ++ " " ++ OpenSslArgs ++ " 2>&1",
            Result = os:cmd(Cmd),
            ct:log("OpenSSL Result: ~s", [Result]),
            
            ssl:close(ListenSocket),
            exit(Pid, kill),
            
            case string:find(Result, ExpectedCipher) of
                nomatch -> ct:fail("Handshake failed to negotiate ~s", [ExpectedCipher]);
                _ -> ok
            end;
        {error, Reason} ->
            ct:fail("Failed to listen on ~p: ~p", [Port, Reason])
    end.
