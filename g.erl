-module(g).
-compile(export_all).

t()->global:register_name(?MODULE,self()),
     E1=erlang:system_time(),
     t(1000),
     (erlang:system_time() - E1)/1000.

n(Node)->global:register_name(?MODULE,rpc:call(Node,erlang,spawn,[?MODULE,loop,[]])),
     E1=erlang:system_time(),
     t(1000),
     {ops,1000000000/((erlang:system_time() - E1)/100)}.

t(0)-> ok;
t(N)-> global:whereis_name(?MODULE),
       t(N-1).

s()->global:register_name(?MODULE,self()),
     E1=erlang:system_time(),
     timer:sleep(1000),
     (erlang:system_time() - E1).

loop()->
 timer:sleep(1000), 
 loop().