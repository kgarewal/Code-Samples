class CreatePets < ActiveRecord::Migration
  def change
    create_table :pets do |t|
      t.string :name
      t.string :type_of_pet
      t.string :breed
      t.integer :age
      t.integer :weight
      t.datetime :date_of_last_visit

      t.timestamps
    end
  end
end
