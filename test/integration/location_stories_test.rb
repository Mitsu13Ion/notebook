require 'test_helper'

# Tests scenarios related to interacting with Locations
class LocationStoriesTest < ActionDispatch::IntegrationTest
  fixtures :locations

  test 'locations button shows locations list' do
    log_in_as_user
    visit dashboard_path
    click_on 'Locations'
    assert_equal locations_path, current_path
  end

  test 'location list edit button edits location' do
    log_in_as_user
    visit locations_path
    click_on 'Edit'
    assert_equal edit_path(locations(:shire)), current_path
  end

  test 'location list view button shows location' do
    log_in_as_user
    visit locations_path
    click_on 'View'
    assert_equal location_path(locations(:shire)), current_path
  end

  test 'location view edit button edits location' do
    log_in_as_user
    visit location_path(locations(:shire))
    click_on 'Edit'
    assert_equal edit_location_path(locations(:shire)), current_path
  end

  test 'a user can create a new location' do
    log_in_as_user
    visit locations_path
    click_on 'Create another location'
    fill_in 'location_name', with: 'Mordor'
    fill_in 'location_universe', with: 'Middle-Earth'
    click_on 'Create Location'

    assert_equal location_path(Location.where(name: 'Mordor').first),
                 current_path
  end
end
