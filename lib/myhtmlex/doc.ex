defmodule Myhtmlex.Doc do
  defstruct ref: nil, source: nil
end

defimpl Inspect, for: Myhtmlex.Doc do
  import Inspect.Algebra

  def inspect(%Myhtmlex.Doc{source: source}, opts) do
    cut = String.slice(source, 0..60)
    cut = if String.length(cut) < String.length(source) do
      "#{cut}..."
    else
      cut
    end
    concat ["#Myhtmlex.Doc<source: ", to_doc(cut, opts), ">"]
  end
end

