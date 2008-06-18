class Admin::GasSupplierController < Admin::AdminController
 
  active_scaffold :gas_suppliers do |config|
    config.columns = [:name, :country, :g_per_m3, :default]    
    config.columns[:country].ui_type = :select
  end

end
