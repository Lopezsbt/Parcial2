defmodule Conexion do
  defstruct [:origen, :destino, :distancia]

  def parse(linea) do
    case String.split(String.trim(linea), ",") do
      [origen, destino, distancia] ->
        origen = String.trim(origen)
        destino = String.trim(destino)
        distancia = String.trim(distancia)

        if origen == "" or destino == "" do
          {:error, "El origen o el destino están vacíos"}
        else
          case Integer.parse(distancia) do
            {valor, ""} when valor >= 0 ->
              {:ok,
               %Conexion{
                 origen: origen,
                 destino: destino,
                 distancia: valor
               }}

            _ ->
              case Float.parse(distancia) do
                {valor, ""} when valor >= 0 ->
                  {:ok,
                   %Conexion{
                     origen: origen,
                     destino: destino,
                     distancia: valor
                   }}

                _ ->
                  {:error, "La distancia no es un número válido o es negativa"}
              end
          end
        end

      _ ->
        {:error, "La línea debe contener tres campos"}
    end
  end
end
