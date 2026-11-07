System.put_env("ELIXIR_ERL_OPTIONS", "+fnu")
Code.require_file("conexion.exs", __DIR__)
Code.require_file("ruta.exs", __DIR__)
Code.require_file("grafo.exs", __DIR__)
Code.require_file("alcance.exs", __DIR__)
Code.require_file("consultas.exs", __DIR__)

defmodule Programa1 do
  def main do
    carpeta = __DIR__

    archivo_conexiones = Path.join(carpeta, "conexiones.csv")
    archivo_consultas = Path.join(carpeta, "consultas.txt")

    case Grafo.cargar(archivo_conexiones) do
      {:ok, grafo} ->
        IO.puts("Grafo cargado correctamente.")
        Consultas.ejecutar(grafo, archivo_consultas, carpeta)

      {:error, motivo} ->
        IO.puts(motivo)
    end
  end
end

Programa1.main()
