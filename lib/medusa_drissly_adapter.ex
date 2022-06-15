defmodule Medusa.DrisslyAdapter do
  @moduledoc """
        Documentation for `Medusa.DrisslyAdapter`.

        Estos son los Endpoints
        base:  "https://sandbox.drissly.com/api/v1",
        login: "/auth/login" ,
        catalogo_productos: "/get_products",
        catalogo_servicios: "/get_services",
        consulta_saldo: "/get_balance",
        recargas: "/transactions",
        pago_servicio: "/transaction_service",
        consulta_transaccion: "/consult_transaction"

        Para usar el modulo se debe hacer llamado a una funcion
        de entrada make_request/2 la cual toma dos parametros
        el primero es el tipo de operacion
        (uno por endpoint a partir de catalogo_productos)
        y el segundo parametro es una tupla de 6 valores en la que se setean los
        valores correspondientes en dependencia del tipo de operacion
        y los demas se dejan con el valor nil. los datos de autenticacion
        se ponen por defecto en el body cargados desde la configuracion.

        los valores de la tupla son {
                                     numero_telefonico,
                                     tipo_de_servicio_o_producto,
                                     cantidad_a_recargar,
                                     texto_adicional,
                                     numero_referencia,
                                     folio
                                     }

        Nota: El folio solo se necesita para la consulta de una transaccion previa.

        Ejemplo para el catalogo de productos solo necesitamos el tipo de operacion[19~], y nada mas, por lo que quedaria asi.
        Medusa.DrisslyAdapter.make_request("catalogo_servicios",{nil,nil,nil,nil,nil,nil})

        Para la recarga necesitamos el tipo de operacion, el numero



  """
  import Record
  require EEx
  use Timex
  require Logger
  import UUID
  use Tesla

  @drissly_timeout_tae 60
  @drissly_timeout_servicios 75
  @config Application.get_env(:medusa, :drissly)

  @doc """
      Esta funcion construye la solicitud que se le enviara a la API de Drissly                  recibiendo como parametros el tipo de operacion(),y una lista con parametros opc           ionales como el numero de telefono, el tipo de servicio, la cantidad de dinero             en caso de pago, y el numero de referencia en caso de pago
  """
  def make_request(ops, options) do
    operation_id = UUID.uuid4()

    url = get_url(ops)

    phone_num = options[:phone]
    tos = options[:id_product]

    spa = options[:amount]
    addition_text = options[:aditional]
    ref = options[:reference]
    folio = options[:folio]

    if phone_has_10_digits?(phone_num) or ops != "recarga" or ops != "pago_servicio" do
      send_request(
        ops,
        url,
        phone_num,
        tos,
        spa,
        addition_text,
        ref,
        folio
      )
      |> parse_response()
    else
      Logger.error("Drissly Error: Verifique el numero de telefono, debe tener 10 digitos")
    end
  end

  defp get_url(class) do
    @config[:endpoints][:base] <> @config[:endpoints][String.to_atom(class)]
  end

  def get_user_name() do
    @config[:headers][:login][:email]
  end

  def get_password() do
    @config[:headers][:login][:password]
  end

  defp send_request(action, url, phone_number, tos, spa, ad, ref, fol) do
    payment_id = UUID.uuid4()

    Logger.info("ID de Operacion #{payment_id} Drissly URL: #{url} ")

    # log =
    #   _body
    #   |> String.replace(get_user_name(), "*****")
    #   |> String.replace(get_password(), "*****")

    # log(:info, payment_id, "#{get_time()} Drissly Request: #{log}")

    body =
      get_body(
        action,
        phone_number,
        tos,
        spa,
        ad,
        ref,
        fol
      )
      |> Jason.encode()
      |> elem(1)

    {:ok, response} = Tesla.post(url, body, headers: get_headers())

    # server_response_body = response.body |> Jason.encode
    # Logger.info("Drissly Response: #{server_response_body}")

    #    parse_response(payment_id, response)
  end

  # top = Type of service, calling_station = phone_number
  defp get_body(
         ops,
         calling_station,
         type_of_service,
         service_payment_ammount,
         additional,
         reference,
         folio
       ) do
    case ops do
      "catalogo_productos" ->
        %{
          email: get_user_name(),
          password: get_password()
        }

      "catalogo_servicios" ->
        ''

      "recarga" ->
        %{
          email: get_user_name(),
          password: get_password(),
          phone: calling_station,
          id_product: type_of_service
        }

      "consulta_saldo" ->
        ''

      "pago_servicio" ->
        %{
          phone: calling_station,
          id_product: type_of_service,
          ammount: service_payment_ammount,
          additional: additional,
          reference: reference
        }

      "consulta_transaccion" ->
        %{
          email: get_user_name(),
          password: get_password(),
          folio: folio
        }
    end
  end

  def get_time() do
    # Timex.format!(Timex.now("America/Mexico_City"), "%Y-%m-%d %H:%M:%S.%L", :strftime)
    :hello
  end

  defp parse_response(raw_response) do
    response = Jaxon.decode(elem(raw_response, 1).body) |> elem(1)
    status_code = get_status_code(response) |> Integer.to_string()
    message = get_message(response)
    error_message = get_error(response)


    cond do
      status_code == "200" ->
        response
	
      status_code == "400" ->
        Logger.error("Drissly Response: Codigo de error: #{status_code} , #{message}")

      Regex.match?(~r/^(40[1|3])/, status_code) -> Logger.error("Drissly Error: Codigo de error: #{status_code}, #{response}")	
