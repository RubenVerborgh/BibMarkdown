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

        # If the anchor text is empty, output reference links
        if text.empty?
          reflinks
        # If the reference has no URL, output the anchor text and append reference links
        elsif refs.first[:url].empty?
          "#{text} #{reflinks}"
        # Otherwise, link the anchor text to the first reference URL and append reference links
        else
          property = 'schema:citation http://purl.org/spar/cito/' + rel
          # Link to the first reference
          first = refs.first
          if first[:id] == first[:url]
            "#{create_element :a, text, property: property, href: first[:url]} #{reflinks}"
          # If the reference's ID is different from its URL, surround with an extra span
          else
            link = create_element :a, text, href: first[:url]
            "#{create_element :span, link, property: property, resource: first[:id]} #{reflinks}"
          end
        end
      end

      # Append the reference list to the document
      "#{markdown}\n\n#{references_html}".rstrip
    end

    protected
    def find_entry key
      raise "Reference '#{key}' does not exist." unless @entries.key?(key)
      @entries[key]
    end

    def create_reference key
      return @references[key] if @references.has_key? key

      # Look up citation and its URL
      entry = find_entry key
      url = entry[:url] || ''

      # Assign a reference number and create a link to the reference
      number = @references.length + 1
      link = create_element :a, "\\[#{number}\\]", href: "#ref-#{number}", class: 'reference'

      @references[key] = { id: reference_id(key), number: number, url: url, link: link }
    end

    def h text
      CGI::escapeHTML(text || '')
    end

    def create_element tag, html, attrs = {}
      attrs = attrs.map { |attr, value| %Q{#{attr}="#{h value}"} }
      %Q{<#{tag} #{attrs.join ' '}>#{html}</#{tag}>}
    end

    def references_html
      if @references.empty?
        ''
      else
        html =  %Q{<h2 id="references">References</h2>\n}
        html += %Q{<dl class="references">\n}
        @references.each do |key, ref|
          html += %Q{  <dt id="ref-#{ref[:number]}">\[#{ref[:number]}\]</dt>\n}
          html += %Q{  <dd resource="#{reference_id key}" typeof="#{reference_type key}">#{reference_html key}</dd>\n}
        end
        html += %Q{</dl>\n}
      end
    end

    def reference_id key
      entry = find_entry key
      entry[:id] ||
        entry[:doi] && "https://dx.doi.org/#{entry[:doi]}" ||
        entry[:url] ||
        "##{key}"
    end

    def reference_type key
      case find_entry(key).type
      when :article, :inproceedings
        'schema:Article'
      when :book
        'schema:Book'
      when :incollection
        'schema:Chapter'
      when :mastersthesis, :phdthesis
        'schema:Thesis'
      else
        'schema:CreativeWork'
      end
    end

    def reference_html key
      # Prepare reference HTML renderer
      processor = CiteProc::Processor.new style: @style, format: 'html'
      citeproc = @entries[key].to_citeproc

      # Ensure multi-part last names stick together
      (citeproc["author"] || citeproc["editor"] || []).each do |author|
        if author.has_key? "non-dropping-particle"
          author["family"] = "#{author["non-dropping-particle"]} #{author["family"]}"
          author.delete "non-dropping-particle"
        end
      end

      # Render reference
      processor << citeproc
      citations = processor.render :bibliography, id: key
      citation = citations.first

      # Replace URLs by links
      citation.gsub %r{https?://[^ ]+[^ .]} do |match|
        create_element :a, h(match), href: match
      end
    end
  end
end
