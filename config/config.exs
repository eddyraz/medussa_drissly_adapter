import Config

config :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 60_000]}

config :medusa,
  drissly: %{
    path: %{
      
      drissly_catalog_of_services: "catalogo_servicios",
      drissly_payment_of_services: "pago_servicios",
      drissly_tae: "recarga_tae",
      drissly_transaction_consult: "consulta_transaccion"
      
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
      login: %{email: "manuel@mio.mx", password: "aK2cahFpVB2WP6r5"},
      auth: %{
        content_type: "application/json",
        authorization: "Bearer",
        token:
          "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI5MzRlZjc3MS0zZmZjLTQ0ZTItOGI1NC01NWIwYmI4MTM1M2QiLCJqdGkiOiIxYTcyYmRhZjI2ODM2Y2I2YTFlOTUxNjZjZDE3YWY5YWVhN2Q2OTg4ZWRjOGM1NzBkZDYyYWI5ZWFkYmU1NjM5NWNiYTAzNmRlY2I3Y2YzYSIsImlhdCI6MTY1NDQzMTM5NSwibmJmIjoxNjU0NDMxMzk1LCJleHAiOjE2ODU5NjczOTUsInN1YiI6IjM1Iiwic2NvcGVzIjpbXX0.UA0z1td6tTNSU0NQPNEidbINX2_Ht8lcQnJCOeN-YWwj3PQIFuMbAokGQ-fdIEGP9tum2zSwIbUSkgHhXhselWB_YjhSWCbLnjz9fBIXl9eCyNZS3Ph-WDdiml2UpT9ZjMBj533An1WV8RlE7LxiahO6SHYNbotNQejIv2V3bvuBUkfEW4F_Q-IJqGniyBT37DgWyI2ZHqFfNscdRIGoQS02BMmPb-MkwCI0dZL4NxTPyGD9RN3ibf-1PQHZtJE8lJ4Owts4aZqAeiSPrvmLManb0zefliNG41TzeLfFNGbbkNyUas0IsT8tmTSt3j6yqTVbthMguq_iZ7a9suvWJUfSjYbueXqFM7LupGGhk9vvJm454OChy4QUaUfiNhoFdGrobO_UJmIy5oOl0gf2OeSibpKH8u8A8vMRMChfcSoySpLKEpYAEy9bjxxuislFluJme1prhYeAr6kw4DYNN4litSf3PiWAGYhqwpM4yWbZ8MdxvjRSESYhv3TYrqg-GPy_YU7h89Bl70BYCbGYhSLBnB43F0o_9m2qwfs2XSSIJK5c2LtkUn8rXWkwyIFoPCpaJA9hnXmNX902NhNHeE5kvtp7vhYqrGMKw9I4kpyXj8v2Z38G8Ek47luWXuWRHioe4wx65z38pKjCWnboqfr4Kl-2saX-_ibJOllLgIQ"
      }
    }
  }

