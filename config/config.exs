import Config

config :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 60_000]}

config :medusa,
  drissly: %{
    log_path: %{
      drissly_services: "/pago_servicios/",
      drissly_tae: "/recarga_tae/",
      
      
    },
    endpoints: %{
      base: "https://sandbox.drissly.com/api/v1",
      login: "/auth/login",
      catalogo_productos: "/get_products",
      recarga: "/transaction",
      consulta_saldo: "/get_balance",
      catalogo_servicios: "/get_services",
      pago_servicio: "/transaction_service",
      consulta_transaccion: "/consult_transaction"
    },
    codigos_respuesta: %{
      "200" => "Transacción exitosa",
      "400" => "Transacción no exitosa sin error",
      "500" => "Transacción no exitosa con error"
    },
    headers: %{
      login: %{email: "manuel@miio.mx", password: "aK2cahFpVB2WP6r5"},
      auth: %{
        content_type: "application/json",
        authorization: "Bearer",

      }
    }
  }

