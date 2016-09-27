# Adapted from:
#
# Title: Simple Code Blocks for Jekyll
# Author: Brandon Mathis http://brandonmathis.com
# Description: Write codeblocks with semantic HTML5 <figure> and <figcaption> elements and optional syntax highlighting — all with a simple, intuitive interface.
#
# Syntax:
# {% codeblock [title] [url] [link text] %}
# code snippet
# {% endcodeblock %}
#
# For syntax highlighting, put a file extension somewhere in the title. examples:
# {% codeblock file.sh %}
# code snippet
# {% endcodeblock %}
#
# {% codeblock Time to be Awesome! (awesome.rb) %}
# code snippet
# {% endcodeblock %}
#
# Example:
#
# {% codeblock Got pain? painreleif.sh http://site.com/painreleief.sh Download it! %}
# $ rm -rf ~/PAIN
# {% endcodeblock %}
#
# Output:
#
# <figure class='code'>
# <figcaption><span>Got pain? painrelief.sh</span> <a href="http://site.com/painrelief.sh">Download it!</a>
# <div class="highlight"><pre><code class="sh">
# -- nicely escaped highlighted code --
# </code></pre></div>
# </figure>
#
# Example 2 (no syntax highlighting):
#
# {% codeblock %}
# <sarcasm>Ooooh, sarcasm... How original!</sarcasm>
# {% endcodeblock %}
#
# <figure class='code'>
# <pre><code>&lt;sarcasm> Ooooh, sarcasm... How original!&lt;/sarcasm></code></pre>
# </figure>
#

module Jekyll

  class CodeBlock < Liquid::Block
    CaptionUrlTitle = /(\S[\S\s]*)\s+(https?:\/\/\S+|\/\S+)\s*(.+)?/i
    Caption = /(\S[\S\s]*)/
    def initialize(tag_name, markup, tokens)
      @title = nil
      @caption = nil
      @lang = nil
      @starting_line = 1
      @highlight = true

      if markup =~ /\s*lang:(\S+)/i
        @lang = $1
        markup = markup.sub(/\s*lang:(\S+)/i,'')
      end
      if markup =~ CaptionUrlTitle
        @file = $1
        code_url = $2
        @caption = "<figcaption><span>#{$1.gsub('%20', ' ')}</span><a href='#{code_url}'> #{$3 || 'link'}</a></figcaption>"
        if code_url =~ /\S+#L(\d+)/
          @starting_line = $1.to_i
        end
      elsif markup =~ Caption
        @file = $1
        @caption = "<figcaption><span>#{$1}</span></figcaption>\n"
      end
      if @file =~ /\S[\S\s]*\w+\.(\w+)/ && @lang.nil?
        @lang = $1
      end
      super
    end

    def render_rouge(code)
      Jekyll::External.require_with_graceful_fail("rouge")
      formatter = Rouge::Formatters::HTML.new(
        :line_numbers => true,
        :wrap         => false,
        :start_line   => @starting_line
      )
      lexer = Rouge::Lexer.find_fancy(@lang, code) || Rouge::Lexers::PlainText
      formatter.format(lexer.lex(code))
    end

    def add_code_tag(code, caption)
      code_attributes = [
        "class=\"language-#{@lang.to_s.tr("+", "-")}\"",
        "data-lang=\"#{@lang}\""
      ].join(" ")
      "<figure class=\"highlight\">#{caption}<pre><code #{code_attributes}>"\
      "#{code.chomp}</code></pre></figure>"
    end

    def render(context)
      prefix = context["highlighter_prefix"] || ""
      suffix = context["highlighter_suffix"] || ""
      code = super.to_s.gsub(%r!\A(\n|\r)+|(\n|\r)+\z!, "")

      is_safe = !!context.registers[:site].safe

      output =
        case context.registers[:site].highlighter
        when "pygments"
          render_pygments(code, is_safe)
        when "rouge"
          render_rouge(code)
        else
          render_codehighlighter(code)
        end

      rendered_output = add_code_tag(output, @caption)
      prefix + rendered_output + suffix
    end
  end
end

Liquid::Template.register_tag('codeblock', Jekyll::CodeBlock)


## Jekyll hightlight.rb:

# module Jekyll
#   module Tags
#     class HighlightBlock < Liquid::Block
#       include Liquid::StandardFilters

