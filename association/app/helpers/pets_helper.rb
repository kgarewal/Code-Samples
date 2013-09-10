module PetsHelper
  def appointments_list
    appointments = Appointment.where( "date_of_visit >= ?", Time.now - 1.days).order("date_of_visit ASC")
    appointments.map{ |appointment| [" #{appointment.pet} :
      #{appointment.customer}  :  #{appointment.date_of_visit.to_s}", appointment.id] }
  end
end
