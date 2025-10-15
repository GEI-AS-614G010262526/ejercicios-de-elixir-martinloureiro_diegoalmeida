defmodule ServidoresFederados.Actor do
@moduledoc false


defstruct [:id, :full_name, :avatar, inbox: []]


@type t :: %__MODULE__{
id: String.t(),
full_name: String.t(),
avatar: String.t() | nil,
inbox: list()
}
end
