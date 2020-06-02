-module(dns_dets).
-compile(export_all).

init()-> try dets:open_file(?MODULE, [{type, set},{file,"dns.dets"} %,{ramfile,true}
                                     ]) 
         of
         {ok,R}-> info_rand(R),
                  R
         catch
          Err:Reason -> {?MODULE,?LINE,Err,Reason} 
         end.

i(K,V)->
% io:format("~p:~p i ~p ~n",[?MODULE,?LINE,K]),
 init(), 
 dets:insert(?MODULE, {K,V}).

g0(K,F1)->F1(K).


g(K,F1)->
 init(), 
 try dets:lookup(?MODULE, K) of
 [{K,V}] -> V;
 [] -> V=F1(K),
       i(K,V),
       V;
        
  _ -> F1(K)
 catch
  _:_ -> F1(K)
 end.

info_rand(Ref)->
 case rand:uniform(1024) of
  1 -> info(Ref);
  _ -> ok
 end.

info(Ref)->
try io:format("~p:~p ~p ~p ~n",[?MODULE, ?LINE, {date(),time()},dets:info(Ref)]) of
         R-> 
             R
         catch
          Err:Reason -> {?MODULE,?LINE,Err,Reason} 
         end.

test()->
 [%init(),
  i(1,{date(),time()}),
  i(2,{date(),time()}),

  g(1, fun(A)-> A end),
  g(3, fun(A)-> A end)
  
 ].
