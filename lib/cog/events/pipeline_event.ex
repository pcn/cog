defmodule Cog.Events.PipelineEvent do
  @moduledoc """
  Provides functions for generating command pipeline execution events.
  """

  # ISO-8601 UTC
  @date_format "~.4.0w-~.2.0w-~.2.0wT~.2.0w:~.2.0w:~.2.0wZ"

  @typedoc """
  One of the valid kinds of events that can be emitted by a pipeline
  """
  @type event_label :: :pipeline_initialized |
                       :command_dispatched |
                       :pipeline_succeeded |
                       :pipeline_failed

  @typedoc """
  Encapsulates information about command pipeline execution events.

  # Fields

  * `pipeline_id`: The unique identifier of the pipeline emitting the
  event. Can be used to correlate events from the same pipeline
  instance.

  * `event`: label indicating which pipeline lifecycle event is being
  recorded.

  * `timestamp`: When the event was created, in UTC, as an ISO-8601
  extended-format string (e.g. `"2016-01-07T15:08:00Z"`). For
  pipelines that execute in sub-second time, also see
  `elapsed_microseconds`.

  * `elapsed_microseconds`: Number of microseconds elapsed since
  beginning of pipeline execution to the creation of this event. Can
  be used to order events from a single pipeline.

  * `data`: Map of arbitrary event-specific data. See below for details.


  # Event-specific Data

  Depending on the type of event, the `data` map will contain
  different keys. These are detailed here for each event.

  ## `pipeline_initialized`

  * `command_text`: (String) the text of the entire pipeline, as typed by the
    user. No variables will have been interpolated or bound at this point.
  * `adapter`: (String) the chat adapter being used
  * `handle`: (String) the adapter-specific chat handle of the user issuing the
    command.

  ## `command_dispatched`

  * `command_text`: (String) the text of the command being dispatched to a
    Relay. In contrast to `pipeline_initialized` above, here,
    variables _have_ been interpolated and bound. If the user
    submitted a pipeline of multiple commands, a `command_dispatched`
    event will be created for each discrete command.
  * `relay`: (String) the unique identifier of the Relay the command was
    dispatched to.

  ## `pipeline_succeeded`

  * `result`: (JSON) the JSON structure that resulted from the successful
    completion of the entire pipeline. This is the raw data produced
    by the pipeline, prior to any template application.

  ## `pipeline_failed`

  * `error`: (String) a symbolic name of the kind of error produced
  * `message`: (String) Additional information and detail about
    the error

  """
  @type t :: %__MODULE__{pipeline_id: String.t,
                         event: event_label,
                         timestamp: String.t,
                         elapsed_microseconds: non_neg_integer(),
                         data: map}
  defstruct [
    pipeline_id: nil,
    event: nil,
    timestamp: nil,
    elapsed_microseconds: 0,
    data: %{}
  ]

  @doc """
  Create a `pipeline_initialized` event
  """
  def initialized(pipeline_id, text, adapter, handle) do
    new(pipeline_id, :pipeline_initialized, 0, %{command_text: text,
                                                 adapter: adapter,
                                                 chat_handle: handle})
  end

  @doc """
  Create a `command_dispatched` event
  """
  def dispatched(pipeline_id, elapsed, command, relay) do
    new(pipeline_id, :command_dispatched, elapsed, %{command_text: command,
                                                     relay: relay})
  end

  @doc """
  Create a `pipeline_succeeded` event
  """
  def succeeded(pipeline_id, elapsed, result),
    do: new(pipeline_id, :pipeline_succeeded, elapsed, %{result: result})

  @doc """
  Create a `pipeline_failed` event
  """
  def failed(pipeline_id, elapsed, error, message) do
    new(pipeline_id, :pipeline_failed, elapsed, %{error: error,
                                                  message: message})
  end

  # Centralize common event creation logic
  defp new(pipeline_id, label, elapsed, data) do
    %__MODULE__{pipeline_id: pipeline_id,
                event: label,
                elapsed_microseconds: elapsed,
                timestamp: now_iso8601_utc,
                data: data}
  end

  # Current time, as an ISO-8601 formatted string
  defp now_iso8601_utc do
    {{year, month, day}, {hour, min, sec}} = :calendar.universal_time
    :io_lib.format(@date_format, [year, month, day, hour, min, sec])
    |> IO.iodata_to_binary
  end

end