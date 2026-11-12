Code.require_file(Path.join(__DIR__, "sismos.exs"))
Code.require_file(Path.join(__DIR__, "util.ex"))
#_DIR_ parte del directorio actual (/punto1/)

defmodule ReporteLocal do
  alias Sismos.{Ciudad, Movimiento}
  #abreviamo el llamado a los structs

  #rutas como constantes para evitar proceso de busqueda
  @ruta_ciudades Path.join(__DIR__, "resources/ciudades.txt")
  @ruta_movimientos Path.join(__DIR__, "resources/movimientos.txt")
  @ruta_reporte Path.join(__DIR__, "resources/reporte_sismos.txt")

  def main do

    resultados = Sismos.leer(@ruta_ciudades,@ruta_movimientos)
    #lee archivos

    #errores retorna tupla {archivo, modivo} con los errores del que le manden, case lo lee
    case errores(resultados) do
      [] ->
        #si esta vacio todo bien
        %{ciudades: {:ok, lc}, movimientos: {:ok, lm}} = resultados


        {ciudades, rech_c} = Sismos.parsear_ciudades(lc)
        #parcear ciudades, {lista de ciudades, ciudades rechazadas}

        ids = MapSet.new(Enum.map(ciudades, & &1.id))
        #creamos lista de ids de ciudades <- mapea ciudades, aplica fn c -> c.id

        {movs, rech_m} = Sismos.parsear_movimientos(lm, ids)
        #parcea movimientos contra ids

        reporte = Sismos.generar_reporte(ciudades, movs, rech_c, rech_m, 304314)
        #genera y guarda el reporte con los datos procesados anteriormente

        Util.mostrar_mensaje(reporte)
        #muestra el reporte obio

        guardar_reporte(reporte)
        #termina el proceso guardando el reporte


      errores ->
        #en caso de haber errores en el documento (las lineas vacias no cuentan)
        Enum.each(errores, fn {arch, motivo} ->
          Util.mostrar_error("No fue posible leer #{ruta_archivo(arch)}: #{:file.format_error(motivo)}")
        end)
        #recorre con each, e imprime que paso

        Util.mostrar_mensaje("Se coserva el reporte anterior.")
        #especifica qeu guarda el rrporte anterior
    end

  end

  defp errores(resultados) do
    for {k, v} <- resultados, match?({:error, _}, v), do: {k, elem(v, 1)}
    #deteccion de errores, itera sobre entradas del mapa, no interesa el orden, filtra con match? cuales tienen el valor :error , elem es el motivo
    #devuelve entonces [{:ciudades, motivo}, fallos]
  end

  defp guardar_reporte(reporte) do
    #sobre escribe el reporte actual que esta ubicado en @ruta_reporte
    case File.write(@ruta_reporte, reporte) do
      #File.write sobrescribe el reporte actual

      :ok -> Util.mostrar_mensaje("Reporte guardado en #{@ruta_reporte}")
      #reporta que se guardo el reporte correctamente

      {:error, m} ->
        Util.mostrar_error("No fue posible escribir #{@ruta_reporte}: #{:file.format_error(m)}")
        #informa el error de escritura

    end
  end

  defp ruta_archivo(:ciudades) do
    @ruta_ciudades
  end

  defp ruta_archivo(:movimientos) do
     @ruta_movimientos
  end

end

ReporteLocal.main()
