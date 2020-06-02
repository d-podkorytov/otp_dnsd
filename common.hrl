-define(POINT,#{ module_line => {?MODULE,?LINE}, node => node(), pid => self() , local_time => calendar:local_time() , function_name => atom_to_list(?MODULE)++":"++atom_to_list(?FUNCTION_NAME)++"/"++integer_to_list(?FUNCTION_ARITY) }).

-define(POINT_ARG(MSG),#{ point =>?POINT , arg => MSG}).

-define(TRACE_POINTS_LEVEL,debug).

-define(CATCH_HANDLER(Info),
              logger:critical(#{ current_stacktrace =>  process_info(self(),current_stacktrace), info => Info, point => ?POINT_ARG("catch inside try")}),      
              #{err => Err, reason => Reason, backtrace => process_info(self(),current_stacktrace), info => Info, point => ?POINT_ARG("catch inside try")}). 

-define(CATCH_HANDLER_FA(F,A),?CATCH_HANDLER({?MODULE,F,A})).

-define(WORKERS_NUM,4).
-define(WORKERS_NODES,['workers_1@de.de','workers_2@de.de']).

-define(SEND(Socket,Client, Port, Reply),prim_inet:sendto(Socket, {Client, Port}, [], Reply)).

-define(TOP_SERVERS,
[  

{77,88,8,8},
{77,88,8,7},

{1,1,1,1}, 
{1,0,0,1},

%Google 
{8,8,8,8},{8,8,4,4},
%Quad9 
{9,9,9,9},{149,112,112,112},
%OpenDNS Home 
{208,67,222,222},{208,67,220,220},
%Cloudflare 
{1,1,1,1},{1,0,0,1},
%CleanBrowsing 
{185,228,168,9},{185,228,169,9},
%Verisign 
{64,6,64,6},{64,6,65,6},
%Alternate DNS 
{198,101,242,72},{23,253,163,53},
%AdGuard DNS 
{176,103,130,130},{176,103,130,131},

% Yandex
{77,88,8,8},
{77,88,8,7}
 
]).
                    