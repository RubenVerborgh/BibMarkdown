require 'cgi'
require 'citeproc'
require 'csl/styles'

module BibMarkdown
  class Document
    def initialize(source, options)
      @source = source
      @entries = options[:entries]
      @style = options[:style]
    end

    def to_markdown
      reference_ids = {}

      # Replace all citations by links
      markdown = @source.gsub %r{\[([^\]]*)\]\(cite:(\w+)\s+([^\)]+)\)} do |match|
        html = $1; rel = $2; key = $3

        # Look up or assign reference ID
        if reference_ids.has_key? key
          reference_id = reference_ids[key]
        else
          reference_id = reference_ids[key] = reference_ids.length + 1
        end

        # Look up citation and its URL
        entry = @entries[key]
        raise "Failed to generate references: entry '#{key}' does not exist." unless entry
        url = entry[:url] || ''

        # Create the reference
        reflink = create_link "[#{reference_id}]", "#ref-#{reference_id}", class: 'reference'

        # If the text is empty, just output the reference
        if html.empty?
          reflink
        # If there is no URL, just output the text with the reference
        elsif url.empty?
          "#{html} #{reflink}"
        # Otherwise, output the link and the reference
        else
          "#{create_link html, url, rel: 'http://purl.org/spar/cito/' + rel} #{reflink}"
        end
      end

      # Append the reference list to the text
      "#{markdown}\n\n#{references_html reference_ids}".rstrip
    end

    protected
    def h text
      CGI::escapeHTML(text || '')
    end

    def create_link html, url, attrs = {}
      attrs[:href] = url
      attrs = attrs.map { |attr, value| %Q{#{attr}="#{h value}"} }
      %Q{<a #{attrs.join ' '}>#{html}</a>}
    end

    def references_html reference_ids
      if reference_ids.empty?
        ''
      else
        html =  %Q{<h2 id="references">References</h2>\n}
        html += %Q{<dl class="references">\n}
        reference_ids.each do |key, id|
          html += %Q{  <dt id="ref-#{id}">[#{id}]</dt>\n}
          html += %Q{  <dd>#{reference_html key}</dd>\n}
        end
        html += %Q{</dl>\n}
      end
    end

    def reference_html key
      # Render reference
      processor = CiteProc::Processor.new style: @style, format: 'html'
      processor << @entries[key].to_citeproc
      citations = processor.render :bibliography, id: key
      citation = citations.first

      # Replace URLs by links
      citation.gsub %r{https?://[^ ]+[^ .]} do |match|
        create_link h(match), match
      end
    end
  end
end
