-module(hehe).

-export([
	run/1,
	run/2,
	
	init/0,
	out/1,
	return/0
]).

run(File) ->
	run(File, []).

run(File, Arg) ->
	{ok, Src} = file:read_file(File),
	
	random:seed(erlang:now()),
	Modname = list_to_binary("hehe_mod_" ++ re:replace(File, "[/\\:.?\s]", "_", [global])),
	
	TFN = "/tmp/hehe/" ++ binary_to_list(Modname) ++ ".erl",
	
	{IHdr, RSrc} = get_header(Src),
	
	Hdr = <<
		<<"-module(">>/binary, Modname/binary, <<").">>/binary, $\n,
		<<"-export([out/1]).\n-include_lib(\"erlongpoll/example/hehe.hrl\").">>/binary, $\n,
		IHdr/binary, $\n,
		<<"out(Arg) -> hehe:init(), ">>/binary
	>>,
	
	Code = lists:reverse(parse_html(RSrc, [])),
	
	%io:format("~p~n", [Code]),
	
	Fin = [Hdr, Code, <<"hehe:return().">>],
	
	file:write_file(TFN, Fin),
	file:write_file("/tmp/hehe/last.erl", Fin),
	
	{ok, Mod} = compile:file(TFN, [return_errors]),
	code:purge(Mod),
	{module, Mod} = code:load_file(Mod),
	Mod:out(Arg).
	
get_header(Src) ->
	case binary:part(Src, 0, 3) of
		<<$<,$?,$?>> ->
			[H, R] = binary:split(Src, <<$?,$?,$>>>),
			{binary:part(H, 3, byte_size(H) - 3), R};
		_ ->
			{<<"">>, Src}
	end.
	
add_html(P, Cur) ->
	["hehe:out(" ++ io_lib:format("~w", [binary_to_list(P)]) ++ "), \n" | Cur].
	
parse_html(Src, Cur) ->
	case binary:match(Src, <<$<,$?>>) of
		{I, _} ->
			P = binary:part(Src, 0, I),
			parse_erl(
				binary:part(Src, I + 2, byte_size(Src) - I - 2),
				add_html(P, Cur)
			);
		_ ->
			add_html(Src, Cur)
	end.
	
add_erl(P, Cur) ->
	case binary:at(P, 0) of
		$= ->
			["hehe:out(" ++ binary_to_list(binary:part(P, 1, byte_size(P) - 1)) ++ "), \n" | Cur];
		_ ->
			[binary_to_list(P) ++ ", \n" | Cur]
	end.
	
parse_erl(Src, Cur) ->
	case binary:match(Src, <<$?,$>>>) of
		{I, _} ->
			P = binary:part(Src, 0, I),
			parse_html(
				binary:part(Src, I + 2, byte_size(Src) - I - 2),
				add_erl(P, Cur)
			);
		_ ->
			add_erl(Src, Cur)
	end.
	
	
init() ->
	put(hehe_buf, []).

out(Int) when is_integer(Int) ->
	out(integer_to_list(Int));
out(Atom) when is_atom(Atom) ->
	out(atom_to_list(Atom));
out(Str) ->
	put(hehe_buf, [Str | get(hehe_buf)]).
	
return() ->
	lists:flatten(lists:reverse(get(hehe_buf))).
