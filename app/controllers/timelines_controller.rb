class TimelinesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_timeline, only: [:show, :edit, :update, :destroy]

  before_action :set_navbar_color
  before_action :set_sidenav_expansion

  before_action :require_premium_plan, only: [:new, :create]
  before_action :require_timeline_read_permission, only: [:show]
  before_action :require_timeline_edit_permission, only: [:edit, :update]

  # GET /timelines
  def index
    cache_linkable_content_for_each_content_type

    # TODO: We SHOULD be just doing the below, but since it returns ContentPage stand-ins instead
    # of actual Timeline models, it's a bit wonky to get all the Timeline-specific logic in place
    # without reworking most of the views. For now, we're just grabbing timelines and contributable
    # timelines manually.
    # @timelines = @linkables_raw.fetch('Timeline', [])
    @timelines = current_user.timelines

    @page_title = "My timelines"

    if @universe_scope
      @timelines = Timeline.where(universe: @universe_scope)
    else
      # Add in all timelines from shared universes also
      @timelines += Timeline.where(universe_id: current_user.contributable_universe_ids)
    end

    @page_tags = PageTag.where(
      page_type: Timeline.name,
      page_id:   @timelines.pluck(:id)
    ).order(:tag)
    if params.key?(:tag)
      @filtered_page_tags = @page_tags.where(slug: params[:tag])
      @timelines = @timelines.select { |timeline| @filtered_page_tags.pluck(:page_id).include?(timeline.id) }
    end

    # if params.key?(:favorite_only)
    #   @timelines.select!(&:favorite?)
    # end
  end

  def show
    @page_title = @timeline.name
  end

  # GET /timelines/new
  def new
    timeline = current_user.timelines.create(name: 'Untitled Timeline', universe: @universe_scope).reload
    redirect_to edit_timeline_path(timeline)
  end

  # GET /timelines/1/edit
  def edit
    @page_title = "Editing #{@timeline.name}"
    @suggested_page_tags = []
  end

  # POST /timelines
  def create
    @page_title = "Create a timeline"

    # TODO this endpoint is probably just API-only, right?
    @timeline = Timeline.new(timeline_params)

    if current_user.on_premium_plan? && @timeline.save
      redirect_to @timeline, notice: 'Timeline was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /timelines/1
  def update
    if @timeline.update(timeline_params)
      update_page_tags

      render status: 200, json: @timeline.reload
    else
      render status: 501, json: @timeline.errors
    end
  end

  # DELETE /timelines/1
  def destroy
    @timeline.destroy
    redirect_to timelines_url, notice: 'Timeline was successfully destroyed.'
  end

  private

  def require_timeline_read_permission
    return user_signed_in? && @timeline.readable_by?(current_user)
  end

  def require_timeline_edit_permission
    return user_signed_in? && @timeline.updatable_by?(current_user)
  end

  # TODO: move this (and the copy in ContentController) into the has_page_tags concern?
  def update_page_tags
    tag_list = page_tag_params.split(PageTag::SUBMISSION_DELIMITER)
    current_tags = @timeline.page_tags.pluck(:tag)

    tags_to_add    = tag_list - current_tags
    tags_to_remove = current_tags - tag_list

    tags_to_add.each do |tag|
      @timeline.page_tags.find_or_create_by(
        tag:  tag,
        slug: PageTagService.slug_for(tag),
        user: @timeline.user
      )
    end

    tags_to_remove.each do |tag|
      @timeline.page_tags.find_by(tag: tag).destroy
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_timeline
    @timeline = Timeline.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def timeline_params
    params.require(:timeline).except(:page_tags).permit(:name, :subtitle, :description, :notes, :private_notes, :universe_id, :deleted_at, :archived_at, :privacy)
  end

  def page_tag_params
    params.require(:timeline).fetch(:page_tags, "")
  end

  def set_navbar_color
    @navbar_color = Timeline.hex_color.presence || '#2196F3'
  end

  def set_sidenav_expansion
    @sidenav_expansion = 'writing'
  end
end
