class CollectionAuthorizer < ApplicationAuthorizer
  def self.creatable_by?(user)
    return false unless user.present?

    user.on_premium_plan?
  end

  def readable_by?(user)
    [
      user && resource.user_id == user.id,
      resource.privacy == 'public'
    ].any?
  end

  def updatable_by?(user)
    [
      user && resource.user_id == user.id
    ].any?
  end

  def deletable_by?(user)
    [
      user && resource.user_id == user.id
    ].any?
  end
end
