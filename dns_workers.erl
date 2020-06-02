-module(dns_workers).

-include_lib("eunit/include/eunit.hrl").

-behaviour(gen_server).

-define(SERVER, ?MODULE).

%%%
%%
%%%

-export([start_link/0, start_link/1, start/2, start/1, 
         info/0, info/1, info/2, name/1,
         
         parse_ask/1
	]).

-export([init/1,
	 handle_call/3,
	 handle_cast/2,
	 handle_info/2,
	 terminate/2,
	 code_change/3]).

-include("common.hrl").

%%====================================================================
%% API
%%====================================================================
start(N)-> 
     P= case start_link() of
     {ok,Pid}                -> Pid;
     {error,{already_started,Pid2}} -> Pid2; 
      R-> logger:critical(#{point => ?POINT, return => R, subject => "unexpected return in start_link"}),
          R
end.
%    logger:critical(#{point => ?POINT, subject => "try to start worker", no => N ,pid => P}),
%    %yes = 
%    global:register_name(list_to_atom("worker_"++integer_to_list(N)),P),
%    P.
% do not used and debugged yet
start(Node,N)->
     % or use pg 
    {ok,Pid} = rpc:call(Node,?MODULE,start_link,[]),
    logger:critical(#{point => ?POINT, subject => "try to start worker", no => N, node => Node}),
    %yes = 
%    global:register_name(dns_workers:name(N),Pid),
    dns_ns:set(dns_workers:name(N),Pid),
    Pid.
    
start_link() ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "start_link" }),   
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(N) ->
    %logger:?TRACE_POINTS_LEVEL(#{no => N,point => ?POINT ,subject => "start_link" }),   
    gen_server:start_link({global, name(N) }, ?MODULE, [], []).

%%====================================================================
%% Gen Server
%%====================================================================

init(Arg) ->
    %logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "init" , state => Arg}),
    {ok, #{pid => self() }}.

handle_call(Ask, From, State) ->
	logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_call" , ask => Ask, from => From ,state => State }),   
	{reply, {ok, {?MODULE,?LINE,'Result'}}, State};

handle_call(Ask, From, State) ->
	logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_call" , ask => Ask, from => From ,state => State }),   
	%{reply, {error, What}, State}.
        {noreply, State}.
        
handle_cast(Ask, State) ->
	logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_cast" , ask => Ask, state => State }),   
	{noreply, State}.

handle_info({Pid,info}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info {Pid,info} ask" , ask => info, state => State }),
    Pid!#{process_info => erlang:process_info(self()) },  
    {noreply, State};

handle_info({Pid,{info,Subject}}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info {Pid,info,subject} ask" , ask => info, state => State }),
    Pid!erlang:process_info(self(),Subject),  
    {noreply, State};

handle_info({Pid,{Socket,ClientAddr,Port,Ask}}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info" , ask => Ask, state => State }),
    %{udp,_Sock,
    %          ClientAddr,
    %          Port,
    %          NsAsk} = Ask,
    %%route(Ask,State),
    {Header,Name,In,A}=parse_ask(Ask),
    Result = ns_query(Header,{Name,In,A}),
    %logger:critical(#{header_ask => Header, point => ?POINT}),
    Ret=case Result of
     {ok,Res} -> Pid!{self(),{worker_reply,{Socket,ClientAddr,Port,inet_dns:encode(Res)}}};
     Unknown  -> logger:critical(#{result => Result, 
                                   ns_ask => {Name,In,A} , 
                                   point => ?POINT , 
                                   reply_to_pid => Pid ,
                                   subject => "can not decode server reply ", 
                                   unexpected_return => Unknown}),
                                   Unknown
    end,

    %logger:critical(#{result => Ret, ns_ask => {Name,In,A} , point => ?POINT , reply_to_pid => Pid }),
    {noreply, State};

handle_info(Un, State) ->
    logger:critical(#{unexpected_ask => Un, point => ?POINT , state => State }),
    {noreply, State}.

terminate(Reason, State) ->
    logger:critical(#{point => ?POINT ,subject => "terminate" , ask => Reason, state => State }),   
    ok.

code_change(OldVsn, State, Extra) ->
    logger:critical(#{point => ?POINT ,subject => "code_change" , ask => OldVsn, state => State , extra => Extra}),   
    {ok, State}.

%%====================================================================
%% Internal functions
%%====================================================================
% for exeternal call and debug remove it late
parse_ask({udp,_Sock,
              ClientAddr,
              Port,
              NsAsk})-> parse_ask(NsAsk);

parse_ask(Ask)-> %logger:critical(#{ ask => Ask, point => ?POINT, self => self() }),
                 Ns_Ask = inet_dns:decode(Ask),
                  
                 logger:critical(#{ ask => Ns_Ask, point => ?POINT, self => self() }),
                 {ok,{dns_rec,Header,
                      [{dns_query,Name,A,In}],
                       L1,L2,L3}} = inet_dns:decode(Ask),
                       
                 {Header,Name,In,A}.
% BUG Warning: Query responce bit was setup manatory 
ns_query(Clnt_Header,{Name,In,A})->
        logger:critical(#{point => ?POINT, client_header => Clnt_Header, ns_ask => {Name,In,A}}),
        % dont forget about optional query fields
        %  inet_res:nslookup(Name,In,A,[{{1,1,1,1},53}])
	R=case dns_query:ask({77,88,8,3},{Name,In,A}) of 
	  {ok,{dns_rec,Srv_Header,Query,Reply,Opt1,Opt2}} ->
	                   logger:critical(#{client_header => Clnt_Header, 
	                                     server_header => Srv_Header,
	                                     query => Query ,
	                                     subject => "replace server header to client header", 
	                                     point => ?POINT}),
	                    % validate_headers Clnt_Header Srv_Header                 
                           {ok,{dns_rec,change_id(Clnt_Header,Srv_Header),Query,Reply,Opt1,Opt2}}; % do not replace Header ,Opt1 Opt2 should be same like in query
                       
           UnExp -> logger:critical(#{point => ?POINT, unexpected_return => UnExp}),
                    UnExp            
	end,
	
	logger:critical(#{point => ?POINT, 
	                  ns_result => R, 
	                  subject => "do not forget to replace header in ns_result to client and about Opt1 Opt2 extensional options"
	                 }
	               ),
	R.

dns_route(Msg,State)->
  logger:critical(#{ask => Msg, 
                    point => ?POINT_ARG("route Msg to different endpoints messages will be here"), 
                    subject => "try to route message" }).

info(Worker)->
 dns_ns:pid(Worker)!{self(),info},
 receive
  R->R
  after 10000 -> {timeout,Worker,info}
 end.

info(Worker,Subject)->
 dns_ns:pid(Worker)!{self(),{info,Subject}},
 receive
  {Subject,Value} -> Value;
   R->R
  after 10000 -> {timeout,Worker,info}
 end.

info()->
 lists:map(fun(N)->
                 Worker =  name(N),
                #{no     => N, 
                  pid    => dns_ns:set(Worker), 
                  info   => info(Worker), 
                  worker => Worker
                 } 
           end,
           lists:seq(1,?WORKERS_NUM)
          ).

name(N)->
 list_to_atom(atom_to_list(?MODULE)++"_"++integer_to_list(N)). 

change_id({dns_header,ID,_,_,_,_,_,_,_,_},
          {dns_header,_,B1,query,B2,B3,B4,B5,B6,Int})->
    {dns_header,ID,true,query,B2,B3,B4,B5,B6,Int}.% set QR also 

dets_resolve(Header,Name,Type,Class)->
          dns_dets:g( {Name,Type,Class},
          fun({Name,Type,Class})->
              % use random two servers for ask's resolving 
              %RU_SERVER = case rand:uniform(length(?RU_SERVERS)) of 
              %                        N-> lists:nth(N,?RU_SERVERS)
              %                      end,
              %                       
              %FAST_SERVER = case rand:uniform(length(?FAST_SERVERS)) of 
              %                        N-> lists:nth(N,?FAST_SERVERS)
              %                      end, 
              SRV = case rand:uniform(length(?TOP_SERVERS)) of 
                                      N-> lists:nth(N,?TOP_SERVERS)
                                    end,
              T1=erlang:system_time(),               
              Ret=try inet_res:resolve(Name,Type,Class,
                                     [{nameservers,
                                       [
 
                                        %{{1,0,0,1},53}
                                        {SRV,53},
                                        {{1,0,0,1},53}
                                        %{FAST_SERVER,53},
                                        %{RU_SERVER,53}

                                       ] 
                                        %{{77,88,8,8},53},{{77,88,8,7},53},{{1,1,1,1},53}]
                                      }
                                     ]
                                  ) of
              {ok,R0}-> 
                       inet_dns:encode(R0);
               R    -> 
                       negative(Header,Name,Class,Type)
              catch
               Err:Reason -> %io:format("~p:~p catch negative ~p~n",[?MODULE,?LINE,{Err,Reason}]),
                             negative(Header,Name,Class,Type)
              end,
              Time_Diff=erlang:system_time()-T1,
              logger:critical(#{resolve_time_ms => Time_Diff/1000000,server => SRV, point => ?POINT}),
              Ret 
          end
             ).

% negative reply, like not_found
negative(Header,Name,Type,Class)->
 % it needs set reply bit in header 
 inet_dns:encode({dns_rec,Header,[{dns_query,Name,Type,Class}],[],[],[]}).

%%====================================================================
%% Tests
%%====================================================================

%test() ->
%    ?assert(test(0) =:= 0),
%    ?assert(test(1) =:= 1),
%    ?assert(test(2) =:= 1).
