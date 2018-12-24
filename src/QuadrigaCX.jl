__precompile__()

module QuadrigaCX
  export  QuadrigaCXRestClient,
          get_balances,
          add_buy_order,
          add_sell_order,
          get_order

  include("client.jl")

end
