class AddPetIdToAppointments < ActiveRecord::Migration
  def change
    add_column :appointments, :pet_id, :integer
  end
end
