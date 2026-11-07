defmodule Alcance do
  def calcular(grafo, origen, archivo) do
    if Grafo.existe_ciudad?(grafo, origen) do
      case File.open(archivo, [:append, :utf8]) do
        {:ok, salida} ->
          conjuntos =
            Stream.iterate(
              MapSet.new([origen]),
              fn alcanzadas -> expandir(grafo, alcanzadas) end
            )
            |> Stream.with_index()

          resultado =
            Enum.reduce_while(conjuntos, nil, fn {conjunto, paso}, anterior ->
              ciudades =
                conjunto
                |> MapSet.to_list()
                |> Enum.sort()
                |> Enum.join(", ")

              IO.puts(salida, "Paso #{paso}: #{ciudades}")

              if anterior == conjunto do
                IO.puts(salida, "Estabilización en el paso #{paso - 1}")
                {:halt, conjunto}
              else
                {:cont, conjunto}
              end
            end)

          File.close(salida)
          {:ok, resultado}

        {:error, motivo} ->
          {:error, "No se pudo crear el archivo de alcance: #{motivo}"}
      end
    else
      {:error, "La ciudad #{origen} no existe en el grafo"}
    end
  end

  defp expandir(grafo, alcanzadas) do
    Enum.reduce(alcanzadas, alcanzadas, fn ciudad, acumulado ->
      Enum.reduce(Grafo.vecinos(grafo, ciudad), acumulado, fn {vecino, _distancia}, conjunto ->
        MapSet.put(conjunto, vecino)
      end)
    end)
  end
end
