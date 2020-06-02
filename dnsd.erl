-module(dnsd).
-include("common.hrl").

-include_lib("eunit/include/eunit.hrl").
-behaviour(gen_server).

-define(SERVER, ?MODULE).
-define(PORT,53).

%%%
%%
%%%

-export([start_link/0,start_link/1,
	 start/0]).

-export([init/1, 
	 handle_call/3,
	 handle_cast/2,
	 handle_info/2,
	 terminate/2,
	 code_change/3]).
	 
-export([init_workers/0,rand_node/1,info/0,info/1]).
%%====================================================================
%% API
%%====================================================================
start()-> logger:?TRACE_POINTS_LEVEL(?POINT_ARG(#{subject => start, 
                                       list => application:ensure_all_started(?MODULE)
                                      })
                         ),ok.

start_link() ->
    %dns_queue:start_link(),
    %logger:?TRACE_POINTS_LEVEL(#{ point => ?POINT_ARG(start_link) }),
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

start_link(N) ->
    %dns_queue:start_link(),
    %logger:?TRACE_POINTS_LEVEL(#{ point => ?POINT_ARG(start_link) , n => N}),
    gen_server:start_link({global, list_to_atom(atom_to_list(?MODULE)++"_"++integer_to_list(N))}, ?MODULE, [], []).

%%====================================================================
%% Gen Server
%%====================================================================
            
init(Args) ->
% try to init remote workers
      init_workers(),
      
       {ok,S}=inet_udp:open(?PORT,[binary,
                                        {active,true},
                                        {reuseaddr,true}
                                        ]
                                ),
    {ok, #{listener => S, args => Args, listener_name => ?MODULE}}.

handle_call({Ask, Arg}, _From, State) ->
    logger:?TRACE_POINTS_LEVEL(#{ask => Ask, arg => Arg, point => ?POINT_ARG(handle_call) }),
    {reply, {ok, "Reply"}, State};

handle_call(What, _From, State) ->
    logger:?TRACE_POINTS_LEVEL(#{ask => What, point => ?POINT_ARG(handle_call) , subject => unexpected }),
    {reply, {error, What}, State}.

handle_cast(What, State) ->
     logger:?TRACE_POINTS_LEVEL(#{ask => What, point => ?POINT_ARG(handle_cast) , subject => unexpected }),
     {noreply, State}.

% handle asks about listener info
handle_info({worker_reply,{Socket,Client,Port,Reply}},State)->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT , reply => Reply, to_client => {Client,Port}, subject => "get reply and pass it to clinet", state => State , decoded => inet_dns:decode(Reply) }),
    S=maps:get(listener,State),
    %gen_udp:connect(S,Client,Port),
    %R = gen_udp:send(S,Reply),
    %R=prim_inet:sendto(Socket, {Client, Port}, [], Reply),
    R=?SEND(Socket,Client,Port,Reply),
                                
    logger:critical(#{send => R, point => ?POINT, socket => Socket}),
    {noreply, State};
    
handle_info({Pid,info}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info {Pid,info} ask" , ask => info, state => State }),
    {ok,SocketStat} = inet:getstat(maps:get(listener,State)),
    Pid!#{process_info => erlang:process_info(self()), socket_stat => SocketStat, state => State, socket => maps:get(listener,State)},  
    {noreply, State};

handle_info({Pid,{info,Subject}}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info {Pid,info} ask" , ask => info, state => State }),
    Pid!erlang:process_info(self(),Subject),  
    {noreply, State};
    
% handle incoming UDP traffic
handle_info({udp,Sock,IP,Port,Msg}, State) ->
     logger:?TRACE_POINTS_LEVEL(#{ask => {IP,Port,Msg}, point => ?POINT_ARG(handle_info) , subject => "handle incoming ask from client" }),

%     try global:whereis_name(dns_queue_1)!{udp,Sock,IP,Port,Msg} of
     try dns_ns:pid(dns_queue_1)!{udp,Sock,IP,Port,Msg} of
      R-> R 
     catch
      Err:Reason -> logger:critical(#{point => ?POINT_ARG({?MODULE,?LINE,"dns_queue_1 is not alive , try to route message to hot spare dns_queue_2"})}),
                    %R1=global:whereis_name(dns_queue_2)!{udp,Sock,IP,Port,Msg},
                    R1=dns_ns:pid(dns_queue_2)!{udp,Sock,IP,Port,Msg},
                    logger:critical(#{point => ?POINT_ARG({?MODULE,?LINE,"was done routing for message to hot spare dns_queue_2"}), result => R1}),
                    ?CATCH_HANDLER({{?MODULE,?LINE},{handle_info,{udp,Sock,IP,Port,Msg}}})
     end,
     {noreply, State};
     
% handle unexpected asks
handle_info(What, State) ->
     logger:?TRACE_POINTS_LEVEL(#{ask => What, point => ?POINT_ARG(handle_info) , subject => unexpected }),
     {noreply, State}.

terminate(Reason, _State) ->
    logger:?TRACE_POINTS_LEVEL(#{ask => Reason, point => ?POINT_ARG(terminate) , subject => unexpected }),
    ok.

code_change(OldVsn, State, Extra) ->
    logger:?TRACE_POINTS_LEVEL(#{ask => {OldVsn, State, Extra}, point => ?POINT_ARG(code_change) , subject => unexpected }),
    {ok, State}.


%%====================================================================
%% Internal functions
%%====================================================================
% depricated and need to remove to dns_handler

do_spawn(Node,M,F,A) -> %spawn(M,F,A).
                   %rpc:call(node(),code,load_file,[M]),
                   %rpc:call(node(),M,F,A).                   
                   %rpc:call(node(),code,load_file,[M]),
                   
                   R=rpc:call(Node,erlang,spawn,[M,F,A]),
                   logger:?TRACE_POINTS_LEVEL(#{point => ?POINT, rpc_at_node => Node, mfa =>{M,F,A}, result => R, subject =>{rpc_call,Node,M,F,A}}),
                   R.

rand_node(WORKERS_NODES)-> lists:nth(rand:uniform(length(WORKERS_NODES)),WORKERS_NODES).

init_workers()->
             lists:map(fun(Nod)-> net_adm:ping(Nod) end, ?WORKERS_NODES),
             %lists:map(fun(Nod)-> net_adm:ping(Nod) end, dns_ns:cluster()),
             
             logger:?TRACE_POINTS_LEVEL(#{point => ?POINT, nodes => [node()|nodes()], names => net_adm:names() ,subject => "init workers" }),   

             lists:map(fun(N)-> dns_ns:set(dns_workers,N, do_spawn(rand_node(?WORKERS_NODES
                                                                           %dns_ns:cluster()
                                                                          ),
                                                                 dns_workers,
                                                                 start_link,
                                                                 [N]
                                                                )
                                             ) 
                           end,
                           lists:seq(1,?WORKERS_NUM)
                          ),
             logger:critical(#{point => ?POINT, pids => dns_ns:pids() }).
                          
% run worker_{N} as {ok,Pid}=rpc:call(Node,dns_workers,start_link,[N])

info()->
% global:whereis_name(?MODULE)!{self(),info},
 dns_ns:pid(?MODULE)!{self(),info},
 receive
  R->R
  after 5000 -> {timeout,?MODULE,info}
 end.

info(Subject)->
% global:whereis_name(?MODULE)!{self(),info,Subject},
 dns_ns:pid(?MODULE)!{self(),info,Subject},
 receive
  {Subject,R}->R
  after 5000 -> {timeout,?MODULE,info,Subject}
 end.
 