require 'cgi'

module BibMarkdown
  class Document
    def initialize(source, options)
      @source = source
      @entries = options[:entries]
    end

    def to_markdown
      # Replace all citations by links
      markdown = @source.gsub %r{\[([^\]]+)\]\(cite:(\w+)\s+([^\)]+)\)} do |match|
        html = $1; rel = $2; key = $3

        # Look up citation and its URL
        entry = @entries[key]
        url = entry[:url]

        # Create the citation link
        create_link html, url, 'http://purl.org/spar/cito/' + rel
      end
    end

    protected
    def h text
      CGI::escapeHTML(text)
    end

    def create_link html, url, rel
      %Q{<a href="#{h url}" rel="#{h rel}">#{html}</a>}
    end
  end
end
