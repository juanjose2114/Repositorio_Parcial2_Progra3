Code.require_file(Path.join(__DIR__, "../../punto-1/sismos.exs"))

defmodule Servidor do
  @ruta_ciudades Path.join(__DIR__, "resources/ciudades.txt")
  @ruta_movimientos Path.join(__DIR__, "resources/movimientos.txt")

  defmodule Usuario do
    defstruct [:id, :nombre]
  end

  def main do
    Process.register(self(), :servicio_sismos)
    IO.puts("Nodo servidor #{Node.self()} escuchando como :servicio_sismos")
    atender_solicitudes()
  end

  defp atender_solicitudes do
    receive do
      {destino, {:reporte_ciudad, id_ciudad}} ->
        IO.puts("peticion reporte de ciudad")
        send(destino, reporte_ciudad(id_ciudad))
        atender_solicitudes()

      {destino, :reporte_general} ->
        IO.puts("peticion reporte general")
        send(destino, procesar_reporte_general())
        atender_solicitudes()

      {destino, :fin} ->
        IO.puts("fin")
        send(destino, :fin)
        atender_solicitudes()
    end
  end

  defp reporte_ciudad(id_ciudad) do
    case leer_datos() do
      {:ok, %{ciudades: {:ok, lc}, movimientos: {:ok, lm}}} ->
        {ciudades, _} = Sismos.parsear_ciudades(lc)
        ids = MapSet.new(Enum.map(ciudades, & &1.id))
        {movs, _} = Sismos.parsear_movimientos(lm, ids)

        case Enum.find(ciudades, fn c -> c.id == id_ciudad end) do
          nil ->
            "La ciudad no está registrada"
          ciudad ->
            movs_ciudad = Enum.filter(movs, fn m -> m.id_ciudad == id_ciudad end)
            # IMPORTANTE: Requiere que reporte_ciudad sea `def` en sismos.exs
            Sismos.reporte_ciudad(ciudad, movs_ciudad)
        end

      {:ok, %{ciudades: {:error, _}}} -> "Error al leer archivo de ciudades"
      {:ok, %{movimientos: {:error, _}}} -> "Error al leer archivo de movimientos"
    end
  end

  defp procesar_reporte_general do
    case leer_datos() do
      {:ok, %{ciudades: {:ok, lc}, movimientos: {:ok, lm}}} ->
        {ciudades, rech_c} = Sismos.parsear_ciudades(lc)
        ids = MapSet.new(Enum.map(ciudades, & &1.id))
        {movs, rech_m} = Sismos.parsear_movimientos(lm, ids)
        # IMPORTANTE: Requiere que generar_reporte sea `def` en sismos.exs
        Sismos.generar_reporte(ciudades, movs, rech_c, rech_m)

      {:ok, %{ciudades: {:error, _}}} -> "Error al leer archivo de ciudades"
      {:ok, %{movimientos: {:error, _}}} -> "Error al leer archivo de movimientos"
    end
  end

  defp leer_datos do
    coordinador = self()
    ref = make_ref()

    spawn(fn -> send(coordinador, {ref, :ciudades, leer_archivo(@ruta_ciudades)}) end)
    spawn(fn -> send(coordinador, {ref, :movimientos, leer_archivo(@ruta_movimientos)}) end)

    # Envolvemos el resultado final en {:ok, _} para que los case lo atrapen fácil
    {:ok, recibir_resultados(ref, %{})}
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
