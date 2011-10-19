-module(web).

-export([
	out/1
]).

-include_lib("yaws/include/yaws.hrl").
-include_lib("yaws/include/yaws_api.hrl").

out(Arg) ->
	case prepare(Arg) of
		ok ->
			process(Arg);
		Error ->
			{html, Error}
	end.
	
prepare(_Arg) ->
	case {ok, true} of % dirty dirty
		{ok, true} ->
			case make:all([load]) of
				up_to_date ->
					ok;
				error ->
					"Recompile error."
			end;
		_ ->
			ok
	end.

process(Arg) ->
	% Eat em cookies

	% Cookies = Arg#arg.headers#headers.cookie,
	
	% Prepare user data
	
	% UID = case yaws_api:find_cookie_val("auth", Cookies) of
	%	[] -> 0;
	%	AC ->
	%		case fisbb_auth:cookie(AC) of
	%			PUID when is_integer(PUID) ->
	%				fisbb_user:prepare_data(PUID),
	%				PUID;
	%			_ -> 0
	%		end
	% end,
	put(uid, 1),
	
	% What now?

	Tok = string:tokens(string:strip(Arg#arg.appmoddata, both, $/), "/"),
	
	% case Tok of

	%	["!", Modname, Function |_] ->
	%		Module = list_to_existing_atom("fisbb_" ++ Modname),
	%		{ok, {struct, Params}} = json:decode_string(binary_to_list(Arg#arg.clidata)),
	%		Res = try
	%			Module:rpc(Function, Params, Arg)
	%		catch
	%			exit:{return, Ret} ->
	%				Ret;
	%			ET:EV ->
	%				io:format("~p ~p ~p ~p", [{Module, Function, Params}, ET, EV, erlang:get_stacktrace()]),
	%				{error, fisbb_lang:t("System error")}
	%		end,
	%		case Res of
	%			{_, _} ->
	%				{html, json:encode({struct, [Res]})};
	%			_ ->
	%				{html, json:encode({struct, Res})}
	%		end;
	%		
	%	_ ->
			case Tok of
				[Modname | Params] ->
					ok;
				[] ->
					{Modname, Params} = {"upload", []}
			end,
			Module = get_module(Modname),
			
			try
				Module:work(Params, Arg)
			catch
				exit:{return, Ret} ->
					Ret;
				ET:EV ->
					io:format("~p ~p ~p ~p", [{Module, work, Params}, ET, EV, erlang:get_stacktrace()]),
					"System error"
			end
			
	% end
.

get_module("upload") ->
	upload;
get_module("longpoll") ->
	http_push;
get_module(Modname) ->
	list_to_existing_atom("example_" ++ Modname).
