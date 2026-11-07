defmodule Consultas do
  def ejecutar(grafo, archivo, carpeta) do
    if File.exists?(archivo) do
      archivo_rutas = Path.join(carpeta, "rutas_encontradas.txt")
      archivo_alcance = Path.join(carpeta, "alcance.txt")

      File.write(archivo_rutas, "")
      File.write(archivo_alcance, "")

      case File.open(archivo_rutas, [:write, :utf8]) do
        {:ok, salida} ->
          consultas =
            File.stream!(archivo)
            |> Stream.with_index(1)
            |> Stream.reject(fn {linea, _numero} ->
              contenido = String.trim(linea)
              contenido == "" or String.starts_with?(contenido, "#")
            end)
            |> Enum.to_list()

          procesar_consultas(
            consultas,
            grafo,
            salida,
            archivo_alcance,
            1
          )

          File.close(salida)

        {:error, motivo} ->
          IO.puts("No se pudo crear el archivo de rutas: #{motivo}")
      end
    else
      IO.puts("No existe el archivo #{archivo}")
    end
  end

  defp procesar_consultas([], _grafo, _salida, _archivo_alcance, _numero) do
    :ok
  end

  defp procesar_consultas(
         [{linea, numero_linea} | resto],
         grafo,
         salida,
         archivo_alcance,
         numero
       ) do
    case String.split(String.trim(linea), ",") do
      [origen, destino] ->
        origen = String.trim(origen)
        destino = String.trim(destino)

        escribir(salida, "\nCONSULTA #{numero}: #{origen} -> #{destino}")

        cond do
          origen == "" or destino == "" ->
            escribir(salida, "La consulta de la línea #{numero_linea} tiene campos vacíos.")

          not Grafo.existe_ciudad?(grafo, origen) ->
            escribir(salida, "La ciudad #{origen} no existe en el grafo.")

          not Grafo.existe_ciudad?(grafo, destino) ->
            escribir(salida, "La ciudad #{destino} no existe en el grafo.")

          true ->
            case Alcance.calcular(grafo, origen, archivo_alcance) do
              {:ok, alcanzadas} ->
                if MapSet.member?(alcanzadas, destino) do
                  rutas = buscar_rutas(grafo, origen, destino, [origen], 0)
                  mostrar_rutas(rutas, salida)
                else
                  escribir(salida, "No existen rutas entre #{origen} y #{destino}.")
                end

              {:error, motivo} ->
                escribir(salida, motivo)
            end
        end

      _ ->
        escribir(
          salida,
          "La consulta de la línea #{numero_linea} debe contener origen y destino."
        )
    end

    procesar_consultas(
      resto,
      grafo,
      salida,
      archivo_alcance,
      numero + 1
    )
  end

  defp buscar_rutas(grafo, actual, destino, visitadas, distancia) do
    if actual == destino do
      [%Ruta{ciudades: Enum.reverse(visitadas), distancia: distancia}]
    else
      buscar_en_vecinos(
        Grafo.vecinos(grafo, actual),
        grafo,
        destino,
        visitadas,
        distancia
      )
    end
  end

  defp buscar_en_vecinos([], _grafo, _destino, _visitadas, _distancia) do
    []
  end

  defp buscar_en_vecinos(
         [{vecino, distancia_conexion} | resto],
         grafo,
         destino,
         visitadas,
         distancia
       ) do
    rutas =
      if vecino in visitadas do
        []
      else
        buscar_rutas(
          grafo,
          vecino,
          destino,
          [vecino | visitadas],
          distancia + distancia_conexion
        )
      end

    rutas ++
      buscar_en_vecinos(
        resto,
        grafo,
        destino,
        visitadas,
        distancia
      )
  end

  defp mostrar_rutas([], salida) do
    escribir(salida, "No se encontraron rutas.")
  end

  defp mostrar_rutas(rutas, salida) do
    rutas
    |> Enum.with_index(1)
    |> Enum.each(fn {ruta, numero} ->
      ciudades = Enum.join(ruta.ciudades, " -> ")

      escribir(
        salida,
        "Ruta #{numero}: #{ciudades} | Ciudades: #{length(ruta.ciudades)} | Distancia: #{ruta.distancia} km"
      )
    end)

    escribir(salida, "Número total de rutas: #{length(rutas)}")

    menor_cantidad =
      rutas
      |> Enum.map(fn ruta -> length(ruta.ciudades) end)
      |> Enum.min()

    escribir(salida, "Rutas con menos ciudades:")

    rutas
    |> Enum.filter(fn ruta ->
      length(ruta.ciudades) == menor_cantidad
    end)
    |> Enum.each(fn ruta ->
      escribir(salida, Enum.join(ruta.ciudades, " -> "))
    end)

    menor_distancia = Enum.min_by(rutas, fn ruta -> ruta.distancia end)

    escribir(
      salida,
      "Ruta de menor distancia: #{Enum.join(menor_distancia.ciudades, " -> ")} (#{menor_distancia.distancia} km)"
    )
  end

  defp escribir(salida, mensaje) do
    IO.puts(mensaje)
    IO.puts(salida, mensaje)
  end
end
