Code.require_file(Path.join(__DIR__, "sismos.exs"))
Code.require_file(Path.join(__DIR__, "util.ex"))

defmodule ReporteLocal do

  @ruta_ciudades Path.join(__DIR__, "resources/ciudades.txt")
  @ruta_movimientos Path.join(__DIR__, "resources/movimientos.txt")

  def main do
    resultados = Sismos.leer(@ruta_ciudades,@ruta_movimientos)
    IO.puts(resultados)
  end

end

ReporteLocal.main()
