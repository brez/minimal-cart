# See LICENSE file in the root for details
class Customer < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :email, :street_address, :city, :state, :zip_code, :country, :phone
  validates_length_of :first_name, :in => 2..255
  validates_length_of :last_name, :in => 2..255
  #validates_length_of :email, :in => 7..255
  validates_length_of :street_address, :in => 2..255
  validates_length_of :city, :in => 2..255 
  validates_length_of :phone, :in => 7..20
  validates_length_of :state, :in => 2..255
  validates_length_of :country, :in => 2..255
  
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create
end
