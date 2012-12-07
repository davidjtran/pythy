class GlobalRole < ActiveRecord::Base
  attr_accessible :can_edit_system_configuration, 
                  :can_manage_all_courses,
                  :can_manage_own_courses,
                  :builtin,
                  :name

  # make sure to run rake db:seed after initial database creation
  # to ensure that these IDs are accurate
  ADMINISTRATOR_ID = 1
  STUDENT_ID = 2
  INSTRUCTOR_ID = 3
end