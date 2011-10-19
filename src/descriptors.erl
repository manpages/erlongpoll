-module(descriptors).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([start/0, set/2, val/1, del/1]).


start() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%
%
% You have to rewrite those functions for custom description management
%
%%%
val(Key) -> 
	gen_server:call(?MODULE, {val, Key}).

del(Key) -> 
	gen_server:call(?MODULE, {del, Key}).

set(Key, Value) -> 
	gen_server:call(?MODULE, {set, {Key, Value}}).

init([]) ->
	Dict = dict:new(),
	{ok, Dict}.

handle_call(Cmd, _From, Dict) ->
	{Response, NewDict} = case Cmd of
		{val, Key} ->
			case dict:is_key(Key, Dict) of
				true  ->
					{{value, lists:nth(1, dict:fetch(Key, Dict))}, Dict};
				false ->
					{false, Dict}
			end;
		{del, Key} ->
			{ok, dict:erase(Key, Dict)};
		{set, {Key, Value}} ->
			{ok, dict:append(Key, Value, dict:erase(Key, Dict))};
		_ ->
			{error, Dict}
	end,
	{reply, Response, NewDict}.

%Blah-blah-blah
handle_cast(_Message, Dict) -> {noreply, Dict}.
handle_info(_Message, Dict) -> {noreply, Dict}.
terminate(_Reason, _Dict) -> ok.
code_change(_OldVersion, Dict, _Extra) -> {ok, Dict}.