#       # The regular expression syntax checker. Start with the language specifier.
#       # Follow that by zero or more space separated options that take one of three
#       # forms: name, name=value, or name="<quoted list>"
#       #
#       # <quoted list> is a space-separated list of numbers
#       SYNTAX = %r!^([a-zA-Z0-9.+#-]+)((\s+\w+(=(\w+|"([0-9]+\s)*[0-9]+"))?)*)$!

#       def initialize(tag_name, markup, tokens)
#         super
#         if markup.strip =~ SYNTAX
#           @lang = Regexp.last_match(1).downcase
#           @highlight_options = parse_options(Regexp.last_match(2))
#         else
#           raise SyntaxError, <<-eos
# Syntax Error in tag 'highlight' while parsing the following markup:

#   #{markup}

# Valid syntax: highlight <lang> [linenos]
# eos
#         end
#       end

#       def render(context)
#         prefix = context["highlighter_prefix"] || ""
#         suffix = context["highlighter_suffix"] || ""
#         code = super.to_s.gsub(%r!\A(\n|\r)+|(\n|\r)+\z!, "")

#         is_safe = !!context.registers[:site].safe

#         output =
#           case context.registers[:site].highlighter
#           when "pygments"
#             render_pygments(code, is_safe)
#           when "rouge"
#             render_rouge(code)
#           else
#             render_codehighlighter(code)
#           end

#         rendered_output = add_code_tag(output)
#         prefix + rendered_output + suffix
#       end

#       def sanitized_opts(opts, is_safe)
#         if is_safe
#           Hash[[
#             [:startinline, opts.fetch(:startinline, nil)],
#             [:hl_lines,    opts.fetch(:hl_lines, nil)],
#             [:linenos,     opts.fetch(:linenos, nil)],
#             [:encoding,    opts.fetch(:encoding, "utf-8")],
#             [:cssclass,    opts.fetch(:cssclass, nil)]
#           ].reject { |f| f.last.nil? }]
#         else
#           opts
#         end
#       end

#       private

#       def parse_options(input)
#         options = {}
#         unless input.empty?
#           # Split along 3 possible forms -- key="<quoted list>", key=value, or key
#           input.scan(%r!(?:\w="[^"]*"|\w=\w|\w)+!) do |opt|
#             key, value = opt.split("=")
#             # If a quoted list, convert to array
#             if value && value.include?("\"")
#               value.delete!('"')
#               value = value.split
#             end
#             options[key.to_sym] = value || true
#           end
#         end
#         if options.key?(:linenos) && options[:linenos] == true
#           options[:linenos] = "inline"
#         end
#         options
#       end

#       def render_pygments(code, is_safe)
#         Jekyll::External.require_with_graceful_fail("pygments")

#         highlighted_code = Pygments.highlight(
#           code,
#           :lexer   => @lang,
#           :options => sanitized_opts(@highlight_options, is_safe)
#         )

#         if highlighted_code.nil?
#           Jekyll.logger.error <<eos
# There was an error highlighting your code:

# #{code}

# While attempting to convert the above code, Pygments.rb returned an unacceptable value.
# This is usually a timeout problem solved by running `jekyll build` again.
# eos
#           raise ArgumentError, "Pygments.rb returned an unacceptable value "\
#           "when attempting to highlight some code."
#         end

#         highlighted_code.sub('<div class="highlight"><pre>', "").sub("</pre></div>", "")
#       end

#       def render_rouge(code)
#         Jekyll::External.require_with_graceful_fail("rouge")
#         formatter = Rouge::Formatters::HTML.new(
#           :line_numbers => @highlight_options[:linenos],
#           :wrap         => false
#         )
#         lexer = Rouge::Lexer.find_fancy(@lang, code) || Rouge::Lexers::PlainText
#         formatter.format(lexer.lex(code))
#       end

#       def render_codehighlighter(code)
#         h(code).strip
#       end

#       def add_code_tag(code)
#         code_attributes = [
#           "class=\"language-#{@lang.to_s.tr("+", "-")}\"",
#           "data-lang=\"#{@lang}\""
#         ].join(" ")
#         "<figure class=\"highlight\"><pre><code #{code_attributes}>"\
#         "#{code.chomp}</code></pre></figure>"
#       end
#     end
#   end
# end

# Liquid::Template.register_tag("highlight", Jekyll::Tags::HighlightBlock)
