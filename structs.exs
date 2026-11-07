defmodule Terreno do
  defstruct [:simbolo, :nombre, :transitable, :costo]
end

defmodule Ruta do
  defstruct [:posiciones, :costo]
end
