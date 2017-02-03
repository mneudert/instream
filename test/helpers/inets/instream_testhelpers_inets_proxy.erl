-module(instream_testhelpers_inets_proxy).

-export([do/1]).

do(ModData) ->
    'Elixir.Instream.TestHelpers.Inets.Handler':serve(ModData).
