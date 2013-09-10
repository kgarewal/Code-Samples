class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :edit, :update, :destroy]

  # GET /appointments
  # GET /appointments.json
  def index
    @appointments = Appointment.all
  end

  # GET /appointments/1
  # GET /appointments/1.json
  def show
  end

  # GET /appointments/new
  def new
    @appointment = Appointment.new
  end

  # GET /appointments/1/edit
  def edit
  end

  # POST /appointments
  # POST /appointments.json
  def create
    @appointment = Appointment.new(appointment_params)
    @doctor = Doctor.where(id: params[:doctor]).first
    
    respond_to do |format|
      if !@doctor.nil? && !@appointment.nil? && @doctor.appointments << @appointment
        format.html { redirect_to action: :index, notice: 'Appointment was successfully created.' }
        format.json { render action: 'show', status: :created, location: @appointment }
      else
        flash[:error] = 'No doctors available' if @doctor.nil?
        flash[:error] = 'Appointment error' if @appointment.nil?
        format.html { render action: 'new' }
        format.json { render json: @appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /appointments/1
  # PATCH/PUT /appointments/1.json
  def update
    @doctor = Doctor.where(id: params[:doctor]).first
    @appointment.doctor_id = @doctor.id if !@doctor.nil?

    respond_to do |format|
      if !@doctor.nil? &&  @appointment.update(appointment_params)
        format.html { redirect_to @appointment, notice: 'Appointment was successfully updated.' }
        format.json { head :no_content }
      else
        flash[:error] = 'Doctor assignment error' if @doctor.nil?
        format.html { render action: 'edit' }
        format.json { render json: @appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /appointments/1
  # DELETE /appointments/1.json
  def destroy
    @appointment.destroy
    respond_to do |format|
      format.html { redirect_to appointments_url }
      format.json { head :no_content }
    end
  end
  
  # GET /search
  
  def search
    @appointment = Appointment.new
  end
  
  #GET : search_result/:customer
  def search_result
    @appointment = Appointment.where( "customer = ? AND date_of_visit >= ?", params[:customer], Time.now).
      order("date_of_visit ASC").first

    respond_to do |format|
      if !@appointment.nil?
        format.html
      else
        flash[:notice] = 'No appointments found' 
        format.html { redirect_to action: 'search'}
      end
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_appointment
      @appointment = Appointment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def appointment_params
      params.require(:appointment).permit(:date_of_visit, :pet, :customer, :requires_reminder, :reason_for_visit)
    end
end
