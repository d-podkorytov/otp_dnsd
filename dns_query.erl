-module(dns_query).
-compile(export_all).

%ask_to_bin({Name,In,A})->  ID = random:uniform(16#FFFF),
%                         inet_dns:encode
 %                        ({dns_rec,{dns_header,ID,false,query,false,false,false,false,false,1},
 %                         [{dns_query,Name,A,In}],[],[],[]}
 %                        ).

header()-> ID = rand:uniform(16#FFFF),
           %logger:critical(#{id => ID}),
           {dns_header,ID,false,query,false,false,true,false,false,0}. 

ask_to_bin({Name,In,A},Opt1,Opt2,Opt3)->
                         Header= header(),                          
                         {Header,inet_dns:encode({dns_rec,Header,
                                                  [{dns_query,Name,A,In}],
                                                  Opt1,Opt2,Opt3
                                                 }
                                                )
                         }.
%Return like
%{ok,{dns_rec,
%                       {dns_header,1251,false,query,false,false,true,false,
%                           false,0},
%                       [{dns_query,"vk.com",a,in}],
%                       [{dns_rr,"vk.com",a,in,0,378,
%                            {87,240,137,158},
%                            undefined,[],false},
%                        {dns_rr,"vk.com",a,in,0,378,
%                            {87,240,190,72},
%                            undefined,[],false},
%                        {dns_rr,"vk.com",a,in,0,378,
%                            {87,240,139,194},
%                            undefined,[],false},
%                        {dns_rr,"vk.com",a,in,0,378,
%                            {87,240,190,67},
%                            undefined,[],false},
%                        {dns_rr,"vk.com",a,in,0,378,
%                            {87,240,190,78},
%                            undefined,[],false},
%                        {dns_rr,"vk.com",a,in,0,378,
%                            {93,186,225,208},
%                            undefined,[],false}],
%                       [],[]}}

ask({Host,Port},Ask,Opt1,Opt2,Opt3)->
                      {ok, S} = gen_udp:open(0, [binary, {active, false}, {recbuf, 8192}]),
                      ok = gen_udp:connect(S, Host, Port),
                      {Header,Bin} = ask_to_bin(Ask,Opt1,Opt2,Opt3),
                      gen_udp:send(S,Bin),
                      R=try gen_udp:recv(S,1000) of
                         {ok,{Host,Port,Msg}} -> validate(Header,inet_dns:decode(Msg));
                          R1                  -> R1 
                        catch
                         Err:Reason:Stack -> #{module => ?MODULE, line => ?LINE, err => Err,reason => Reason,stack => Stack}  
                        end,
                      gen_udp:close(S),
                      R.
                      
ask(Host,Ask) when is_tuple(Ask) ->ask({Host,53},Ask,[],[],[]);                      
ask(Host,Ask) when is_list(Ask) ->ask({Host,53},{Ask,in,a},[],[],[]).                      

ask(Ask)->ask({{77,88,8,3},53},Ask).                      

%test
ask()-> ask({77,88,8,3},{"ya.ru",in,a}).

validate_headers({dns_header,ID,False0,query,false,false,True1,False1,false,Int},
                 {dns_header,ID,False3,query,false,false,True2,False2,false,Int}  
                )->true.

validate(Header,Reply) ->
 try Reply of
  {ok,{dns_rec,Header1,Query,RR,Opt1,Opt2}} -> 
      case validate_headers(Header,Header1) of
       true -> {ok,{dns_rec,Header,Query,RR,Opt1,Opt2}}
      end
 catch
  Err:Reason:Stack -> #{line => {?MODULE,?LINE}, err => {Err,Reason}, stack => Stack, ask_header => Header, reply => Reply}   
 end.
                     
                      