-module(lmdb_test).

-include_lib("eunit/include/eunit.hrl").

open_test_db() ->
    {ok, CWD} = file:get_cwd(),
    DataDir = filename:join([CWD, "data", "eunit"]),
    ?cmd("rm -rf " ++ DataDir),
    ?assertMatch(ok, filelib:ensure_dir(filename:join([DataDir, "x"]))),
    {ok, Handle} = lmdb:open(DataDir, 2147483648),
    [lmdb:upd(Handle, crypto:hash(sha, <<X>>),
		 crypto:strong_rand_bytes(crypto:rand_uniform(128, 4096))) ||
	X <- lists:seq(1, 10)],
    Handle.

basics_test_() ->
    {setup,
     fun() ->
             H = open_test_db(),
             ?debugFmt("setup: open_test_db.....~p", [H]),
             H
     end,
     fun(Handle) ->
             ok = lmdb:close(Handle)
     end,
     fun(Handle) ->
             {inorder,
              [{"open and close a database",
                fun() ->
                        H = open_test_db(),
                        ?debugFmt("open & clse.... ~p, with: ~p", [H,Handle]),
                        lmdb:close(H)
                end},
               {"create, then drop an empty database",
                fun() ->
                        H  = open_test_db(),
                        ?debugFmt("create & drop.... ~p, with: ~p", [H,Handle]),
                        ?assertMatch(ok, lmdb:drop(Handle))
                end},
               {"create, put an item, get it, then drop the database",
                fun() ->
                        ?debugFmt("create, put, get, drop... ~p",[Handle]),
                        ?assertMatch(ok, lmdb:put(Handle, <<"a">>, <<"apple">>)),
                        ?assertMatch(ok, lmdb:put(Handle, <<"b">>, <<"boy">>)),
                        ?assertMatch(ok, lmdb:put(Handle, <<"c">>, <<"cat">>)),
                        ?assertMatch({ok, <<"apple">>}, lmdb:get(Handle, <<"a">>)),
                        ?assertMatch(ok, lmdb:update(Handle, <<"a">>, <<"ant">>)),
                        ?assertMatch({ok, <<"ant">>}, lmdb:get(Handle, <<"a">>)),
                        ?assertMatch(ok, lmdb:del(Handle, <<"a">>)),
                        ?assertMatch(not_found, lmdb:get(Handle, <<"a">>)),
                        ?assertMatch(ok, lmdb:drop(Handle))
                end}
              ]}
     end}.

