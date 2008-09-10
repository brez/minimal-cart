# See LICENSE file in the root for details
module MinimalCart 
  require 'yaml'
  require 'active_merchant'

  # included is called from the Controller when you inject this module
  def self.included(base)
    base.extend ClassMethods
  end

  # declare the class level helper methods which will load the relevant instance methods defined below when invoked
  module ClassMethods
    def minimal_cart
      include MinimalCart::ShoppingCart
    end
  end

  module ShoppingCart
    def add_cart(id)
      begin
        item = Product.find(id)
        get_cart.add item
      rescue Exception => e
        raise 'Error adding product to cart: ' + e.message
      end
    end

    def remove_cart(id)
      begin
        get_cart.remove id.to_i
      rescue Exception => e
        raise 'Error removing product: ' + e.message
      end
    end

    def update_cart(id, quantity)
      begin
        get_cart.update id, quantity
      rescue Exception => e
        raise 'Error updating the quantity of a product: ' + e.message
      end
    end

    def clear_cart
      get_cart.clear
    end

    def subtotal_cart
      return get_cart.price
    end

    def total_cart
      tax = MinimalTax::Tax.calculate get_cart, get_ship_to
      shipping = MinimalShipping::Shipping.calculate get_cart, get_ship_to
      return subtotal_cart + tax + shipping
    end

    def ship_to(shipping)
      customer = Customer.new shipping
      #raise 'Invalid Customer data in Customer object' if !customer.valid?
      begin
        customer.save!
        session[:ship_to]  = customer
      rescue Exception => exp
        raise 'Invalid Customer data in Customer object.<br>' + exp.to_s
      end
    end
    
    def bill_to(customer, billing_info)
      begin
        billing = get_billing
        #billing.customer = Customer.new(customer)
        #billing.customer.save!
        billing.customer = session[:ship_to]
        
        billing.card_type = billing_info[:credit_card]
        billing.card_number = billing_info[:card_number]
        billing.expiration_month = billing_info[:expiration_month]
        billing.expiration_year = billing_info[:expiration_year]
        billing.cvn = billing_info[:card_verification_number]
        
        session[:bill_to] = billing
      rescue Exception => exp
        raise 'Invalid Customer data in Customer object.<br>' + exp.to_s
        return
      end
      
      process_card
    end
    
    private
    def get_cart
      return session[:shopping_cart] ||= Cart.new
    end

    private
    def get_billing
      return session[:bill_to] ||= Billing.new
    end

    private
    def get_ship_to
      return session[:ship_to] ||= Customer.new()
    end

    private
    def process_card
      billing = get_billing
      customer = billing.customer
      credit_card = ActiveMerchant::Billing::CreditCard.new(:first_name => customer.first_name, :last_name => customer.last_name, :number => billing.card_number, :month => billing.expiration_month, :year => billing.expiration_year, :type => billing.card_type)
      raise 'Credit card is invalid.' if !credit_card.valid?
      options = {
        :address => {},
        :billing_address => {:name => customer.first_name + ' ' + customer.last_name, :address1 => customer.street_address, :city => customer.city, :state => customer.state, :country => customer.country, :zip => customer.zip_code, :phone => customer.phone}
      }
      config = Config.new
      begin
        gateway = ActiveMerchant::Billing::Base.gateway(config.name.to_s).new(:login => config.user_name.to_s, :password => config.password.to_s)    
      rescue
        raise 'Invalid ActiveMerchant Gateway'
      end
      amount_to_charge = total_cart
      response = gateway.authorize(amount_to_charge, credit_card, options)  
      if response.success?
        gateway.capture(amount_to_charge, response.authorization)
      else 
        raise "ActiveMerchant failed to authorize the charge ( #{amount_to_charge}$ ): " + response.message
      end
    end 

    def check_out
      #customer
      raise 'Could not save Customer data' if !get_billing.customer.save
      #transaction
      transaction = ShoppingTransaction.new
      transaction.date = Time.now
      transaction.customer = get_billing.customer
      transaction.shopping_transaction_status = ShoppingTransactionStatus.find_by_status('NEW')
      transaction.total = total_cart
      transaction.save
      #orders
      get_cart.orders.values.each {|o| o.shopping_transaction = transaction; o.customer = transaction.customer; o.save}
    end
  end
  
  class Config
    attr_reader :name
    attr_reader :user_name
    attr_reader :password
    def initialize
      config = YAML::load(File.open("#{RAILS_ROOT}/vendor/plugins/minimalcart/config/config.yml"))
      raise "Please configure the ActiveMerchant Gateway" if config['merchant_account'] == nil
      @name = config['merchant_account']['name'].to_s
      @user_name = config['merchant_account']['user_name'].to_s
      @password  = config['merchant_account']['password'].to_s
    end
  end 
end 


module MinimalTax
  class Tax
    class << self
      def calculate(cart,shipping)
        raise 'Cannot calculate tax on an empty Cart' if cart == nil
        raise 'Cannot calculate tax without valid shipping values' if shipping == nil
        tax_rate = TaxRate.find_by_country(shipping.country)
        return 0 if tax_rate == nil
        return total_tax = (cart.price * tax_rate) / 100.00 unless tax_rate == -1.0
      end
    end
  end
end


module MinimalShipping
  class Shipping
    class << self 
      def calculate(cart,shipping)
        raise 'Cannot calculate shipping on an empty Cart' if cart == nil
        raise 'Cannot calculate shipping without valid shipping values' if shipping == nil
        shipping_rate = 0.0
        #total_weight = cart.weight / 16.00 # convert from ounces to lbs
        total_weight = cart.weight
        shipping_group = CountryGroup.find_by_country(shipping.country)
        shipping_rate = ShippingRate.shipping_rate_from_weight_method_group total_weight, shipping.shipping_method, shipping_group
        return shipping_rate * 100 # pennies
      end
    end
  end
end
