defmodule Instream.TestHelpers.HackneyPool do
  defdelegate start(),              to: :hackney_pool
  defdelegate checkin(ref, socket), to: :hackney_pool
  defdelegate notify(pool, msg),    to: :hackney_pool

  def checkout(host, port, transport, client) do
    http_opts = elem(client, 7)

    if :instream_test_sleeper == http_opts[:pool] do
      :timer.sleep(100)
    end

    :hackney_pool.checkout(host, port, transport, client)
  end
end
