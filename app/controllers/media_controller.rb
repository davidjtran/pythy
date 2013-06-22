class MediaController < ApplicationController

  before_filter :set_upload_url


  # -------------------------------------------------------------
  def requesting_user
    params[:user] ? User.find_by_id(params[:user]) : current_user
  end


  # -------------------------------------------------------------
  def index
    @user = requesting_user
    #assignment_id = params[:assignment]
    type = type_pattern_to_query(params[:type])

    #@assignment = Assignment.find_by_id(assignment_id)

    authorize! :show, @user
    #authorize! :read, @assignment if @assignment

    if @user
      @user_media = MediaItem.where(user_id: @user.id)
    else
      @user_media = MediaItem.where('0 = 1')
    end

    #if assignment_id
    #  @assignment_media = MediaItem.where(assignment_id: assignment_id)
    #else
    #  @assignment_media = MediaItem.where('0 = 1')
    #end

    if type
      @user_media = @user_media.where('content_type like ?', type)
    #  @assignment_media = @assignment_media.where('content_type like ?', type)
    end

    @media = { user: @user_media } #, assignment: @assignment_media }

    respond_to do |format|
      format.html
      format.js
      format.json { render json: @media }
    end
  end


  # -------------------------------------------------------------
  def show
  end


  # -------------------------------------------------------------
  def create
    files = params[:files]

    @user = requesting_user
    #assignment_id = params[:assignment]

    media_items = {
      uploaded: [],
      errors: []
    }

    if @user #|| assignment_id
      files.each do |file|
        media_item = MediaItem.create(
          user_id: @user ? @user.id : nil,
          #assignment_id: assignment_id,
          file: file)
        
        if media_item.save
          media_items[:uploaded] << media_item
        else
          media_items[:errors] << media_item.errors
        end
      end

      respond_to do |format|
        format.json { render json: media_items }
      end
    else
      #format.json { render json: @upload.errors, status: :unprocessable_entity }
    end

  end


  # -------------------------------------------------------------
  def destroy
    id = params[:id]
    media_item = MediaItem.find_by_id(id)

    authorize! :destroy, media_item

    media_item.destroy

    respond_to do |format|
      format.js
      format.json { head :no_content }
    end
  end


  private 

  # -------------------------------------------------------------
  def set_upload_url
    user = requesting_user
    if user
      @upload_url = "/media/user/#{user.id}"
    #elsif params[:assignment]
    #  @upload_url = "/media/assignment/#{params[:assignment]}"
    end
  end


  # -------------------------------------------------------------
  def type_pattern_to_query(pattern)
    if pattern
      pattern.gsub(/\*/, '%')
    else
      nil
    end
  end

end
