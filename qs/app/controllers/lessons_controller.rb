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
        redirect_to root_url, notice: "There is no session by that name."
      end
    else
      @lesson = Lesson.find(params[:id])
    end
    
    @channel_status = JSON.parse(open("http://api.ustream.tv/json/channel/#{@lesson.embed_code}/getInfo?key=ACC93DE5C684A1B334D50C0B082A84EA").read)["results"]["status"]
    
    if @channel_status == "offline"
      @channel_videos = JSON.parse(open("http://api.ustream.tv/json/channel/#{@lesson.embed_code}/listAllVideos?key=ACC93DE5C684A1B334D50C0B082A84EA").read)["results"]
      @video_times = @channel_videos.map{ |video| { id: video["id"], start: start = Time.parse(video["createdAt"]) + 7*3600, end: start + video["lengthInSecond"].to_f } }
      
      
    
      @lesson.questions.each do |question|
        @video_times.each do |video_time|
          time_range = video_time[:start]...video_time[:end]
          if time_range.cover?(question.created_at.utc)
            @video_id = video_time[:id]
          end
        end
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
    @lesson.name = CGI::escape(@lesson.name)
    
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
        format.html { redirect_to @lesson, notice: 'Session was successfully updated.' }
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
