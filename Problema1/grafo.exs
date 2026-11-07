defmodule Grafo do
  def cargar(ruta) do
    if File.exists?(ruta) do
      carpeta = Path.dirname(ruta)
      errores = Path.join(carpeta, "errores_conexiones.txt")
      depuracion = Path.join(carpeta, "depuracion_conexiones.txt")

      with {:ok, conexiones} <- leer_conexiones(ruta, errores),
           {:ok, conexiones} <- depurar(conexiones, depuracion) do
        {:ok, construir(conexiones)}
      end
    else
      {:error, "No existe el archivo #{ruta}"}
    end
  end

  defp leer_conexiones(ruta, archivo_errores) do
    case File.open(archivo_errores, [:write, :utf8]) do
      {:ok, salida} ->
        resultado =
          File.stream!(ruta)
          |> Stream.with_index(1)
          |> Stream.reject(fn {linea, _numero} -> ignorar?(linea) end)
          |> Stream.map(fn {linea, numero} ->
            {String.trim(linea), numero}
          end)
          |> Enum.reduce([], fn {contenido, numero}, acumulador ->
            case Conexion.parse(contenido) do
              {:ok, conexion} ->
                [{conexion, numero, contenido} | acumulador]

              {:error, motivo} ->
                IO.puts(
                  salida,
                  "Línea #{numero}: #{contenido} | Motivo: #{motivo}"
                )

                acumulador
            end
          end)

        File.close(salida)
        {:ok, Enum.reverse(resultado)}

      {:error, motivo} ->
        {:error, "No se pudo crear el archivo de errores: #{motivo}"}
    end
  end

  defp ignorar?(linea) do
    contenido = String.trim(linea)
    contenido == "" or String.starts_with?(contenido, "#")
  end

  defp depurar(conexiones, archivo) do
    case File.open(archivo, [:write, :utf8]) do
      {:ok, salida} ->
        resultado = depurar_recursivo(conexiones, [], salida)
        File.close(salida)
        {:ok, resultado}

      {:error, motivo} ->
        {:error, "No se pudo crear el archivo de depuración: #{motivo}"}
    end
  end

  defp depurar_recursivo([], aceptadas, _salida) do
    Enum.reverse(aceptadas)
  end

  defp depurar_recursivo(
         [{conexion, numero, contenido} | resto],
         aceptadas,
         salida
       ) do
    cond do
      conexion.origen == conexion.destino ->
        IO.puts(
          salida,
          "Línea #{numero}: #{contenido} -> conecta una ciudad consigo misma; se descarta"
        )

        depurar_recursivo(resto, aceptadas, salida)

      true ->
        case buscar_par(conexion, aceptadas) do
          nil ->
            depurar_recursivo(
              resto,
              [{conexion, numero} | aceptadas],
              salida
            )

          {numero_anterior, distancia_anterior} ->
            if conexion.distancia == distancia_anterior do
              IO.puts(
                salida,
                "Línea #{numero}: #{contenido} -> repetida (línea #{numero_anterior}); se descarta"
              )
            else
              IO.puts(
                salida,
                "Línea #{numero}: #{contenido} -> distancia distinta a la de la línea #{numero_anterior} (#{distancia_anterior}); se conserva la de la línea #{numero_anterior}"
              )
            end

            depurar_recursivo(resto, aceptadas, salida)
        end
    end
  end

  defp buscar_par(_conexion, []) do
    nil
  end

  defp buscar_par(conexion, [{anterior, numero} | resto]) do
    mismo_sentido =
      conexion.origen == anterior.origen and
        conexion.destino == anterior.destino

    sentido_contrario =
      conexion.origen == anterior.destino and
        conexion.destino == anterior.origen

    if mismo_sentido or sentido_contrario do
      {numero, anterior.distancia}
    else
      buscar_par(conexion, resto)
    end
  end

  defp construir(conexiones) do
    construir_recursivo(conexiones, %{})
  end

  defp construir_recursivo([], grafo) do
    grafo
  end

  defp construir_recursivo([{conexion, _numero} | resto], grafo) do
    grafo =
      agregar(grafo, conexion.origen, conexion.destino, conexion.distancia)

    grafo =
      agregar(grafo, conexion.destino, conexion.origen, conexion.distancia)

    construir_recursivo(resto, grafo)
  end

  defp agregar(grafo, origen, destino, distancia) do
    vecinos = Map.get(grafo, origen, [])
    Map.put(grafo, origen, [{destino, distancia} | vecinos])
  end

  def existe_ciudad?(grafo, ciudad) do
    Map.has_key?(grafo, ciudad)
  end

  def vecinos(grafo, ciudad) do
    Map.get(grafo, ciudad, [])
  end
end
