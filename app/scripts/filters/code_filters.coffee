'use strict'

angular.module('cortadoApp')

.filter 'md2html', ($interpolate, $rootScope) ->
  # Turns markdown into html courtesy of markdown.js
  (md) -> if md and md.replace(/\s*/,'') then markdown.toHTML(md) else ''


.filter 'escapeHTML', ($interpolate, $rootScope) ->
  (html) ->
    if html and html.replace(/\s*/,'')
      html.replace( /&/g, "&amp;" )
          .replace( /</g, "&lt;" )
          .replace( />/g, "&gt;" )
          .replace( /"/g, "&quot;" )
          .replace( /'/g, "&#39;" )
    else ''


.filter 'scopeCSS', ($filter) ->
  # Parses the supplied CSS and restricts it to the scope of the supplied prefix
  # - selectors referencing blacklisted tags are removed
  # - references to body are replaced with the prefix
  # - all other selectors are prefixed so as to limit their scope appropriately
  (css, prefix, prettify) ->
    doc = document.implementation.createHTMLDocument("")
    styles = document.createElement("style")
    styles.innerText = css
    doc.body.appendChild(styles)
    blacklist = /(^| )(head|title|link|style|script)($| )/
    response = ''
    scope_selectors = (rules) ->

      return unless rules.length
      for i in [0...rules.length]
        if rules[i].selectorText
          selectors = rules[i].selectorText.split(', ')
          selector = ((if /(^| )(body|html)($| )/.test(s) then s.replace(/(body|html)/, prefix) else "#{prefix} #{s}") for s in selectors when not blacklist.test(s)).join(', ')
          if selector
            # some hackery is required to get deal with urls which the document object excludes from css injected in this way
            cssText = ""
            if /url\(\)/.test(rules[i].cssText)
              # find the number of previous occrences of this selector
              n = 0
              n += 1 for r of rules when rules[r].selectorText is rules[i].selectorText and parseInt(r) < i
              # grab the raw text of the styles of this selector
              splitter = RegExp(rules[i].selectorText+"\\s*\{")
              contained_styles = css.split(splitter)[n+1].split('}')[0]
              # find porperty url pairs within the contained styles
              prop_url_pairs = {}
              for line in contained_styles.match(/\s*(.+?)\s*:.+?url\((.+?)\).*?;/g)
                mtch = line.match(/\s*([\-\w]+)\s*:.+?url\((.+?)\).*?;/)
                url_selector = mtch[1].replace(/\s+/g, '')
                url_content = mtch[2].replace(/\s+/g, '')
                prop_url_pairs[url_selector] = url_content

              # reconstruct css one line at a time in order to add the url from the original css text without going through the parser
              cssText += selector + ' { '
              # for each css property declaration
              for prop_decl in rules[i].cssText.match(/\{(.+)\}/)[1].split(';')
                if !!~ prop_decl.indexOf 'url()'
                  url_selector = prop_decl.match(/\s*(.+?)\s*:.+/)[1].replace(/\s+/g, '')
                  url_content = prop_url_pairs[url_selector]
                  if not url_content # account for reformatting by css parser
                    if url_selector is 'background-image'
                      url_content = prop_url_pairs['background']
                  prop_decl = prop_decl.replace('url()', 'url('+url_content+')')
                  cssText += prop_decl + '; '
                else
                  cssText += prop_decl + '; '
              cssText += ' } '
            else
              rules[i].selectorText = selector
              cssText = rules[i].cssText

            response += cssText + '   '
        else if rules[i].media[0] is 'screen'
          scope_selectors(rules[i].cssRules)
    scope_selectors(styles.sheet.cssRules)
    response


.filter 'deSassify', () ->
  # removes debug spam sometimes added to css by sass
  (css) -> `css.replace( /@media -sass-debug-info.*?\{(?:.*?\{.*?\})+.*?\}/g, '')`


.filter 'prettifyCSS', () ->
  # prettify and standardize the distrobution of whitespace in the a string of css
  (css) ->
    `css
    .replace( /^\s+/g,    ''         )
    .replace( /\s*,\s*/g, ', '       )
    .replace( /\s*{\s*/g, ' {\n    ' )
    .replace( /\s*;\s*/g, ';\n    '  )
    .replace( /\*\//g,    '*/\n'     )
    .replace( /\n\n+/g,   '\n'       )
    .replace( /\s*}\s*/g, '\n}\n\n'  )`


.filter 'prettifyHTML', () ->
  # an almost simple as possible method for adding sensible whitespace to blocky html
  # doesn't try very hard to fail gracefully given malformed html (e.g. unclosed tags without excuse)
  indent = (n,inline_count)  -> if n <= 0 then "" else Array(n-inline_count+1).join('  ')
  inline = (tag) -> tag in ['span', 'a', 'code', 'i', 'b', 'em', 'strong', 'abbr', 'img', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'bdi', 'bdo', 'wbr', 'kbd', 'del', 'ins', 's', 'rt', 'rp', 'var', 'time', 'sub', 'sup', 'link', 'title', 'label', 'input']
  closing = (tag) -> tag in ['area', 'br', 'col', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'meta', 'base', 'param', 'source', 'track', 'wbr'] # option can be self closing but usually isn't!
  count_inline = (stack) -> (t for t in stack when inline(t)).length
  tag_re = '<(?:(?:(\\w+)[^><]*?)|(?:\\/(\\w+)))>'
  tag_re = new RegExp(tag_re)
  tag_re.compile(tag_re)

  (html) ->
    saved = html
    inline_count = 0
    stack = []
    pretty_html = ""

    while html
      i = html.search(tag_re)
      unless i+1 # no tags left
        pretty_html += html
        html = ""
      m = html.match(tag_re)
      if tag_name = m[1] # found opening tag
        if inline tag_name # open inline tag
          pretty_html += indent(stack.length, inline_count) if pretty_html.charAt(pretty_html.length-1) is '\n'
          pretty_html += html.substr(0,i+m[0].length)
          stack.push tag_name
          inline_count += 1
          html = html.substr(i+m[0].length)
        else if closing tag_name
          pretty_html += indent(stack.length, inline_count) if pretty_html.charAt(pretty_html.length-1) is '\n'
          pretty_html += html.substr(0,i+m[0].length)
          html = html.substr(i+m[0].length)
        else # open block tag
          pretty_html += indent(stack.length, inline_count) if i and pretty_html.charAt(pretty_html.length-1) is '\n'
          pretty_html += "#{html.substr(0,i)}"
          pretty_html += '\n' unless pretty_html.charAt(pretty_html.length-1) is '\n'
          pretty_html += indent(stack.length, inline_count) + m[0]
          stack.push tag_name
          pretty_html += '\n'
          html = html.substr(i+m[0].length)
      else if tag_name = m[2] # found closing tag
        last_t = stack.lastIndexOf(tag_name)
        if last_t+1
          if inline tag_name # close inline tag
            inline_count -= 1
            stack.splice(last_t)
            pretty_html += "#{html.substr(0,i)}#{m[0]}"
            html = html.substr(i+m[0].length)
          else # close block tag
            pretty_html += indent(stack.length, inline_count) if i and pretty_html.charAt(pretty_html.length-1) is '\n'
            stack.splice(last_t)
            inline_count = count_inline(stack)
            pretty_html += "#{html.substr(0,i)}#{ if pretty_html.charAt(pretty_html.length-1) is '\n' then '' else '\n'}#{indent(stack.length, inline_count)}#{m[0]}"
            html = html.substr(i+m[0].length)
            pretty_html += '\n' unless html[0] is '\n'
        else
          pretty_html += "#{html.substr(0,i+m[0].length)}"
          html = html.substr(i+m[0].length)

      else # um wut?
        console.warn "UH OH: found a tag that's not an opening tag or a closing tag!?!?"
    pretty_html


