json.array!(@pets) do |pet|
  json.extract! pet, :name, :type_of_pet, :breed, :age, :weight, :date_of_last_visit
  json.url pet_url(pet, format: :json)
end
