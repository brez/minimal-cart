# See LICENSE file in the root for details
class Product < ActiveRecord::Base
  acts_as_featurable
  acts_as_commentable
  acts_as_taggable
  
  belongs_to :user
  
  has_many :orders
  validates_presence_of :name, :byline, :description
  validates_uniqueness_of :name
  #validates_numericality_of :price, :weight, :only_integer => true
end
