class Pet < ActiveRecord::Base

  has_many :doctors, through: :appointments
  has_many :appointments
  
  validates_length_of :name, minimum: 1, maximum:35
  validates :type_of_pet, :inclusion => { :in => %w(dog cat bird)  }
  validates_length_of :breed, minimum: 1, maximum:35
  validates_numericality_of  :age, greater_than: 0, less_than: 100
  validates_numericality_of  :weight, greater_than: 0, less_than: 1000
  
end