#      status_code == "401" ->
#        Logger.error("Drissly Error: Codigo de error: #{status_code}, #{response}")

#      status_code == "403" ->
#        Logger.error("Drissly Error: Codigo de error: #{status_code}, Access Forbidden")

      Regex.match?(~r/^(50)/, status_code) ->
        Logger.error(
          "Drissly Error: Codigo de error: #{status_code}, Tipo de error: #{error_message}"
        )

      true ->
        response
    end
  end

  defp get_headers() do
    [
      "User-Agent": "Miio",
      "Content-Type": @config[:headers][:auth][:content_type],
      Authorization: "Bearer " <> get_bearer_token()
    ]
  end

  defp get_login_headers() do
    [
      "User-Agent": "Miio",
      "Content-Type": @config[:headers][:auth][:content_type]
    ]
  end

  defp get_bearer_token() do
    body =
      %{
        email: get_user_name(),
        password: get_password()
      }
      |> Jason.encode()
      |> elem(1)

    url = @config[:endpoints][:base] <> @config[:endpoints][:login]
    {:ok, response} = Tesla.post(url, body, headers: get_login_headers)

    usr_token =
      (response.body
       |> Jason.decode()
       |> elem(1))["token"]
  end

  def get_attemps(class) do
    case class do
      "Servicios" ->
        @attempts_services_timeout

      "Recarga tae" ->
        @attempts_tae

      _ ->
        0
    end
  end

  defp get_status_code(res) do
    status_code = res["code"]
  end

  defp parse_status_code(scode) do
  end

  def get_message(res) do
    error_message = res["message"]
  end

  def get_error(res) do
    error_message = res["error"]
  end

  defp phone_has_10_digits?(number) do
    if number |> to_charlist |> length == 10 do
      true
    else
      false
    end
  end
end

# Catalogo de productos
# Medusa.DrisslyAdapter.make_request("catalogo_productos",[])

# Catalogo de Servicios
# Medusa.DrisslyAdapter.make_request("catalogo_servicios",[])

# Recarga de tae
# Medusa.DrisslyAdapter.make_request("recarga",[phone: "5512345678", id_product: 78,amount: 100])

# Pago de servicio
# Medusa.DrisslyAdapter.make_request("pago_servicio",[phone: "5512345678",id_product: 98,amount: 100,aditional: "TEST",reference: 010101010101])

# Consulta transaccion
# Medusa.DrisslyAdapter.make_request("consulta_transaccion",[folio: 9064])
