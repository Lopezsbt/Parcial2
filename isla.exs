Code.require_file("structs.exs")
Code.require_file("validador.exs")
Code.require_file("busqueda.exs")

defmodule Main do
  def ejecutar do
    terrenos_map =
      if File.exists?("terrenos.csv") do
        "terrenos.csv"
        |> File.stream!()
        |> Stream.map(&String.replace(&1, "\uFEFF", ""))
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
        |> Stream.map(fn linea ->
          case String.split(linea, ",") do
            [simbolo, nombre, transitable, costo] ->
              sim = String.trim(simbolo)
              {sim, %Terreno{
                simbolo: sim,
                nombre: String.trim(nombre),
                transitable: String.trim(transitable),
                costo: String.to_integer(String.trim(costo))
              }}
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.into(%{})
      else
        IO.puts("Error: El archivo 'terrenos.csv' no existe.")
        %{}
      end

    if map_size(terrenos_map) > 0 do
      if File.exists?("isla.txt") do
        filas =
          "isla.txt"
          |> File.stream!()
          |> Stream.map(&String.replace(&1, "\uFEFF", ""))
          |> Stream.map(&String.trim/1)
          |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
          |> Stream.map(fn linea -> String.split(linea, ~r/\s+/) end)
          |> Enum.to_list()

        case Validador.validar_mapa(filas, terrenos_map) do
          {:error, errores} ->
            IO.puts("El mapa contiene errores. Se reportan en 'validacion_isla.txt'.")
            archivo_err = File.open!("validacion_isla.txt", [:write])
            Enum.each(errores, fn err ->
              IO.binwrite(archivo_err, err <> "\n")
            end)
            File.close(archivo_err)

          {:ok, filas_validas} ->
            IO.puts("¡Mapa válido! Buscando rutas...")
            rutas = Busqueda.encontrar_rutas(filas_validas, terrenos_map)

            if Enum.empty?(rutas) do
              IO.puts("No se encontró ninguna ruta posible hacia el bote.")
            else
              procesar_resultados(rutas, filas_validas)
            end
        end
      else
        IO.puts("Error: El archivo 'isla.txt' no existe.")
      end
    end
  end

  defp procesar_resultados(rutas, filas) do
    rutas_procesadas =
      rutas
      |> Enum.with_index(1)
      |> Enum.map(fn {ruta, idx} ->
        movimientos = length(ruta.posiciones) - 1
        recorrido_str = Enum.map_join(ruta.posiciones, " -> ", fn {r, c} -> "{#{r}, #{c}}" end)
        %{id: idx, movimientos: movimientos, costo: ruta.costo, recorrido: recorrido_str, posiciones: ruta.posiciones}
      end)

    mas_corta = Enum.min_by(rutas_procesadas, & &1.movimientos)
    menor_costo = Enum.min_by(rutas_procesadas, & &1.costo)

    archivo_csv = File.open!("rutas_isla.csv", [:write])
    IO.binwrite(archivo_csv, "ruta;movimientos;costo;recorrido\n")
    Enum.each(rutas_procesadas, fn r ->
      IO.binwrite(archivo_csv, "#{r.id};#{r.movimientos};#{r.costo};#{r.recorrido}\n")
    end)
    File.close(archivo_csv)

    mapa_marcado = marcar_mapa(filas, menor_costo.posiciones)

    archivo_resumen = File.open!("resumen_isla.txt", [:write])
    IO.binwrite(archivo_resumen, "Número total de rutas: #{length(rutas_procesadas)}\n")
    IO.binwrite(archivo_resumen, "Ruta más corta: #{mas_corta.movimientos} movimientos (Ruta #{mas_corta.id})\n")
    IO.binwrite(archivo_resumen, "Ruta de menor costo: costo #{menor_costo.costo} (#{menor_costo.movimientos} movimientos, Ruta #{menor_costo.id})\n\n")
    IO.binwrite(archivo_resumen, "Mapa de la isla con la ruta de menor costo marcada (*):\n")
    IO.binwrite(archivo_resumen, mapa_marcado <> "\n")
    File.close(archivo_resumen)

    IO.puts("¡Proceso finalizado! Archivos 'rutas_isla.csv' y 'resumen_isla.txt' generados con éxito.")
  end

  defp marcar_mapa(filas, posiciones_optimas) do
    filas
    |> Enum.with_index(0)
    |> Enum.map_join("\n", fn {fila, r} ->
      fila
      |> Enum.with_index(0)
      |> Enum.map_join(" ", fn {simbolo, c} ->
        if Enum.member?(posiciones_optimas, {r, c}) and simbolo not in ["P", "B"] do
          "*"
        else
          simbolo
        end
      end)
    end)
  end
end

Main.ejecutar()
