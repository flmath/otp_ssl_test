-module(tls_server).
-export([start/3, stop/1, loop/1, start_standalone/2]).

start(Port, SslOpts, Parent) ->
    {ok, ListenSocket} = ssl:listen(Port, SslOpts),
    spawn_link(?MODULE, loop, [ListenSocket]),
    Parent ! {server_started, self()},
    {ok, ListenSocket}.

start_standalone(Port, SslOpts) ->
    ssl:start(),
    {ok, ListenSocket} = ssl:listen(Port, [{active, false}, {reuseaddr, true} | SslOpts]),
    io:format("Server started on port ~p~n", [Port]),
    loop(ListenSocket).

stop(ListenSocket) ->
    ssl:close(ListenSocket).

loop(ListenSocket) ->
    case ssl:transport_accept(ListenSocket) of
        {ok, Socket} ->
            case ssl:handshake(Socket) of
                {ok, S} ->
                    ssl:send(S, "Hello from Erlang TLS Server"),
                    ssl:close(S);
                {error, _Reason} ->
                    ok
            end,
            loop(ListenSocket);
        {error, _Reason} ->
            ok
    end.
