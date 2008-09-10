# See LICENSE file in the root for details
class ShippingRate < ActiveRecord::Base
  
  def self.shipping_rate_from_weight_method_group(weight, method, group)
    begin
      shipping_rate = ShippingRate.find(:first, :conditions => ["from_weight <= ? and to_weight >= ? and method = ? and country_group = ? ", weight, weight, method, group])
    rescue
      raise 'Invalid ShippingRate based on weight, method, and group combination'
    end
    return 0 unless shipping_rate
    return shipping_rate.rate
  end
  
end
