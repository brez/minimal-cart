# See LICENSE file in the root for details
class ShoppingTransaction < ActiveRecord::Base
  belongs_to :customer
  belongs_to :shopping_transaction_status, :foreign_key => 'status_transaction_id'
end
