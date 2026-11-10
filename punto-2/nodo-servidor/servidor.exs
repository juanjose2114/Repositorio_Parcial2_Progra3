Code.require_file(Path.join(__DIR__, "../../punto-1/sismos.exs"))
#traemos codigo del punto 1 para evitar duplicar trabajo innecesariamente

defmodule Servidor do
  @ruta_ciudades Path.join(__DIR__, "resources/ciudades.txt")
  @ruta_movimientos Path.join(__DIR__, "resources/movimientos.txt")

  #structure usuario
  defmodule Usuario do
    defstruct [:id, :nombre]
  end

  def main do
    Process.register(self(), :servicio_sismos)

    IO.puts("Nodo servidor #{Node.self()} escuchando como :servicio_sismos")
    atender_solicitudes()
  end

  #loop que atiende solicitudes
  defp atender_solicitudes do
    #{destino de solicitud, que se solicita}
    receive do

      {destino, {:reporte_ciudad, id_ciudad}} ->
        IO.puts("peticion reporte de ciudad")
        send(destino, reporte_ciudad(id_ciudad))
        atender_solicitudes()

      {destino, :reporte_general} ->
        IO.puts("peticion reporte general")
        send(destino, reporte_general())
        atender_solicitudes()

      {destino, :fin} ->
        IO.puts("fin")
        send(destino, :fin)
        atender_solicitudes() #espera nuevos usuarios
    end
  end

  defp reporte_ciudad(id_ciudad) do
    case leer_datos() do
      {:ok, datos} -> Sismos.reporte_ciudad(datos, id_ciudad)
      {:error, mensaje} -> mensaje
    end
  end

  defp procesar_reporte_general do
    resultados = leer_concurrente()

    case {resultados.ciudades, resultados.movimientos} do
      {{:ok, lc}, {:ok, lm}} ->
        {ciudades, rech_c} = Sismos.parsear_ciudades(lc)
        ids = MapSet.new(Enum.map(ciudades, & &1.id))
        {movs, rech_m} = Sismos.parsear_movimientos(lm, ids)
        Sismos.generar_reporte(ciudades, movs, rech_c, rech_m)

      {{:error, _}, _} -> "Error al leer archivo de ciudades"
      {_, {:error, _}} -> "Error al leer archivo de movimientos"
    end
  end

  defp leer_datos do
    coordinador = self()
    ref = make_ref()

    spawn(fn -> send(coordinador, {ref, :ciudades, leer_archivo(@ruta_ciudades)}) end)
    spawn(fn -> send(coordinador, {ref, :movimientos, leer_archivo(@ruta_movimientos)}) end)

    recibir_resultados(ref, %{})
  end

  defp recibir_resultados(ref, acc) when map_size(acc) == 2, do: acc

  defp recibir_resultados(ref, acc) do
    receive do
      {^ref, :ciudades, res} -> recibir_resultados(ref, Map.put(acc, :ciudades, res))
      {^ref, :movimientos, res} -> recibir_resultados(ref, Map.put(acc, :movimientos, res))
    end
  end

  defp leer_archivo(ruta) do
    case File.read(ruta) do
      {:ok, contenido} -> {:ok, String.split(contenido, "\n")}
      {:error, motivo} -> {:error, motivo}
    end
  end

end

Servidor.main()
