-module(dnsd_ut).
-compile(export_all).

res(Name)->
case rand:uniform(4) of
1 -> inet_res:resolve(Name,in,a);
_ -> spawn(fun()-> inet_res:resolve(Name,in,a) end)  
end.

f(FN)-> {ok,F} = file:open(FN,[read]),
      f_loop(F).

f_loop(F)->
 case file:read_line(F) of
  {ok,L} -> [L1|_] = string:tokens(L,"\n\r\t"), 
            Ns=res(L1),
            io:format("~p ~n",[Ns]),
            f_loop(F);
  R->R
  end.

f()-> lists:map(fun(A)-> spawn (fun()-> f(A) end) end,["dmoz.R","top1m.R","com.R"]).
   