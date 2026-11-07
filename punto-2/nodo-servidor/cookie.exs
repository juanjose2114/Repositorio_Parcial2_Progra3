Code.require_file(Path.join(__DIR__, "util.ex"))

defmodule Cookie do
  @longitud_llave 128

  def main do
    cookie =
      :crypto.strong_rand_bytes(@longitud_llave)
      |> Base.encode64()

    File.write!(Path.join(__DIR__, "cookie"), cookie <> "\n")
    File.write!(Path.join(__DIR__, "../nodo-cliente/cookie"), cookie <> "\n")

    Util.mostrar_mensaje(cookie)
  end
end

Cookie.main()
