## BibMarkown
BibMarkdown is a Ruby pre-processor for Markdown,
adding support for citations
realized by a BibTex back-end.

## Syntax and result
This Markdown snippet
```markdown
The way _clients_ and _servers_ exchange information on the Web
is modeled by the [REST architectural style](cite:citesAsAuthority REST).
```
will be processed into the following Markdown snippet:
```markdown
The way _clients_ and _servers_ exchange information on the Web
is modeled by the <a rel="http://purl.org/spar/cito/citesAsAuthority" href="http://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm">REST architectural style</a> <a class="reference" href="#ref-1">[1]</a>.
```

This Markdown snippet
```markdown
The way _clients_ and _servers_ exchange information on the Web
is modeled by the REST architectural style [](cite:citesAsAuthority REST).
```
will be processed into the following Markdown snippet:
```markdown
The way _clients_ and _servers_ exchange information on the Web
is modeled by the REST architectural style <a class="reference" href="#ref-1">[1]</a>.
```

Furthermore, at the end of the Markdown document,
a _References_ section will be added:
```html
<h2 id="references">References</h2>
<dl class="references">
  <dt id="ref-1">[1]</dt>
  <dd>Fielding, R.T., 2000. Architectural Styles and the Design of Network-based Software Architectures (PhD thesis). University of California.</dd>
</dl>
```

## Usage
```ruby
require 'bibmarkdown'
require 'bibtex'
require 'csl/styles'

content = <<-md
The way _clients_ and _servers_ exchange information on the Web
is modeled by the [REST architectural style](cite:citesAsAuthority REST).
md

bibliography = <<-bib
@phdthesis{REST,
  author = {Roy Thomas Fielding},
  title = {Architectural Styles and the Design of Network-based Software Architectures},
  school = {University of California},
  year = 2000,
  url = {http://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm},
}
bib

entries = BibTeX.parse(bibliography).entries
document = BibMarkdown::Document.new content,
             entries: entries, style: 'elsevier-harvard'
puts document.to_markdown
```

## Related work
This library was inspired by [Pieter Colpaert](http://pieter.pm/)'s
[jekyll-refs](https://github.com/pietercolpaert/jekyll-refs),
which has some nice [CSS suggestions](https://github.com/pietercolpaert/jekyll-refs#using-css-styles-to-mark-up-the-citations) as well.

## License
Copyright ©2016 Ruben Verborgh – MIT License
