-module(pt).
-compile(export_all).

t()->
 persistent_term:put(node(),{self(),calendar:local_time()}),
 persistent_term:get().

loop()->
 logger:critical(t()),
 timer:sleep(3000),
 loop().

start()-> spawn(?MODULE,loop,[]). 