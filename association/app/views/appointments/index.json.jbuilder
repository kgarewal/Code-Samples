json.array!(@appointments) do |appointment|
  json.extract! appointment, :date_of_visit, :pet, :customer, :requires_reminder, :reason_for_visit
  json.url appointment_url(appointment, format: :json)
end
