# See LICENSE file in the root for details
class Cart
  
  attr_reader :orders
  attr_reader :weight
  attr_reader :price 

  def initialize
    @orders = Hash.new
    @price  = 0.0
    @weight = 0.0
  end

  def clear
    initialize
  end

  def add(product)
    if @orders.key? product.id
      @orders[product.id].quantity += 1
    else 
      @orders[product.id] = Order.create_from product
    end
    @price += product.price
    @weight += product.weight
  end

  def update(id, quantity)
    if quantity.to_i == 0
      remove(id)
    else
      update_totals :subtract, id
      begin 
        @orders[id].quantity = quantity.to_i
      rescue IndexError
        raise 'No order found on Cart.update'
      end
      update_totals :add, id
    end
  end

  def remove(id)
    update_totals :subtract, id
    begin
      @orders.delete id
    rescue IndexError
      raise 'No order found on Cart.remove'
    end
  end

  private
  def update_totals(update, id)
    if update == :add
      @price += @orders[id].calc_price
      @weight += @orders[id].calc_weight
    elsif update == :subtract
      @price -= @orders[id].calc_price
      @weight -= @orders[id].calc_weight
    else
      raise 'No valid update type passed to Cart.update_totals'
    end
  end

end
