require 'cgi'

module BibMarkdown
  class Document
    def initialize(source, options)
      @source = source
      @entries = options[:entries]
    end

    def to_markdown
      reference_ids = {}

      # Replace all citations by links
      markdown = @source.gsub %r{\[([^\]]+)\]\(cite:(\w+)\s+([^\)]+)\)} do |match|
        html = $1; rel = $2; key = $3

        # Look up or assign reference ID
        if reference_ids.has_key? key
          reference_id = reference_ids[key]
        else
          reference_id = reference_ids[key] = reference_ids.length + 1
        end

        # Look up citation and its URL
        entry = @entries[key]
        url = entry[:url]

        # Create the citation link
        link = create_link html, url, rel: 'http://purl.org/spar/cito/' + rel
        reflink = create_link "[#{reference_id}]", "#ref-#{reference_id}", class: 'reference'

        "#{link} #{reflink}"
      end
    end

    protected
    def h text
      CGI::escapeHTML(text)
    end

    def create_link html, url, attrs
      attrs[:href] = url
      attrs = attrs.map { |attr, value| %Q{#{attr}="#{h value}"} }
      %Q{<a #{attrs.join ' '}>#{html}</a>}
    end
  end
end
