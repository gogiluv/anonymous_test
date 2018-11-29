require 'sanitize'

class Search

  class GroupedSearchResults
    include ActiveModel::Serialization

    class TextHelper
      extend ActionView::Helpers::TextHelper
    end

    attr_reader(
      :type_filter,
      :posts,
      :categories,
      :users,
      :tags,
      :more_posts,
      :more_categories,
      :more_users,
      :term,
      :search_context,
      :include_blurbs,
      :more_full_page_results      
    )

    attr_accessor :search_log_id, :total_count

    def initialize(type_filter, term, search_context, include_blurbs, blurb_length)
      @type_filter = type_filter
      @term = term
      @search_context = search_context
      @include_blurbs = include_blurbs
      @blurb_length = blurb_length || 200
      @posts = []
      @categories = []
      @users = []
      @tags = []
      @total_count = 0
    end

    def find_user_data(guardian)
      if user = guardian.user
        topics = @posts.map(&:topic)
        topic_lookup = TopicUser.lookup_for(user, topics)
        topics.each { |ft| ft.user_data = topic_lookup[ft.id] }
      end
    end

    def blurb(post)
      GroupedSearchResults.blurb_for(post.cooked, @term, @blurb_length)
    end

    def add(object)
      type = object.class.to_s.downcase.pluralize

      if @type_filter.present? && send(type).length == Search.per_filter
        @more_full_page_results = true
      elsif !@type_filter.present? && send(type).length == Search.per_facet
        instance_variable_set("@more_#{type}".to_sym, true)
      else
        (send type) << object
      end
    end

    def self.blurb_for(cooked, term = nil, blurb_length = 200)
      blurb = nil
      cooked = SearchIndexer.scrub_html_for_search(cooked)

      if term
        terms = term.split(/\s+/)
        blurb = TextHelper.excerpt(cooked, terms.first, radius: blurb_length / 2, seperator: " ")
      end

      blurb = TextHelper.truncate(cooked, length: blurb_length, seperator: " ") if blurb.blank?
      Sanitize.clean(blurb)
    end

    def set_total_count(count)
      @total_count = count
    end
  end

end
