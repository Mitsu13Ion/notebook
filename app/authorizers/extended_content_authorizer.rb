class ExtendedContentAuthorizer < ContentAuthorizer
  def self.creatable_by?(user)
    return false if ENV.key?('CONTENT_BLACKLIST') && ENV['CONTENT_BLACKLIST'].split(',').include?(user.email)

    [
      PermissionService.billing_plan_allows_extended_content?(user: user),
      PermissionService.user_can_collaborate_in_universe_that_allows_extended_content?(user: user),
      PermissionService.user_has_active_promotion_for_this_content_type(user: user, content_type: 'Location')
    ].any?
  end
end
