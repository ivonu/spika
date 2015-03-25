class ProgramsController < ApplicationController

  before_filter :authenticate_user!, :only => :rate
  
  def show
    if params[:id].to_i == 0

      @plan = true
      @program = Program.new
      @program.id = 0
      @program.title = "Deine Gruppenstunde"

      @plan_start = []
      @plan_main = []
      @plan_end = []

      session[:plan_start].each do |id|
        entry = Entry.find(id)
        @program.entries << entry
        @plan_start << entry
      end
      session[:plan_main].each do |id|
        entry = Entry.find(id)
        @program.entries << entry
        @plan_main << entry
      end
      session[:plan_end].each do |id|
        entry = Entry.find(id)
        @program.entries << entry
        @plan_end << entry
      end

    else
      @plan = false
      @program = Program.find(params[:id])
    end

    @combined = OpenStruct.new

    @combined.material = []
    @combined.preparation = []
    @combined.remarks = []
    @combined.group_size_min = 0
    @combined.group_size_max = 1/0.0
    @combined.age_min = 0
    @combined.age_max = 1/0.0
    @combined.time_min = 0
    @combined.time_max = 0
    @combined.indoors = false
    @combined.outdoors = false
    @combined.weather_snow = false
    @combined.weather_rain = false
    @combined.weather_sun = false
    @combined.act_active = false
    @combined.act_calm = false
    @combined.act_creative = false

    @combined.attachments = @program.entries.collect{|x| x.attachments.order(:file_content_type)}.flatten

    @program.entries.each do |entry|
      @combined.material << entry.material.split(/\r?\n/) unless entry.material.empty?
      @combined.preparation << entry.preparation unless entry.preparation.empty?
      @combined.remarks << entry.remarks unless entry.remarks.empty?
      @combined.group_size_min = [@combined.group_size_min, entry.group_size_min].max
      @combined.group_size_max = [@combined.group_size_max, entry.group_size_max].min
      @combined.age_min = [@combined.age_min, entry.age_min].max
      @combined.age_max = [@combined.age_max, entry.age_max].min
      @combined.time_min += entry.time_min
      @combined.time_max += entry.time_max
      @combined.indoors = @combined.indoors || entry.indoors
      @combined.outdoors = @combined.outdoors || entry.outdoors
      @combined.weather_snow = @combined.weather_snow || entry.weather_snow
      @combined.weather_rain = @combined.weather_rain || entry.weather_rain
      @combined.weather_sun = @combined.weather_sun || entry.weather_sun
      @combined.act_active = @combined.act_active || entry.act_active
      @combined.act_calm = @combined.act_calm || entry.act_calm
      @combined.act_creative = @combined.act_creative || entry.act_creative
    end

    respond_to do |format|
      format.html
      format.pdf do
        render  :pdf => "Spika_Program",
                :template => 'programs/show.pdf.erb',
                :page_size => 'A4',
                :footer => {:left => "spika.jubla.ch", :center => "Spielkatapult", :right => 'Seite [page] von [topage]' }
      end
    end
  end

  def new
    @program = Program.new
  end

  def new_entry
    @entry = Entry.new

    order = params[:order].to_i
    program_id = params[:program_id].to_i
    last_program_entry = ProgramEntry.where(program_id: program_id).where(order: (order..(order+99))).order(:order).last
    order = last_program_entry.order+1 if last_program_entry
    @program_entry = ProgramEntry.new(program_id: program_id.to_i, order: order)

    render 'entries/new'
  end

  def create
    @program = Program.new(program_params)

    if @program.save
      flash[:info] = "Gruppenstunde erstellt. Du kannst nun neue Spiele erfassen oder bestehende verwenden."
      redirect_to @program
    else
      render 'new'
    end
  end
  
  def edit
    @program = Program.find(params[:id])
  end

  def update
    @program = Program.find(params[:id])

    if @program.update(program_params)
      redirect_to @program
    else
      render 'edit'
    end
  end

  def destroy
    @program = Program.find(params[:id])
    @program.destroy

    redirect_to entries_path
  end

  def rate
    @program = Program.find(params[:program])

    if @program.ratings.where(user: current_user).exists?
      flash[:error] = "Du hast diesen Eintrag bereits bewertet"
    else
      value = params[:rating].to_f
      if((value >= 1) && (value <= 5))
        @program.ratings.create(:user=>current_user, :value=>value)
        tot_rate = 0
        @program.ratings.each do |rating|
          tot_rate += rating.value
        end
        @program.rating = (tot_rate.to_f / @program.ratings.count).round(2)
        @program.save
        flash[:success] = "Bewertet mit #{params[:rating]} Sternen"
      end
    end

    redirect_to Program.find(params[:program])
  end

  def program_params
    params.require(:program).permit(:title)
  end
end
