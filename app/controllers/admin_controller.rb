class AdminController < ApplicationController

  before_action :admin_validated

  def candidates
    roles = Role.where(power:0)
    @candidates = []
    roles.each do |r|
      @candidates << Teacher.find(r.teacher_id)
    end

  end

  def spams
    @spams = Teacher.where(confirmed_at:nil)
  end

  def validate
    Role.where(teacher_id:params[:id]).last.update(power:1)
    TeacherMailer.validated(Teacher.find(params[:id])).deliver
    #SMS

    @twilio_number = ENV['TWILIO_NUMBER']
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    @client = Twilio::REST::Client.new(account_sid, ENV['TWILIO_AUTH_TOKEN'])
    teacher_phone = "+33" + Teacher.find(params[:id]).infoteacher.phone
    twilio_phone_number = "TopNote"
    #time_str = ((self.time).localtime).strftime("%I:%M%p on %b. %d, %Y")
    #reminder = "Hi #{self.name}. Just a reminder that you have an appointment coming up at #{time_str}."
    reminder = "Hello, votre compte TopNote est validé. Vous pouvez désormais créer vos annonces :)
    Rendez-vous sur : 
    www.topnote.fr/cours/create

    L'équipe de TopNote"
    message = @client.api.account.messages.create(
      #:from => '+33644640536',
      :from =>twilio_phone_number,
      #:to => self.phone_number,
      :to => teacher_phone,
      :body => reminder,
    )

    redirect_to '/admin/candidates'
  end

  def validated
    roles = Role.where(power:1)
    @validated = []
    roles.each do |r|
      @validated << Teacher.find(r.teacher_id)
    end
  end

  def invalidate
    Role.where(teacher_id:params[:id]).last.update(power:0)
    redirect_to '/admin/validated'
  end

  def teacher_profile
    id = params[:id]
    @cours = Cour.where(teacher_id:id)
    @infoteacher = Infoteacher.find_by_teacher_id(id)
  end 

  def detruire_prof
    Teacher.find(params[:id]).destroy
    redirect_to '/admin/validated'
  end


  def really_detruire_prof
    Teacher.find(params[:id]).really_destroy!
    redirect_to '/admin/validated'
  end

  def eleves
    @users=User.all
  end

  def detruire_eleve
    User.find(params[:id]).destroy
    redirect_to '/admin/eleves'
  end

  def info_eleve
    @l=[]
    @user = User.find(params[:id])
    Inscription.where(user_id:params[:id]).each do |i|
      @l << Cour.find(i.cour_id)
    end
  end


  private

  def admin_validated
    unless (teacher_signed_in? and Role.where(teacher_id: current_teacher.id).last.power==2)
    #unless (teacher_signed_in? and current_teacher.id==1)
      redirect_to root_path
    end
  end
end
