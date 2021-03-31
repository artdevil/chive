module Chive
  class Article < ApplicationRecord
    belongs_to :author, class_name: Chive.user_model, primary_key: Chive.user_pk_attr,
                        foreign_key: :author_id, required: false

    has_one_attached :image

    acts_as_taggable_on :tags

    before_validation :set_slug

    validate :valid_status

    validates :title, presence: true

    validates :slug, presence: true, uniqueness: true

    def byline
      return custom_byline if custom_byline.present?
      return real_author_name if real_author_name.present?
      Chive.anonymous_name
    end

    def real_author_name
      author.present? && author.send(Chive.user_name_attr)
    end

    def expired?
      expired_at && expired_at <= DateTime.now
    end

    def published?
      self.status == 'publish'
    end

    def draft?
      self.status == 'draft'
    end

    def public?
      self.status == 'publish' && !expired?
    end

    def to_param
      slug
    end

    def set_slug
      self.slug = Chive.slug_formatter&.call(self) || self.title.parameterize if slug.nil?
    end

    def self.latest
      self.order(published_at: :desc, created_at: :desc)
    end

    def self.latest_published
      now = DateTime.now
      latest.where('published_at <= ? AND (expired_at >= ? OR expired_at IS NULL) AND status = ?', now, now, 'publish')
    end

    private

    def valid_status
      errors.add(:status, :invalid) unless ['publish', 'draft'].include?(status)
    end
  end
end
