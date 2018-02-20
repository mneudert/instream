defmodule Instream.TestHelpers.Retry do
  def retry(0, _, _, _), do: false

  def retry(timeout, delay, retry_call, retry_test) do
    case retry_test.(retry_call.()) do
      true ->
        true

      false ->
        :timer.sleep(delay)
        retry(timeout - delay, delay, retry_call, retry_test)
    end
  end
end
