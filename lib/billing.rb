# See LICENSE file in the root for details
class Billing
  attr_accessor :comments
  attr_accessor :card_type
  attr_accessor :card_number
  attr_accessor :cvn
  attr_accessor :expiration_month
  attr_accessor :expiration_year
  attr_accessor :customer
  
  def initialize
    @customer = Customer.new
  end
end
