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
      @references = {}

      # Replace all citations by links
      markdown = @source.gsub %r{\[([^\]]*)\]\(cit[eo]:(\w+)\s+([^\)]+)\)} do |match|
        text = $1; rel = $2; keys = $3

        # Create the references
        refs = keys.strip.split(/\s*,\s*/).map {|key| create_reference key }
        raise "Missing reference key in #{match}" if refs.empty?
        reflinks = refs.map{|r| r[:link]}.join ''

        # If the link text is empty, output links to the references
        if text.empty?
          reflinks
        # If there is no URL, output the text followed by links to the references
        elsif refs.first[:url].empty?
          "#{text} #{reflinks}"
        # Otherwise, output the linked text and the references
        else
          property = 'schema:citation http://purl.org/spar/cito/' + rel
          "#{create_link text, refs.first[:url], property: property} #{reflinks}"
        end
      end

      # Append the reference list to the document
      "#{markdown}\n\n#{references_html}".rstrip
    end

    protected
    def create_reference key
      return @references[key] if @references.has_key? key

      # Look up citation and its URL
      entry = @entries[key]
      raise "Failed to generate references: entry '#{key}' does not exist." unless entry
      url = entry[:url] || ''

      # Assign an ID and create a link to the reference
      id = @references.length + 1
      link = create_link "\\[#{id}\\]", "#ref-#{id}", class: 'reference'

      @references[key] = { id: id, url: url, link: link }
    end

    def h text
      CGI::escapeHTML(text || '')
    end

    def create_link html, url, attrs = {}
      attrs[:href] = url
      attrs = attrs.map { |attr, value| %Q{#{attr}="#{h value}"} }
      %Q{<a #{attrs.join ' '}>#{html}</a>}
    end

    def references_html
      if @references.empty?
        ''
      else
        html =  %Q{<h2 id="references">References</h2>\n}
        html += %Q{<dl class="references">\n}
        @references.each do |key, ref|
          html += %Q{  <dt id="ref-#{ref[:id]}">\[#{ref[:id]}\]</dt>\n}
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
