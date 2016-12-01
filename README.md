# Män möter mödravård: besöket på barnmorskemottagningen och betydelsen av "vi"

This is an article for the Swedish Association of Midwifes' publication *Jordemodern*, based on a [blog text](https://fenomenologen.se/2016/10/11/om-mellanmanskliga-moten-pappor-och-modrahalsovard/). It is hosted online on [Authorea](https://www.authorea.com/users/106373/articles/132426). The article as well as the blog text is written in Swedish. However, I have done some Authorea hacks that might be of interest.

## Using Pandoc to compile the document offline

Authorea has its own rendering engine online. When working offline and [syncing with a Github repository](https://help.authorea.com/hc/en-us/articles/230482448-Syncing-articles-to-GitHub) I would like to use [Pandoc](https://pandoc.org) to compile the document to PDF or Word or whatever. Since you can write plain [Markdown](https://daringfireball.net/projects/markdown/) in Authorea, this works just fine, except for citations that is written as inline LaTeX codes in Authorea markdown.

### Converting inline LaTeX citations to Pandoc citations

I created a simple Pandoc filter that converts inline LaTeX citations to Pandoc citations using [Panflute](http://scorreia.com/software/panflute/):

```python
#!/usr/bin/env python3

"""
Convert LaTeX inline \cite commands to pandoc citations.
"""

import sys
import re
from panflute import *

def action(elem, doc):
    if isinstance(elem, RawInline) and elem.format == 'tex':
        m = re.match( r'\\cite([tp]?)(?:\[(.*?)\](?:\[(.*?)\])?)?\{(.*?)\}', elem.text )
        if m:
            keys = re.split( r'[, ]+', m.group(4))
            citationtype = m.group(1)
            prefix = m.group(2)
            suffix = m.group(3)
            citations = list()
            for key in keys:
                citation = Citation( key )
                if citationtype == 't':
                    citation.mode = 'AuthorInText'
                if prefix:
                    citation.prefix = [ Str( prefix ) ]
                if suffix:
                    citation.suffix = [ Str( suffix ) ]
                citations.append( citation )
            return Cite( Str('bogus'), citations=citations )


if __name__ == '__main__':
    run_filter(action)
```

The script above if very simple and it can't handle all cases, but it serves as a starting point how to convert LaTeX inline citations to pandoc citations.

### Using BibLaTeX instead of BibTeX

Authorea uses plain BibTeX for references online, but [pandoc-citeproc](https://github.com/jgm/pandoc-citeproc) can use the newer [BibLaTeX](https://www.ctan.org/pkg/biblatex) database format. BibLaTeX is superior to BibTeX, so I prefer having all references in BibLaTeX. In the `bibliography` subdirectory, the `biblio-biblatex.bib` file is the master BibLaTeX bibliography that is converted to BibTeX using `biber` (part of the BibLaTeX package) with the `biblatex-to-bibtex.conf` that I got from [Mikko Kouhia](https://users.aalto.fi/~mkouhia/2016/biblatex-to-bibtex-conversion/):

```bash
biber --tool --configfile=biblatex-to-bibtex.conf --output-resolve \
      --output-file=biblio.bib biblio-biblatex.bib
```

## Building with `make`

Authorea stores the document layout in `layout.md`. Adding some metadata in `meta.yaml`, this can be used to run Pandoc from an GNU make pattern rule:

```make
fulltext.%: meta.yaml $(shell cat layout.md) refs.md
    pandoc -f markdown -o $@ -F ./authorea-citations-filter --bibliography \
    bibliography/biblio-biblatex.bib --smart --self-contained \
    --latex-engine=xelatex $+
```

(The file `refs.md` contains only the section title `## References`; Authorea adds this automatically, whereas `pandoc-citeproc` does not.)