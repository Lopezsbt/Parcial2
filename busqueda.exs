Code.require_file("structs.exs")

defmodule Busqueda do
  def encontrar_rutas(filas, terrenos_map) do
    {inicio_r, inicio_c} = encontrar_simbolo(filas, "P", 0)
    {bote_r, bote_c} = encontrar_simbolo(filas, "B", 0)

    buscar_recursivo({inicio_r, inicio_c}, {bote_r, bote_c}, filas, terrenos_map, [{inicio_r, inicio_c}], 0)
  end

  defp encontrar_simbolo(filas, objetivo, r) do
    fila = Enum.at(filas, r)
    case buscar_en_fila(fila, objetivo, 0) do
      {:ok, c} -> {r, c}
      :error -> encontrar_simbolo(filas, objetivo, r + 1)
    end
  end

  defp buscar_en_fila([], _objetivo, _c), do: :error
  defp buscar_en_fila([sim | resto], objetivo, c) do
    if sim == objetivo, do: {:ok, c}, else: buscar_en_fila(resto, objetivo, c + 1)
  end

  defp buscar_recursivo(actual, objetivo, filas, terrenos_map, camino, costo_acumulado) do
    if actual == objetivo do
      [%Ruta{posiciones: Enum.reverse(camino), costo: costo_acumulado}]
    else
      {r, c} = actual
      movimientos = [{r - 1, c}, {r + 1, c}, {r, c - 1}, {r, c + 1}]

      Enum.flat_map(movimientos, fn {nr, nc} ->
        case obtener_celda(filas, nr, nc) do
          nil -> []
          simbolo ->
            case Map.get(terrenos_map, simbolo) do
              %Terreno{transitable: "si"} = terreno ->
                if not Enum.member?(camino, {nr, nc}) do
                  nuevo_camino = [{nr, nc} | camino]
                  nuevo_costo = costo_acumulado + terreno.costo
                  buscar_recursivo({nr, nc}, objetivo, filas, terrenos_map, nuevo_camino, nuevo_costo)
                else
                  []
                end
              _ ->
                []
            end
        end
      end)
    end
  end

  defp obtener_celda(filas, r, c) do
    with fila when not is_nil(fila) <- Enum.at(filas, r) do
      Enum.at(fila, c)
    end
  end
end
