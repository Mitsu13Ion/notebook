class ExportService < Service
  def self.text_outline_export(universe_ids)
    page_types = Rails.application.config.content_types[:all]
    temporary_user_id_reference = Universe.find_by(id: universe_ids).user_id

    export_text = StringIO.new

    categories = fetch_categories(user_id:  temporary_user_id_reference)
    fields     = fetch_fields(category_ids: categories.map(&:id))
    values     = fetch_values(field_ids:    fields.map(&:id))

    page_types.each do |page_type|
      # Get all pages in the given universe(s)
      pages = (page_type.name == 'Universe') ? page_type.where(id: universe_ids)
                                             : page_type.where(universe_id: universe_ids)
      if pages.any?
        export_text << "# #{page_type.name.pluralize}\n"

        categories_for_this_page_type = categories.select { |c| c.entity_type == page_type.name.downcase }
        fields_for_this_page_type     = fields.select { |f| categories_for_this_page_type.map(&:id).include? f.attribute_category_id }

        pages.each do |page|
          export_text << "* Name: #{page.name}\n"
          export_text << "    ID: #{page.id}\n"

          values_for_this_page = values.select { |v| v.entity_type == page_type.name && v.entity_id == page.id }

          categories_for_this_page_type.each do |category|
            export_text << "  #{category.label}\n"

            fields_for_this_category = fields_for_this_page_type.select { |f| f.attribute_category_id == category.id }
            values_for_these_fields  = values_for_this_page.select { |v| fields_for_this_category.map(&:id).include? v.attribute_field_id }

            fields_for_this_category.each do |field|
              value_for_this_field = values_for_these_fields.detect do |value|
                value.attribute_field_id == field.id       &&
                  value.entity_type      == page_type.name &&
                  value.entity_id        == page.id
              end

              case field.field_type
              when 'text_area', 'textarea'
                # For answers to text fields, we can just output their value directly
                export_text << "    #{field.label}: #{value_for_this_field.try :value}\n"

              when 'link'
                # For link fields, we have link codes ([[Character-1]]) and need to translate
                # them into the linked page's name in order for them to actually be useful
                if value_for_this_field.present?
                  json_list = JSON.parse(value_for_this_field.value)
                  formatted_names = json_list.map do |link_code|
                    query_link_code_with_cache(*link_code.split('-')).name
                  end

                  export_text << "    #{field.label}: #{formatted_names.to_sentence}\n"
                else
                  export_text << "    #{field.label}:\n"
                end
              end

            end
          end

          export_text << "\n" # spacer between pages
        end

        export_text << "\n" # spacer between sections
      end
    end

    return export_text.string
  end

  def self.text_markdown_export(universe_ids)

  end

  def self.csv_export(universe_ids, separator=',')

  end

  def self.json_export(universe_ids)

  end

  def self.xml_export(universe_ids)

  end

  def self.yaml_export(universe_ids)

  end

  def self.html_export(universe_ids)

  end

  def self.scrivener_export(universe_ids)

  end

  private

  def self.fetch_categories(user_id:)
    AttributeCategory.where(user_id: user_id)
                     .order('position ASC')
                     .select(:id, :label, :entity_type)
  end

  def self.fetch_fields(category_ids:)
    AttributeField.where(attribute_category_id: category_ids)
                  .order('position ASC')
                  .select(:id, :label, :attribute_category_id, :field_type)
  end

  def self.fetch_values(field_ids:)
    Attribute.where(attribute_field_id: field_ids)
             .select(:attribute_field_id, :value, :entity_type, :entity_id)
  end

  def self.fetch_universes(universe_ids)

  end

  def self.query_link_code_with_cache(content_type_name, content_id)
    cache_key = "#{content_type_name}-#{content_id}"

    # Pull from the cache to avoid a query if we can
    @content_cache ||= {}
    if @content_cache.key?(cache_key)
      return @content_cache[cache_key]
    end

    # TODO: we should probably whitelist content_type from valid page types here

    # If there's no cache, we unfortunately need to do a query to resolve the link code
    content = class_from_name(content_type_name).find(content_id)
    @content_cache[cache_key] = content

    return content
  end

  def self.class_from_name(content_type_name)
    # This is ~3x faster than .constantize
    Rails.application.config.content_types_by_name[content_type_name]
  end
end