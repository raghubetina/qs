require 'open-uri'

class LessonsController < ApplicationController
  # GET /lessons
  # GET /lessons.json
  
  def start
  end
  
  def find_name
    @lessons = Lesson.order(:name).where("name like ?", "%#{params[:term]}%")
    render json: @lessons.map(&:name)
  end
  
  def index
    @lessons = Lesson.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lessons }
    end
  end

  # GET /lessons/1
  # GET /lessons/1.json
  def show
    if params[:name]
      if l = Lesson.find_by_name(params[:name])
        @lesson = l
      else
        redirect_to root_url, notice: "There is no lesson by that name."
      end
    else
      @lesson = Lesson.find(params[:id])
      
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @lesson }
      end
    end
  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    @lesson = Lesson.new

    @results = JSON.parse(open("http://api.ustream.tv/json/user/#{params[:ustream_user_id]}/listAllChannels?key=ACC93DE5C684A1B334D50C0B082A84EA").read)["results"]
    if !@results
      redirect_to root_url, :notice => "We couldn't find any channels for that Ustream username. Please try again."
    else
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @lesson }
      end
    end
  end

  # GET /lessons/1/edit
  def edit
    @lesson = Lesson.find(params[:id])
  end

  # POST /lessons
  # POST /lessons.json
  def create
    @lesson = Lesson.new(params[:lesson])
    
    respond_to do |format|
      if @lesson.save
        format.html { redirect_to "/#{@lesson.name}" }
        format.json { render json: @lesson, status: :created, location: @lesson }
      else
        format.html { redirect_to root_url, notice: 'Something went wrong. Please try again.' }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
  def update
    @lesson = Lesson.find(params[:id])

    respond_to do |format|
      if @lesson.update_attributes(params[:lesson])
        format.html { redirect_to @lesson, notice: 'Lesson was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lessons/1
  # DELETE /lessons/1.json
  def destroy
    @lesson = Lesson.find(params[:id])
    @lesson.destroy

    respond_to do |format|
      format.html { redirect_to lessons_url }
      format.json { head :no_content }
    end
  end
end
