class Doctor < ActiveRecord::Base
  
  has_many :appointments, dependent: :nullify 
  has_many :pets, through: :appointments, dependent: :nullify
  
  validates_length_of :name, within: 1..35
  validates_length_of :zip, within: 1..5
  validates :zip, :numericality => {:only_integer => true}
  validates_inclusion_of :years_in_practise, :in => 1..100, message: 'invalid'  
end
