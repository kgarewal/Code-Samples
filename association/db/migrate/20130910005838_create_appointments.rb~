class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.datetime :date_of_visit
      t.string :pet
      t.string  :customer
      t.boolean :requires_reminder
      t.string :reason_for_visit

      t.timestamps
    end
  end
end
