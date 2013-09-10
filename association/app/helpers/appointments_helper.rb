module AppointmentsHelper

  def doctors_list
    Doctor.all.order('name ASC').map{ |doctor| [doctor.name, doctor.id] }
  end

end
