class HomeController < FriendlyUrlController

  layout 'no_container'
  before_filter :authenticate_user!

  # -------------------------------------------------------------
  def index
    @organization_list = Organization.all.map { |o| [o.display_name, o.id] }

    offerings = current_user.course_offerings
    @courses = offerings.group_by { |co| co.course }

    respond_to do |format|
      format.html
      format.js { render command }
    end
  end


  # -------------------------------------------------------------
  def course
    @command = params[:command]

    if @offerings.length == 1 &&
      !@offerings.first.role_for_user(current_user).staff?
      course_student
    else
      course_staff
    end

  end


  private

  # -------------------------------------------------------------
  def course_staff
    # This is a staff user viewing one or more course offerings that
    # they have permission to see.

    @assignments = []
    @examples = []
    
    @all_course_offerings = {} # a hash of term to offerings.
    
    @course.course_offerings.pluck(:term_id).uniq.each do |term_id|      
      @all_course_offerings[term_id] = @course.course_offerings.where(:term_id => term_id).select { |o| can?(:show, o) }
    end

    @offerings.each do |offering|
      assignments = offering.assignment_offerings
      @assignments |= assignments.map { |ao| ao.assignment }
      @examples |= offering.example_repositories.where(source_repository_id: nil)
    end

    @assignments.sort! { |a, b| a.updated_at <=> b.updated_at }
    @examples.sort! { |a, b| b.created_at <=> a.created_at }

    if @offerings.count == 1
      @course_offering = @offerings.first
      @course_enrollments = @course_offering.course_enrollments.page(params[:page])
      @course_scores = CourseOfferingScores.new(@course_offering)
    end

    respond_to do |format|
      format.html { render 'course_staff' }
      format.js   { render @command }
    end
  end


  # -------------------------------------------------------------
  def course_student
    # This is a regular student viewing the one course offering that he or
    # she is enrolled in for this course.

    @not_started_assignments = []
    @started_assignments = []
    @examples = []

    offering = @offerings.first

    assignments = offering.assignment_offerings.visible
    assignments.each do |assignment|
      repo = AssignmentRepository.where(
        assignment_offering_id: assignment.id,
        user_id: current_user.id).first

      if repo
        @started_assignments |= [assignment]
      else
        @not_started_assignments |= [assignment]
      end
    end

    @started_assignments.sort! { |a, b| a.updated_at <=> b.updated_at }
    @not_started_assignments.sort! do |a, b|
      nil_safe_compare(a.effectively_due_at, b.effectively_due_at)
    end

    @examples = offering.example_repositories
    @examples.sort! { |a, b| b.created_at <=> a.created_at }

    respond_to do |format|
      format.html { render 'course_student' }
      format.js   { render @command }
    end
  end

end
