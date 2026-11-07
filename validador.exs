Code.require_file("structs.exs")

defmodule Validador do

  def validar_mapa(filas, terrenos_map) do
    num_filas = length(filas)
    primera_fila = List.first(filas)
    num_cols = if primera_fila, do: length(primera_fila), else: 0

    errores_longitud = verificar_longitudes_rec(filas, num_cols, 1)
    errores_simbolos = verificar_simbolos_rec(filas, terrenos_map, 0)
    {contador_p, contador_b, pos_p, pos_b} = contar_p_y_b_rec(filas, 0, 0, 0, 0, nil, nil)
    errores_pb = verificar_conteo_pb(contador_p, contador_b, pos_p, pos_b)
    errores_borde = verificar_borde_rec(filas, 0, num_filas, num_cols)

    errores = errores_longitud ++ errores_simbolos ++ errores_pb ++ errores_borde

    if Enum.empty?(errores) do
      {:ok, filas}
    else
      {:error, errores}
    end
  end

  defp verificar_longitudes_rec([], _esperado, _n_fila), do: []
  defp verificar_longitudes_rec([fila | resto], esperado, n_fila) do
    actual = length(fila)
    if actual != esperado do
      ["Fila #{n_fila}: tiene #{actual} posiciones; se esperaban #{esperado}"] ++ verificar_longitudes_rec(resto, esperado, n_fila + 1)
    else
      verificar_longitudes_rec(resto, esperado, n_fila + 1)
    end
  end

  defp verificar_simbolos_rec([], _terrenos_map, _r), do: []
  defp verificar_simbolos_rec([fila | resto], terrenos_map, r) do
    verificar_fila_simbolos(fila, terrenos_map, r, 0) ++ verificar_simbolos_rec(resto, terrenos_map, r + 1)
  end

  defp verificar_fila_simbolos([], _terrenos_map, _r, _c), do: []
  defp verificar_fila_simbolos([simbolo | resto_fila], terrenos_map, r, c) do
    if Map.has_key?(terrenos_map, simbolo) do
      verificar_fila_simbolos(resto_fila, terrenos_map, r, c + 1)
    else
      ["Posición {#{r}, #{c}}: símbolo desconocido '#{simbolo}'"] ++ verificar_fila_simbolos(resto_fila, terrenos_map, r, c + 1)
    end
  end

  defp contar_p_y_b_rec([], _r, _c, count_p, count_b, pos_p, pos_b), do: {count_p, count_b, pos_p, pos_b}
  defp contar_p_y_b_rec([fila | resto_filas], r, _c, count_p, count_b, pos_p, pos_b) do
    {cp, cb, pp, pb} = contar_fila_pb(fila, r, 0, count_p, count_b, pos_p, pos_b)
    contar_p_y_b_rec(resto_filas, r + 1, 0, cp, cb, pp, pb)
  end

  defp contar_fila_pb([], _r, _c, count_p, count_b, pos_p, pos_b), do: {count_p, count_b, pos_p, pos_b}
  defp contar_fila_pb([simbolo | resto], r, c, count_p, count_b, pos_p, pos_b) do
    cond do
      simbolo == "P" ->
        p_act = if pos_p, do: pos_p ++ [{r, c}], else: [{r, c}]
        contar_fila_pb(resto, r, c + 1, count_p + 1, count_b, p_act, pos_b)
      simbolo == "B" ->
        b_act = if pos_b, do: pos_b ++ [{r, c}], else: [{r, c}]
        contar_fila_pb(resto, r, c + 1, count_p, count_b + 1, pos_p, b_act)
      true ->
        contar_fila_pb(resto, r, c + 1, count_p, count_b, pos_p, pos_b)
    end
  end

  defp verificar_conteo_pb(cp, cb, pos_p, pos_b) do
    err_p = if cp == 1, do: [], else: ["Hay #{cp} posiciones iniciales P" <> if(pos_p, do: ": " <> inspect(pos_p), else: "")]
    err_b = if cb == 1, do: [], else: ["Hay #{cb} posiciones de bote B" <> if(pos_b, do: ": " <> inspect(pos_b), else: "")]
    err_p ++ err_b
  end

  defp verificar_borde_rec(filas, r, total_filas, total_cols) when r < total_filas do
    fila = Enum.at(filas, r)
    verificar_celdas_borde(fila, r, 0, total_filas, total_cols) ++ verificar_borde_rec(filas, r + 1, total_filas, total_cols)
  end
  defp verificar_borde_rec(_filas, _r, _total_filas, _total_cols), do: []

  defp verificar_celdas_borde([], _r, _c, _tf, _tc), do: []
  defp verificar_celdas_borde([simbolo | resto], r, c, tf, tc) do
    es_borde = (r == 0 or r == tf - 1 or c == 0 or c == tc - 1)
    if es_borde and simbolo != "~" do
      ["Posición {#{r}, #{c}}: el borde debe ser agua y contiene #{simbolo}"] ++ verificar_celdas_borde(resto, r, c + 1, tf, tc)
    else
      verificar_celdas_borde(resto, r, c + 1, tf, tc)
    end
  end
end
