module PageEntriesHelper
    
    # <%= page_entries @posts, :entry_name => 'item' %>
    #  items 6 - 10 of 26
    def page_entries(collection, options = {})
      entry_name = options[:entry_name] ||
        (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
      message = options[:message]  
      
      if collection.total_pages < 2
        case collection.size
        when 0; "<h3>#{entry_name.pluralize.capitalize} (0 total) #{message}</h3>"
        when 1; "<h3>#{entry_name.pluralize.capitalize} (1 total) #{message}</h3>"
        else; %{<h3>#{entry_name.pluralize.capitalize} (%d&nbsp;-&nbsp;%d of %d) #{message}</h3>} % [ 
          collection.offset + 1, 
          collection.offset + collection.length,  
          collection.total_entries ]
        end
      else
        %{<h3> #{entry_name.pluralize.capitalize} (%d&nbsp;-&nbsp;%d of %d) #{message}</h3>} % [
          collection.offset + 1,
          collection.offset + collection.length,
          collection.total_entries
        ]
      end
    end
end    
