% simple Syslog client
% send some message to syslog server
-module(dnser).
-compile(export_all).
-include("common.hrl").

-define(PREAMBLE,"<165>:Jun 21 16:13:28 UTC:").

ask(Query)      ->a({127,0,0,1},53,Query).
ask(Host,Query) ->a(Host,53,Query).
ask(Host,Port,Query) ->a(Host,Port,Query).

a(Host,Port,Query)->
                      {ok, S} = gen_udp:open(0, [binary, {active, false}, {recbuf, 8192}]),
                      ok = gen_udp:connect(S, Host, Port),
                      gen_udp:send(S,Query),
                      gen_udp:close(S).

tests()-> [test()].

test()-> inet_res:nslookup("ya.ru",in,a,[{{127,0,0,1},53}]).

start()-> start({127,0,0,1},53).

start(Host,Port)->
          {ok, S} = gen_udp:open(0, [binary, {active, true}, {recbuf, 8192}]),
           ok     = gen_udp:connect(S, Host, Port), 
          Pid=spawn(fun()-> loop(S) end),
          register(?MODULE,Pid),
          ok.

% client loop 
loop(S)->
 receive
  {From,Msg}-> gen_udp:send(S,Msg) 
 end,
 loop(S).          

% store msg
send(Msg)->
 ?MODULE!{self(),Msg}.           

play_file(Name)->play_file(Name,{127,0,0,1},53).
play_file(Name,IP,Port)->
 {ok,L}=file:read_file(Name),
 lists:map(fun(A)-> ask(IP,Port,A) end, string:tokens(binary_to_list(L),"\n")).

play_file()->play_file("dnser.log"). 
                         